import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import { dateRangeSchema } from '../validators/schemas.js';

const router = Router();

router.get('/overview', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const complexId = req.user!.complexId!;
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  
  const dateWhere: any = {};
  if (startDate || endDate) {
    if (startDate) dateWhere.gte = new Date(startDate);
    if (endDate) dateWhere.lte = new Date(endDate);
  }

  const [
    totalResidents,
    activeResidents,
    totalUnits,
    occupiedUnits,
    totalPayments,
    pendingPayments,
    overduePayments,
    totalIncome,
    totalExpenses,
    openRequests,
    activeAccesses,
    noticesCount,
  ] = await Promise.all([
    prisma.resident.count({ where: { complexId } }),
    prisma.resident.count({ where: { complexId, status: 'ACTIVE' } }),
    prisma.unit.count({ where: { complexId, isActive: true } }),
    prisma.unit.count({ where: { complexId, isActive: true, resident: { status: 'ACTIVE' } } }),
    prisma.payment.count({ where: { complexId, ...(Object.keys(dateWhere).length ? { dueDate: dateWhere } : {}) } }),
    prisma.payment.count({ where: { complexId, status: 'PENDING', ...(Object.keys(dateWhere).length ? { dueDate: dateWhere } : {}) } }),
    prisma.payment.count({ where: { complexId, status: 'OVERDUE', ...(Object.keys(dateWhere).length ? { dueDate: dateWhere } : {}) } }),
    prisma.accountingEntry.aggregate({ where: { complexId, type: 'INCOME', ...(Object.keys(dateWhere).length ? { date: dateWhere } : {}) }, _sum: { amount: true } }),
    prisma.accountingEntry.aggregate({ where: { complexId, type: 'EXPENSE', ...(Object.keys(dateWhere).length ? { date: dateWhere } : {}) }, _sum: { amount: true } }),
    prisma.serviceRequest.count({ where: { complexId, status: { in: ['OPEN', 'IN_PROGRESS'] }, ...(Object.keys(dateWhere).length ? { createdAt: dateWhere } : {}) } }),
    prisma.accessLog.count({ where: { complexId, status: 'APPROVED', exitTime: null } }),
    prisma.notice.count({ where: { complexId, publishAt: { lte: new Date() }, OR: [{ expiresAt: null }, { expiresAt: { gte: new Date() } }] } }),
  ]);

  res.json({
    residents: { total: totalResidents, active: activeResidents, occupancyRate: totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0 },
    units: { total: totalUnits, occupied: occupiedUnits, vacant: totalUnits - occupiedUnits },
    payments: { total: totalPayments, pending: pendingPayments, overdue: overduePayments },
    finances: { income: totalIncome._sum.amount || 0, expenses: totalExpenses._sum.amount || 0, balance: (totalIncome._sum.amount || 0) - (totalExpenses._sum.amount || 0) },
    services: { open: openRequests },
    security: { activeAccesses },
    communications: { notices: noticesCount },
  });
}));

router.get('/recent-activity', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const complexId = req.user!.complexId!;
  
  const [recentAccesses, recentPayments, recentRequests, recentNotices] = await Promise.all([
    prisma.accessLog.findMany({
      where: { complexId },
      include: { unit: { select: { number: true } }, resident: { select: { user: { select: { firstName: true, lastName: true } } } }, visitor: { select: { firstName: true, lastName: true } } },
      orderBy: { entryTime: 'desc' },
      take: 10,
    }),
    prisma.payment.findMany({
      where: { complexId },
      include: { resident: { select: { user: { select: { firstName: true, lastName: true } }, unit: { select: { number: true } } } } },
      orderBy: { createdAt: 'desc' },
      take: 10,
    }),
    prisma.serviceRequest.findMany({
      where: { complexId },
      include: { unit: { select: { number: true } }, user: { select: { firstName: true, lastName: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10,
    }),
    prisma.notice.findMany({
      where: { complexId },
      include: { author: { select: { firstName: true, lastName: true } } },
      orderBy: { publishAt: 'desc' },
      take: 5,
    }),
  ]);

  res.json({ recentAccesses, recentPayments, recentRequests, recentNotices });
}));

router.get('/payment-trends', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const complexId = req.user!.complexId!;
  const { months = '6' } = req.query;
  const monthsNum = parseInt(months as string);
  
  const startDate = new Date();
  startDate.setMonth(startDate.getMonth() - monthsNum);
  
  const payments = await prisma.payment.findMany({
    where: { complexId, dueDate: { gte: startDate } },
    select: { dueDate: true, amount: true, status: true },
  });

  const monthly = new Map<string, { collected: number; pending: number; overdue: number }>();
  
  payments.forEach(p => {
    const key = p.dueDate.toISOString().substring(0, 7); // YYYY-MM
    const entry = monthly.get(key) || { collected: 0, pending: 0, overdue: 0 };
    if (p.status === 'COMPLETED') entry.collected += p.amount;
    else if (p.status === 'PENDING') entry.pending += p.amount;
    else if (p.status === 'OVERDUE') entry.overdue += p.amount;
    monthly.set(key, entry);
  });

  const trends = Array.from(monthly.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([month, data]) => ({ month, ...data }));

  res.json(trends);
}));

router.get('/access-trends', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const complexId = req.user!.complexId!;
  const { days = '30' } = req.query;
  const daysNum = parseInt(days as string);
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysNum);
  
  const accesses = await prisma.accessLog.findMany({
    where: { complexId, entryTime: { gte: startDate } },
    select: { entryTime: true, type: true },
  });

  const daily = new Map<string, { total: number; residents: number; visitors: number; services: number }>();
  
  accesses.forEach(a => {
    const key = a.entryTime.toISOString().split('T')[0];
    const entry = daily.get(key) || { total: 0, residents: 0, visitors: 0, services: 0 };
    entry.total++;
    if (a.type === 'RESIDENT') entry.residents++;
    else if (a.type === 'VISITOR') entry.visitors++;
    else if (a.type === 'SERVICE') entry.services++;
    daily.set(key, entry);
  });

  const trends = Array.from(daily.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, data]) => ({ date, ...data }));

  res.json(trends);
}));

export default router;