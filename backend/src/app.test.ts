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
});