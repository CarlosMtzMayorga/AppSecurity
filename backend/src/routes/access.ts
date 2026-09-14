import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createAccessLogSchema,
  approveAccessSchema,
  paginationSchema,
  dateRangeSchema,
} from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const { type, status, unitId, residentId } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (type) where.type = type;
  if (status) where.status = status;
  if (unitId) where.unitId = unitId;
  if (residentId) where.residentId = residentId;
  if (startDate || endDate) {
    where.entryTime = {};
    if (startDate) where.entryTime.gte = new Date(startDate);
    if (endDate) where.entryTime.lte = new Date(endDate);
  }

  const [logs, total] = await Promise.all([
    prisma.accessLog.findMany({
      where,
      include: {
        unit: { select: { number: true, block: true } },
        resident: { select: { user: { select: { firstName: true, lastName: true } } } },
        visitor: { select: { firstName: true, lastName: true } },
        securityUser: { select: { firstName: true, lastName: true } },
      },
      orderBy: { [sortBy || 'entryTime']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.accessLog.count({ where }),
  ]);

  res.json({ data: logs, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/active', asyncHandler(async (req: AuthRequest, res) => {
  const logs = await prisma.accessLog.findMany({
    where: {
      complexId: req.user!.complexId,
      status: 'APPROVED',
      exitTime: null,
    },
    include: {
      unit: { select: { number: true, block: true } },
      resident: { select: { user: { select: { firstName: true, lastName: true } } } },
      visitor: { select: { firstName: true, lastName: true } },
    },
    orderBy: { entryTime: 'asc' },
  });

  res.json(logs);
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const log = await prisma.accessLog.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: {
      unit: { select: { number: true, block: true } },
      resident: { select: { user: { select: { firstName: true, lastName: true } } } },
      visitor: { select: { firstName: true, lastName: true } },
      securityUser: { select: { firstName: true, lastName: true } },
    },
  });

  if (!log) throw new AppError(404, 'Registro de acceso no encontrado');
  res.json(log);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  const data = createAccessLogSchema.parse(req.body);
  
  let residentId: string | undefined;
  if (data.type === 'RESIDENT' || data.type === 'VISITOR') {
    if (req.user!.role === 'RESIDENT') {
      const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
      if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');
      residentId = resident.id;
    } else {
      if (!data.unitId && !data.visitorId) throw new AppError(400, 'unitId o visitorId requerido');
      if (data.unitId) {
        const unit = await prisma.unit.findFirst({ where: { id: data.unitId, complexId: req.user!.complexId } });
        if (!unit) throw new AppError(404, 'Unidad no encontrada');
        const resident = await prisma.resident.findFirst({ where: { unitId: data.unitId, status: 'ACTIVE' } });
        if (resident) residentId = resident.id;
      }
    }
  }

  const log = await prisma.accessLog.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      residentId,
      scheduledEntry: data.scheduledEntry ? new Date(data.scheduledEntry) : null,
      scheduledExit: data.scheduledExit ? new Date(data.scheduledExit) : null,
      securityUserId: req.user!.role === 'SECURITY' ? req.user!.id : undefined,
    },
    include: {
      unit: { select: { number: true, block: true } },
      resident: { select: { user: { select: { firstName: true, lastName: true } } } },
      visitor: { select: { firstName: true, lastName: true } },
    },
  });

  res.status(201).json(log);
}));

router.post('/resident-entry', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');
  
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const log = await prisma.accessLog.create({
    data: {
      complexId: req.user!.complexId!,
      unitId: resident.unitId,
      residentId: resident.id,
      type: 'RESIDENT',
      status: 'APPROVED',
      entryTime: new Date(),
      entryMethod: 'APP',
    },
  });

  res.status(201).json(log);
}));

router.post('/resident-exit', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');
  
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const activeLog = await prisma.accessLog.findFirst({
    where: { residentId: resident.id, status: 'APPROVED', exitTime: null },
    orderBy: { entryTime: 'desc' },
  });

  if (!activeLog) throw new AppError(404, 'No hay entrada activa');

  const updated = await prisma.accessLog.update({
    where: { id: activeLog.id },
    data: { exitTime: new Date(), exitMethod: 'APP', status: 'COMPLETED' },
  });

  res.json(updated);
}));

router.post('/peatonal', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');

  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const log = await prisma.accessLog.create({
    data: {
      complexId: req.user!.complexId!,
      unitId: resident.unitId,
      residentId: resident.id,
      type: 'RESIDENT',
      status: 'APPROVED',
      entryTime: new Date(),
      entryMethod: 'PEATONAL',
    },
  });

  res.status(201).json(log);
}));

router.post('/botonera', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');

  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  res.json({ ok: true, message: 'Botonera activada' });
}));

router.patch('/:id/approve', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'SECURITY', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = approveAccessSchema.parse(req.body);
  
  const log = await prisma.accessLog.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!log) throw new AppError(404, 'Registro no encontrado');

  const updateData: any = { status: data.status, notes: data.notes };
  if (data.status === 'APPROVED' && !log.entryTime) updateData.entryTime = new Date();

  const updated = await prisma.accessLog.update({
    where: { id: log.id },
    data: updateData,
    include: {
      unit: { select: { number: true, block: true } },
      resident: { select: { user: { select: { firstName: true, lastName: true } } } },
      visitor: { select: { firstName: true, lastName: true } },
    },
  });

  res.json(updated);
}));

router.patch('/:id/exit', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'SECURITY', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const log = await prisma.accessLog.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!log) throw new AppError(404, 'Registro no encontrado');
  if (log.exitTime) throw new AppError(400, 'Ya tiene hora de salida');

  const updated = await prisma.accessLog.update({
    where: { id: log.id },
    data: { exitTime: new Date(), exitMethod: 'MANUAL', status: 'COMPLETED' },
  });

  res.json(updated);
}));

router.get('/stats/summary', asyncHandler(async (req: AuthRequest, res) => {
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const complexId = req.user!.complexId!;
  
  const where: any = { complexId };
  if (startDate || endDate) {
    where.entryTime = {};
    if (startDate) where.entryTime.gte = new Date(startDate);
    if (endDate) where.entryTime.lte = new Date(endDate);
  }

  const [total, residents, visitors, services, deliveries, active] = await Promise.all([
    prisma.accessLog.count({ where }),
    prisma.accessLog.count({ where: { ...where, type: 'RESIDENT' } }),
    prisma.accessLog.count({ where: { ...where, type: 'VISITOR' } }),
    prisma.accessLog.count({ where: { ...where, type: 'SERVICE' } }),
    prisma.accessLog.count({ where: { ...where, type: 'DELIVERY' } }),
    prisma.accessLog.count({ where: { complexId, status: 'APPROVED', exitTime: null } }),
  ]);

  res.json({ total, residents, visitors, services, deliveries, active });
}));

export default router;