import { initializeApp, getApps, getApp, cert, type App } from 'firebase-admin/app';
import { getMessaging, type Message } from 'firebase-admin/messaging';
import { prisma } from '../index.js';
import { UserRole } from '@prisma/client';

let _app: App | null = null;

function serviceAccountFromEnv() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (raw) {
    try {
      return JSON.parse(raw.startsWith('{') ? raw : Buffer.from(raw, 'base64').toString('utf8'));
    } catch {
      return null;
    }
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  if (projectId && clientEmail && privateKey) {
    return {
      projectId,
      clientEmail,
      privateKey: privateKey.replace(/\\n/g, '\n'),
    };
  }

  return undefined;
}

function initFirebaseAdmin(): App | null {
  if (_app) return _app;
  if (getApps().length > 0) {
    _app = getApp();
    return _app;
  }

  const serviceAccount = serviceAccountFromEnv();
  if (!serviceAccount) return null;

  _app = initializeApp({
    credential: serviceAccount ? cert(serviceAccount) : undefined,
  });
  return _app;
}

export function isPushEnabled(): boolean {
  return Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || process.env.FIREBASE_PROJECT_ID);
}

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  /** Route within the flutter app (e.g. /notices/:id) */
  route?: string;
}

function buildMessage(token: string, payload: PushPayload): Message {
  return {
    token,
    notification: { title: payload.title, body: payload.body },
    data: {
      ...(payload.data || {}),
      ...(payload.route ? { route: payload.route } : {}),
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };
}

export async function sendPushToUsers(userIds: string[], payload: PushPayload): Promise<number> {
  const app = initFirebaseAdmin();
  if (!app || userIds.length === 0) return 0;

  const tokens = await prisma.pushToken.findMany({
    where: { userId: { in: userIds } },
    select: { id: true, token: true },
  });
  if (tokens.length === 0) return 0;

  const messaging = getMessaging(app);
  const messages = tokens.map((t) => buildMessage(t.token, payload));

  const batchSize = 500;
  let sent = 0;
  const invalidIds: string[] = [];

  for (let i = 0; i < messages.length; i += batchSize) {
    const chunk = messages.slice(i, i + batchSize);
    try {
      const result = await messaging.sendEach(chunk);
      result.responses.forEach((r, idx) => {
        if (r.success) {
          sent += 1;
        } else if (
          r.error?.code === 'messaging/registration-token-not-registered' ||
          r.error?.code === 'messaging/invalid-registration-token'
        ) {
          invalidIds.push(tokens[i + idx].id);
        }
      });
    } catch (e) {
      console.error('Error enviando push FCM:', e);
    }
  }

  if (invalidIds.length > 0) {
    await prisma.pushToken.deleteMany({ where: { id: { in: invalidIds } } }).catch(() => {});
  }

  return sent;
}

export interface ComplexTarget {
  roles?: UserRole[];
  /** unitIds: empty array = all units */
  unitIds?: string[];
  excludeUserIds?: string[];
}

export async function sendPushToComplex(
  complexId: string,
  target: ComplexTarget,
  payload: PushPayload
): Promise<number> {
  const app = initFirebaseAdmin();
  if (!app || !complexId) return 0;

  const { roles = [], unitIds, excludeUserIds = [] } = target;
  const exclude = excludeUserIds.length > 0 ? { NOT: { id: { in: excludeUserIds } } } : {};

  let where: any;

  if (roles.includes(UserRole.RESIDENT) && unitIds && unitIds.length > 0) {
    const residents = await prisma.resident.findMany({
      where: { complexId, unitId: { in: unitIds } },
      select: { userId: true },
    });
    const residentIds = residents.map((r) => r.userId);
    const nonResidentRoles = roles.filter((r) => r !== UserRole.RESIDENT);
    const branches: any[] = [];
    if (nonResidentRoles.length > 0) branches.push({ role: { in: nonResidentRoles } });
    if (residentIds.length > 0) branches.push({ id: { in: residentIds } });

    where = { complexId, user: { ...exclude, ...(branches.length > 0 ? { OR: branches } : {}) } };
  } else {
    where = {
      complexId,
      user: {
        AND: [
          roles.length > 0 ? { role: { in: roles } } : {},
          excludeUserIds.length > 0 ? { id: { notIn: excludeUserIds } } : {},
        ].filter((c) => Object.keys(c).length > 0),
      },
    };
  }

  const tokens = await prisma.pushToken.findMany({ where, select: { id: true, token: true } });
  if (tokens.length === 0) return 0;

  const messaging = getMessaging(app);
  const messages = tokens.map((t) => buildMessage(t.token, payload));
  const batchSize = 500;
  let sent = 0;
  const invalidIds: string[] = [];

  for (let i = 0; i < messages.length; i += batchSize) {
    const chunk = messages.slice(i, i + batchSize);
    try {
      const result = await messaging.sendEach(chunk);
      result.responses.forEach((r, idx) => {
        if (r.success) {
          sent += 1;
        } else if (
          r.error?.code === 'messaging/registration-token-not-registered' ||
          r.error?.code === 'messaging/invalid-registration-token'
        ) {
          invalidIds.push(tokens[i + idx].id);
        }
      });
    } catch (e) {
      console.error('Error enviando push FCM:', e);
    }
  }

  if (invalidIds.length > 0) {
    await prisma.pushToken.deleteMany({ where: { id: { in: invalidIds } } }).catch(() => {});
  }

  return sent;
}

export function getPublicMessagingConfig() {
  const enabled = isPushEnabled();
  return {
    enabled,
    vapidKey: process.env.FIREBASE_VAPID_KEY || '',
    firebase: {
      apiKey: process.env.FIREBASE_API_KEY || '',
      authDomain: process.env.FIREBASE_AUTH_DOMAIN || '',
      projectId: process.env.FIREBASE_PROJECT_ID || '',
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || '',
      messagingSenderId: process.env.FIREBASE_MSG_SENDER_ID || '',
      appId: process.env.FIREBASE_APP_ID || '',
    },
  };
}