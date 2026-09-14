import { Router } from 'express';
import Stripe from 'stripe';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createPaymentSchema,
  updatePaymentSchema,
  paginationSchema,
  dateRangeSchema,
} from '../validators/schemas.js';

const router = Router();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', { apiVersion: '2023-10-16' });

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const { status, type, residentId, unitId } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (resident) where.residentId = resident.id;
  }
  if (status) where.status = status;
  if (type) where.type = type;
  if (residentId && req.user!.role !== 'RESIDENT') where.residentId = residentId;
  if (unitId) where.unitId = unitId;
  if (startDate || endDate) {
    where.dueDate = {};
    if (startDate) where.dueDate.gte = new Date(startDate);
    if (endDate) where.dueDate.lte = new Date(endDate);
  }

  const [payments, total] = await Promise.all([
    prisma.payment.findMany({
      where,
      include: {
        resident: { select: { user: { select: { firstName: true, lastName: true } }, unit: { select: { number: true } } } },
        unit: { select: { number: true, block: true } },
      },
      orderBy: { [sortBy || 'dueDate']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.payment.count({ where }),
  ]);

  res.json({ data: payments, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/my-payments', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');
  
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const payments = await prisma.payment.findMany({
    where: { residentId: resident.id },
    include: { unit: { select: { number: true } } },
    orderBy: { dueDate: 'desc' },
  });

  res.json(payments);
}));

router.get('/stats/summary', asyncHandler(async (req: AuthRequest, res) => {
  const complexId = req.user!.complexId!;
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  
  const where: any = { complexId };
  if (startDate || endDate) {
    where.dueDate = {};
    if (startDate) where.dueDate.gte = new Date(startDate);
    if (endDate) where.dueDate.lte = new Date(endDate);
  }

  const [total, pending, completed, failed, overdue, byType] = await Promise.all([
    prisma.payment.aggregate({ where, _sum: { amount: true } }),
    prisma.payment.count({ where: { ...where, status: 'PENDING' } }),
    prisma.payment.count({ where: { ...where, status: 'COMPLETED' } }),
    prisma.payment.count({ where: { ...where, status: 'FAILED' } }),
    prisma.payment.count({ where: { ...where, status: 'OVERDUE' } }),
    prisma.payment.groupBy({ by: ['type'], where, _sum: { amount: true }, _count: true }),
  ]);

  res.json({
    totalAmount: total._sum.amount || 0,
    pending,
    completed,
    failed,
    overdue,
    byType: byType.map(t => ({ type: t.type, amount: t._sum.amount || 0, count: t._count })),
  });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: {
      resident: { select: { user: { select: { firstName: true, lastName: true, email: true } }, unit: { select: { number: true } } } },
      unit: { select: { number: true, block: true } },
    },
  });

  if (!payment) throw new AppError(404, 'Pago no encontrado');
  res.json(payment);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createPaymentSchema.parse(req.body);
  
  const resident = await prisma.resident.findFirst({
    where: { id: data.residentId, complexId: req.user!.complexId },
  });
  if (!resident) throw new AppError(404, 'Residente no encontrado');

  const unit = await prisma.unit.findFirst({
    where: { id: resident.unitId, complexId: req.user!.complexId },
  });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');

  const reference = `PAY-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

  const payment = await prisma.payment.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      unitId: unit.id,
      userId: req.user!.id,
      reference,
      dueDate: new Date(data.dueDate),
      periodStart: data.periodStart ? new Date(data.periodStart) : null,
      periodEnd: data.periodEnd ? new Date(data.periodEnd) : null,
    },
  });

  res.status(201).json(payment);
}));

router.post('/bulk', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const { type, amount, description, dueDate, periodStart, periodEnd, residentIds } = req.body;
  
  const residents = await prisma.resident.findMany({
    where: { id: { in: residentIds }, complexId: req.user!.complexId, status: 'ACTIVE' },
    include: { unit: true },
  });

  const payments = await Promise.all(residents.map(async (resident) => {
    const reference = `PAY-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    return prisma.payment.create({
      data: {
        complexId: req.user!.complexId!,
        residentId: resident.id,
        unitId: resident.unitId,
        userId: req.user!.id,
        type,
        amount,
        description,
        reference,
        dueDate: new Date(dueDate),
        periodStart: periodStart ? new Date(periodStart) : null,
        periodEnd: periodEnd ? new Date(periodEnd) : null,
      },
    });
  }));

  res.status(201).json({ created: payments.length, payments });
}));

router.post('/:id/webhook/test', asyncHandler(async (req: AuthRequest, res) => {
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!payment) throw new AppError(404, 'Pago no encontrado');
  if (payment.status === 'COMPLETED') throw new AppError(400, 'Pago ya completado');

  await prisma.payment.update({
    where: { id: payment.id },
    data: { status: 'COMPLETED', paidAt: new Date() },
  });

  const existing = await prisma.accountingEntry.findFirst({
    where: { reference: payment.id },
  });
  if (!existing) {
    await prisma.accountingEntry.create({
      data: {
        complexId: payment.complexId,
        type: 'INCOME',
        category: payment.type,
        amount: payment.amount,
        description: `Pago app - ${payment.reference}`,
        reference: payment.id,
        date: new Date(),
        createdBy: req.user!.id,
      },
    });
  }

  res.json({ message: 'Pago completado' });
}));

router.post('/:id/stripe-intent', asyncHandler(async (req: AuthRequest, res) => {
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: { resident: { select: { user: { select: { email: true } } } } },
  });

  if (!payment) throw new AppError(404, 'Pago no encontrado');
  if (payment.status === 'COMPLETED') throw new AppError(400, 'Pago ya completado');

  let customerId = payment.stripeCustomerId;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: payment.resident.user.email,
      metadata: { paymentId: payment.id },
    });
    customerId = customer.id;
    await prisma.payment.update({ where: { id: payment.id }, data: { stripeCustomerId: customerId } });
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(payment.amount * 100),
    currency: payment.currency.toLowerCase(),
    customer: customerId,
    metadata: { paymentId: payment.id },
    automatic_payment_methods: { enabled: true },
  });

  await prisma.payment.update({
    where: { id: payment.id },
    data: { stripePaymentIntentId: paymentIntent.id },
  });

  res.json({ clientSecret: paymentIntent.client_secret });
}));

router.post('/webhook/stripe', asyncHandler(async (req: AuthRequest, res) => {
  const sig = req.headers['stripe-signature']!;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;
  
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err: any) {
    console.error('Webhook error:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  if (event.type === 'payment_intent.succeeded') {
    const intent = event.data.object as Stripe.PaymentIntent;
    const paymentId = intent.metadata.paymentId;
    
    await prisma.payment.update({
      where: { id: paymentId },
      data: { status: 'COMPLETED', paidAt: new Date() },
    });

    await prisma.accountingEntry.create({
      data: {
        complexId: (await prisma.payment.findUnique({ where: { id: paymentId }, select: { complexId: true } }))!.complexId,
        type: 'INCOME',
        category: 'MAINTENANCE',
        amount: intent.amount / 100,
        description: `Pago Stripe - ${intent.id}`,
        reference: paymentId,
        date: new Date(),
        createdBy: 'STRIPE_WEBHOOK',
      },
    });
  } else if (event.type === 'payment_intent.payment_failed') {
    const intent = event.data.object as Stripe.PaymentIntent;
    const paymentId = intent.metadata.paymentId;
    await prisma.payment.update({
      where: { id: paymentId },
      data: { status: 'FAILED' },
    });
  }

  res.json({ received: true });
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = updatePaymentSchema.parse(req.body);
  
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!payment) throw new AppError(404, 'Pago no encontrado');

  const updated = await prisma.payment.update({
    where: { id: payment.id },
    data: {
      ...data,
      paidAt: data.paidAt ? new Date(data.paidAt) : undefined,
    },
  });

  if (data.status === 'COMPLETED' && payment.status !== 'COMPLETED') {
    await prisma.accountingEntry.create({
      data: {
        complexId: req.user!.complexId!,
        type: 'INCOME',
        category: payment.type,
        amount: payment.amount,
        description: `Pago manual - ${payment.reference}`,
        reference: payment.id,
        date: new Date(),
        createdBy: req.user!.id,
      },
    });
  }

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!payment) throw new AppError(404, 'Pago no encontrado');

  await prisma.payment.delete({ where: { id: payment.id } });
  res.json({ message: 'Pago eliminado' });
}));

export default router;