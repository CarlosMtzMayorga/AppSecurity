import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'node:path';
import { PrismaClient } from '@prisma/client';
import { errorHandler } from './middleware/errorHandler.js';
import { authMiddleware } from './middleware/auth.js';
import { requestLogger } from './middleware/requestLogger.js';
import authRoutes from './routes/auth.js';
import residentRoutes from './routes/residents.js';
import accessRoutes from './routes/access.js';
import paymentRoutes, { stripeWebhookHandler } from './routes/payments.js';
import noticeRoutes from './routes/notices.js';
import bookingRoutes from './routes/bookings.js';
import serviceRoutes from './routes/services.js';
import accountingRoutes from './routes/accounting.js';
import configRoutes from './routes/config.js';
import unitRoutes from './routes/units.js';
import visitorRoutes from './routes/visitors.js';
import amenityRoutes from './routes/amenities.js';
import dashboardRoutes from './routes/dashboard.js';
import pushRoutes from './routes/push.js';
import { startMonthlyPaymentCron } from './jobs/monthlyPayments.js';

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

const app = express();
const PORT = process.env.PORT || 3000;
const API_PREFIX = process.env.API_PREFIX || '/api/v1';

app.use(cors({
  origin: process.env.FRONTEND_URL?.split(',').map((o) => o.trim()) || ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Stripe webhook: raw body required for signature verification, no authMiddleware. Must run before express.json
app.post(`${API_PREFIX}/payments/webhook/stripe`, express.raw({ type: 'application/json' }), stripeWebhookHandler);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);
app.use('/uploads', express.static(path.resolve(process.cwd(), process.env.UPLOAD_DIR || './uploads')));

app.get('/health', (_, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/residents`, authMiddleware, residentRoutes);
app.use(`${API_PREFIX}/access`, authMiddleware, accessRoutes);
app.use(`${API_PREFIX}/payments`, authMiddleware, paymentRoutes);
app.use(`${API_PREFIX}/notices`, authMiddleware, noticeRoutes);
app.use(`${API_PREFIX}/bookings`, authMiddleware, bookingRoutes);
app.use(`${API_PREFIX}/services`, authMiddleware, serviceRoutes);
app.use(`${API_PREFIX}/accounting`, authMiddleware, accountingRoutes);
app.use(`${API_PREFIX}/config`, authMiddleware, configRoutes);
app.use(`${API_PREFIX}/units`, authMiddleware, unitRoutes);
app.use(`${API_PREFIX}/visitors`, authMiddleware, visitorRoutes);
app.use(`${API_PREFIX}/amenities`, authMiddleware, amenityRoutes);
app.use(`${API_PREFIX}/dashboard`, authMiddleware, dashboardRoutes);
app.use(`${API_PREFIX}/push`, authMiddleware, pushRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint no encontrado', path: req.path });
});

app.use(errorHandler);

async function main() {
  try {
    await prisma.$connect();
    console.log('✅ Conectado a PostgreSQL');
    startMonthlyPaymentCron();
    
    app.listen(PORT, () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
      console.log(`📚 API disponible en http://localhost:${PORT}${API_PREFIX}`);
    });
  } catch (error) {
    console.error('❌ Error al conectar a la base de datos:', error);
    process.exit(1);
  }
}

if (process.env.NODE_ENV !== 'test') {
  main();
}

export { app };

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});