import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createServiceRequestSchema,
  updateServiceRequestSchema,
  paginationSchema,
  dateRangeSchema,
} from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const { status, priority, category, assigneeId, unitId } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (resident) where.unitId = resident.unitId;
  }
  if (status) where.status = status;
  if (priority) where.priority = priority;
  if (category) where.category = category;
  if (assigneeId) where.assigneeId = assigneeId;
  if (unitId && req.user!.role !== 'RESIDENT') where.unitId = unitId;
  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt.gte = new Date(startDate);
    if (endDate) where.createdAt.lte = new Date(endDate);
  }

  const [requests, total] = await Promise.all([
    prisma.serviceRequest.findMany({
      where,
      include: {
        unit: { select: { number: true, block: true } },
        user: { select: { firstName: true, lastName: true, phone: true } },
        assignee: { select: { firstName: true, lastName: true } },
      },
      orderBy: { [sortBy || 'createdAt']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.serviceRequest.count({ where }),
  ]);

  res.json({ data: requests, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/my-requests', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');
  
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const requests = await prisma.serviceRequest.findMany({
    where: { unitId: resident.unitId },
    include: { assignee: { select: { firstName: true, lastName: true } } },
    orderBy: { createdAt: 'desc' },
  });

  res.json(requests);
}));

router.get('/assigned', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const requests = await prisma.serviceRequest.findMany({
    where: { assigneeId: req.user!.id, complexId: req.user!.complexId },
    include: { unit: { select: { number: true, block: true } }, user: { select: { firstName: true, lastName: true, phone: true } } },
    orderBy: { createdAt: 'desc' },
  });

  res.json(requests);
}));

router.get('/stats/summary', asyncHandler(async (req: AuthRequest, res) => {
  const complexId = req.user!.complexId!;
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  
  const where: any = { complexId };
  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt.gte = new Date(startDate);
    if (endDate) where.createdAt.lte = new Date(endDate);
  }

  const [total, open, inProgress, resolved, closed, byPriority, byCategory] = await Promise.all([
    prisma.serviceRequest.count({ where }),
    prisma.serviceRequest.count({ where: { ...where, status: 'OPEN' } }),
    prisma.serviceRequest.count({ where: { ...where, status: 'IN_PROGRESS' } }),
    prisma.serviceRequest.count({ where: { ...where, status: 'RESOLVED' } }),
    prisma.serviceRequest.count({ where: { ...where, status: 'CLOSED' } }),
    prisma.serviceRequest.groupBy({ by: ['priority'], where, _count: true }),
    prisma.serviceRequest.groupBy({ by: ['category'], where, _count: true }),
  ]);

  res.json({
    total, open, inProgress, resolved, closed,
    byPriority: byPriority.map(p => ({ priority: p.priority, count: p._count })),
    byCategory: byCategory.map(c => ({ category: c.category, count: c._count })),
  });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const request = await prisma.serviceRequest.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: {
      unit: { select: { number: true, block: true } },
      user: { select: { firstName: true, lastName: true, phone: true, email: true } },
      assignee: { select: { firstName: true, lastName: true, phone: true } },
    },
  });

  if (!request) throw new AppError(404, 'Solicitud no encontrada');
  res.json(request);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  const data = createServiceRequestSchema.parse(req.body);
  
  let unitId: string;
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');
    unitId = resident.unitId;
  } else {
    unitId = data.unitId;
  }

  const unit = await prisma.unit.findFirst({ where: { id: unitId, complexId: req.user!.complexId } });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');

  const request = await prisma.serviceRequest.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      unitId,
      userId: req.user!.id,
      scheduledAt: data.scheduledAt ? new Date(data.scheduledAt) : null,
    },
    include: { unit: { select: { number: true } } },
  });

  res.status(201).json(request);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const data = updateServiceRequestSchema.parse(req.body);
  
  const request = await prisma.serviceRequest.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!request) throw new AppError(404, 'Solicitud no encontrada');

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident || request.unitId !== resident.unitId) throw new AppError(403, 'Sin permisos');
  }

  const updateData: any = { ...data };
  if (data.status === 'IN_PROGRESS' && request.status !== 'IN_PROGRESS') updateData.startedAt = new Date();
  if (data.status === 'RESOLVED' && request.status !== 'RESOLVED') updateData.resolvedAt = new Date();
  if (data.status === 'CLOSED' && request.status !== 'CLOSED') updateData.closedAt = new Date();

  const updated = await prisma.serviceRequest.update({
    where: { id: request.id },
    data: updateData,
    include: { assignee: { select: { firstName: true, lastName: true } } },
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const request = await prisma.serviceRequest.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!request) throw new AppError(404, 'Solicitud no encontrada');

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident || request.unitId !== resident.unitId) throw new AppError(403, 'Sin permisos');
  }

  await prisma.serviceRequest.delete({ where: { id: request.id } });
  res.json({ message: 'Solicitud eliminada' });
}));

export default router;