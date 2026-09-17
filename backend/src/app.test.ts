import { describe, it, expect, afterAll } from 'vitest';
import request from 'supertest';
import { prisma } from './index.js';

const dbAvailable = await prisma.$connect()
  .then(() => true)
  .catch(() => false);

afterAll(async () => {
  await prisma.$disconnect();
});

const dbTest = dbAvailable ? describe : describe.skip;

describe('App HTTP', () => {
  it('GET /health devuelve ok', async () => {
    const { app } = await import('./index.js');
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('devuelve 404 para rutas desconocidas', async () => {
    const { app } = await import('./index.js');
    const res = await request(app).get('/ruta-inexistente');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
  });

  it('pide autenticación para rutas protegidas', async () => {
    const { app } = await import('./index.js');
    const res = await request(app).get('/api/v1/notices');
    expect(res.status).toBe(401);
  });
});

dbTest('App HTTP con base de datos', () => {
  let residentAccessToken: string | null = null;

  async function getResidentToken() {
    if (residentAccessToken) return residentAccessToken;
    // jsonwebtoken usa iat con resolución de 1 segundo; esperamos para evitar
    // colisiones de refresh token entre logins cercanos.
    await new Promise((r) => setTimeout(r, 1200));
    const { app } = await import('./index.js');
    const login = await request(app).post('/api/v1/auth/login').send({
      email: 'juan.perez@email.com',
      password: 'password123',
    });
    residentAccessToken = login.body.accessToken as string;
    return residentAccessToken;
  }

  it('login devuelve tokens y user', async () => {
    const { app } = await import('./index.js');
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'juan.perez@email.com',
      password: 'password123',
    });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user.email).toBe('juan.perez@email.com');
  });

  it('login rechaza credenciales inválidas', async () => {
    const { app } = await import('./index.js');
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'juan.perez@email.com',
      password: 'incorrecta',
    });
    expect(res.status).toBe(401);
  });

  it('registra y elimina un push token', async () => {
    const { app } = await import('./index.js');
    const accessToken = await getResidentToken();
    const fcmToken = `test-fcm-token-${Date.now()}`;

    const created = await request(app)
      .post('/api/v1/push/tokens')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ token: fcmToken, platform: 'web', deviceName: 'vitest' });
    expect(created.status).toBe(201);
    expect(created.body.token).toBe(fcmToken);

    const listed = await request(app)
      .get('/api/v1/push/tokens')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(listed.status).toBe(200);
    expect(listed.body.some((t: { token: string }) => t.token === fcmToken)).toBe(true);

    const removed = await request(app)
      .delete(`/api/v1/push/tokens?token=${encodeURIComponent(fcmToken)}`)
      .set('Authorization', `Bearer ${accessToken}`);
    expect(removed.status).toBe(200);
  });

  it('expone config de mensajería protegida', async () => {
    const { app } = await import('./index.js');
    const unauth = await request(app).get('/api/v1/config/messaging');
    expect(unauth.status).toBe(401);

    const accessToken = await getResidentToken();
    const res = await request(app)
      .get('/api/v1/config/messaging')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('enabled');
    expect(res.body).toHaveProperty('vapidKey');
    expect(res.body.firebase).toHaveProperty('projectId');
  });
});