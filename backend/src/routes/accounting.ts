import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createAccountingEntrySchema,
  paginationSchema,
  dateRangeSchema,
} from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const { type, category } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (type) where.type = type;
  if (category) where.category = category;
  if (startDate || endDate) {
    where.date = {};
    if (startDate) where.date.gte = new Date(startDate);
    if (endDate) where.date.lte = new Date(endDate);
  }

  const [entries, total] = await Promise.all([
    prisma.accountingEntry.findMany({
      where,
      orderBy: { [sortBy || 'date']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.accountingEntry.count({ where }),
  ]);

  res.json({ data: entries, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/summary', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const complexId = req.user!.complexId!;
  
  const where: any = { complexId };
  if (startDate || endDate) {
    where.date = {};
    if (startDate) where.date.gte = new Date(startDate);
    if (endDate) where.date.lte = new Date(endDate);
  }

  const [income, expenses, byCategory] = await Promise.all([
    prisma.accountingEntry.aggregate({ where: { ...where, type: 'INCOME' }, _sum: { amount: true } }),
    prisma.accountingEntry.aggregate({ where: { ...where, type: 'EXPENSE' }, _sum: { amount: true } }),
    prisma.accountingEntry.groupBy({ by: ['type', 'category'], where, _sum: { amount: true }, _count: true }),
  ]);

  const incomeTotal = income._sum.amount || 0;
  const expenseTotal = expenses._sum.amount || 0;

  res.json({
    income: incomeTotal,
    expenses: expenseTotal,
    balance: incomeTotal - expenseTotal,
    byCategory: byCategory.map(c => ({
      type: c.type,
      category: c.category,
      amount: c._sum.amount || 0,
      count: c._count,
    })),
  });
}));

router.get('/monthly', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const { year } = req.query;
  const targetYear = year ? parseInt(year as string) : new Date().getFullYear();
  const complexId = req.user!.complexId!;

  const startOfYear = new Date(targetYear, 0, 1);
  const endOfYear = new Date(targetYear, 11, 31, 23, 59, 59);

  const entries = await prisma.accountingEntry.findMany({
    where: { complexId, date: { gte: startOfYear, lte: endOfYear } },
    select: { type: true, amount: true, date: true },
  });

  const monthly = Array.from({ length: 12 }, (_, i) => ({
    month: i + 1,
    income: 0,
    expenses: 0,
  }));

  entries.forEach(e => {
    const month = new Date(e.date).getMonth();
    if (e.type === 'INCOME') monthly[month].income += e.amount;
    else monthly[month].expenses += e.amount;
  });

  res.json(monthly);
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const entry = await prisma.accountingEntry.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!entry) throw new AppError(404, 'Entrada contable no encontrada');
  res.json(entry);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createAccountingEntrySchema.parse(req.body);
  
  const entry = await prisma.accountingEntry.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      date: new Date(data.date),
      createdBy: req.user!.id,
    },
  });

  res.status(201).json(entry);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createAccountingEntrySchema.partial().parse(req.body);
  
  const entry = await prisma.accountingEntry.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!entry) throw new AppError(404, 'Entrada contable no encontrada');

  const updated = await prisma.accountingEntry.update({
    where: { id: entry.id },
    data: { ...data, date: data.date ? new Date(data.date) : undefined },
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const entry = await prisma.accountingEntry.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!entry) throw new AppError(404, 'Entrada contable no encontrada');

  await prisma.accountingEntry.delete({ where: { id: entry.id } });
  res.json({ message: 'Entrada eliminada' });
}));

export default router;