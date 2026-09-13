import 'server-only';
import { cookies } from 'next/headers';
import { SessionUser } from '@/lib/types';

export const API_BASE_URL = process.env.API_BASE_URL ?? 'http://localhost:3000/api/v1';

const ACCESS_COOKIE = 'appsec_access';
const REFRESH_COOKIE = 'appsec_refresh';

const cookieOptions = {
  httpOnly: true,
  sameSite: 'lax' as const,
  secure: process.env.NODE_ENV === 'production',
  path: '/',
};

export class ApiError extends Error {
  status: number;
  details?: unknown;
  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

async function setTokens(access: string, refresh: string) {
  const store = await cookies();
  store.set(ACCESS_COOKIE, access, { ...cookieOptions, maxAge: 7 * 24 * 3600 });
  store.set(REFRESH_COOKIE, refresh, { ...cookieOptions, maxAge: 30 * 24 * 3600 });
}

export async function createSession(access: string, refresh: string) {
  await setTokens(access, refresh);
}

export async function destroySession() {
  const store = await cookies();
  store.delete(ACCESS_COOKIE);
  store.delete(REFRESH_COOKIE);
}

async function refreshAccess(): Promise<boolean> {
  const store = await cookies();
  const refresh = store.get(REFRESH_COOKIE)?.value;
  if (!refresh) return false;
  const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken: refresh }),
  });
  if (!res.ok) return false;
  const tokens = (await res.json()) as { accessToken: string; refreshToken: string };
  await setTokens(tokens.accessToken, tokens.refreshToken);
  return true;
}

export async function api<T = unknown>(path: string, init: RequestInit = {}): Promise<T> {
  const store = await cookies();
  const access = store.get(ACCESS_COOKIE)?.value;

  const buildHeaders = (token?: string) => {
    const headers = new Headers(init.headers);
    headers.set('Content-Type', 'application/json');
    if (token) headers.set('Authorization', `Bearer ${token}`);
    return headers;
  };

  let res = await fetch(`${API_BASE_URL}${path}`, { ...init, headers: buildHeaders(access) });

  if (res.status === 401 && (await refreshAccess())) {
    const store2 = await cookies();
    const token = store2.get(ACCESS_COOKIE)?.value;
    res = await fetch(`${API_BASE_URL}${path}`, { ...init, headers: buildHeaders(token) });
  }

  if (!res.ok) {
    let body: { error?: string; details?: unknown; message?: string } = {};
    try {
      body = await res.json();
    } catch {
      /* empty */
    }
    throw new ApiError(res.status, body.error ?? body.message ?? `HTTP ${res.status}`, body.details);
  }

  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

export async function getSession() {
  const store = await cookies();
  if (!store.has(ACCESS_COOKIE)) return null;
  try {
    const data = await api<{ user: SessionUser }>('/auth/me');
    return data.user;
  } catch {
    return null;
  }
}