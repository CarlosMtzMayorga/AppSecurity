import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createResidentSchema,
  updateResidentSchema,
  paginationSchema,
} from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { status, search } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (status) where.status = status;
  if (search) {
    where.OR = [
      { user: { firstName: { contains: search as string, mode: 'insensitive' } } },
      { user: { lastName: { contains: search as string, mode: 'insensitive' } } },
      { user: { email: { contains: search as string, mode: 'insensitive' } } },
      { unit: { number: { contains: search as string, mode: 'insensitive' } } },
    ];
  }

  const [residents, total] = await Promise.all([
    prisma.resident.findMany({
      where,
      include: {
        user: { select: { id: true, email: true, firstName: true, lastName: true, phone: true, avatarUrl: true, lastLoginAt: true } },
        unit: { select: { id: true, number: true, block: true, floor: true, type: true } },
      },
      orderBy: { [sortBy || 'createdAt']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.resident.count({ where }),
  ]);

  res.json({
    data: residents,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
}));

router.get('/stats', asyncHandler(async (req: AuthRequest, res) => {
  const complexId = req.user!.complexId!;
  
  const [total, active, pending, inactive, suspended] = await Promise.all([
    prisma.resident.count({ where: { complexId } }),
    prisma.resident.count({ where: { complexId, status: 'ACTIVE' } }),
    prisma.resident.count({ where: { complexId, status: 'PENDING' } }),
    prisma.resident.count({ where: { complexId, status: 'INACTIVE' } }),
    prisma.resident.count({ where: { complexId, status: 'SUSPENDED' } }),
  ]);

  res.json({ total, active, pending, inactive, suspended });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const resident = await prisma.resident.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: {
      user: { select: { id: true, email: true, firstName: true, lastName: true, phone: true, avatarUrl: true, lastLoginAt: true, createdAt: true } },
      unit: { select: { id: true, number: true, block: true, floor: true, type: true, area: true, monthlyFee: true } },
      visitors: { orderBy: { createdAt: 'desc' }, take: 10 },
      accesses: { orderBy: { entryTime: 'desc' }, take: 20 },
      payments: { orderBy: { dueDate: 'desc' }, take: 10 },
    },
  });

  if (!resident) {
    throw new AppError(404, 'Residente no encontrado');
  }

  res.json(resident);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  const data = createResidentSchema.parse(req.body);
  
  const existingUser = await prisma.user.findUnique({ where: { email: data.email } });
  if (existingUser) {
    throw new AppError(409, 'El email ya está registrado');
  }

  const unit = await prisma.unit.findFirst({
    where: { id: data.unitId, complexId: req.user!.complexId },
  });
  if (!unit) {
    throw new AppError(404, 'Unidad no encontrada');
  }

  const passwordHash = await import('bcryptjs').then(m => m.default.hash(Math.random().toString(36).slice(-8), 12));
  
  const user = await prisma.user.create({
    data: {
      email: data.email,
      passwordHash,
      firstName: data.firstName,
      lastName: data.lastName,
      phone: data.phone,
      role: 'RESIDENT',
    },
  });

  const resident = await prisma.resident.create({
    data: {
      userId: user.id,
      complexId: req.user!.complexId!,
      unitId: data.unitId,
      status: 'PENDING',
      rut: data.rut,
      emergencyContactName: data.emergencyContactName,
      emergencyContactPhone: data.emergencyContactPhone,
      emergencyContactRelation: data.emergencyContactRelation,
      vehiclePlates: data.vehiclePlates || [],
    },
    include: { user: true, unit: true },
  });

  res.status(201).json(resident);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const data = updateResidentSchema.parse(req.body);
  
  const resident = await prisma.resident.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!resident) {
    throw new AppError(404, 'Residente no encontrado');
  }

  const updated = await prisma.resident.update({
    where: { id: resident.id },
    data,
    include: { user: true, unit: true },
  });

  if (data.status === 'ACTIVE' && resident.status !== 'ACTIVE') {
    await prisma.resident.update({
      where: { id: resident.id },
      data: { approvedAt: new Date(), approvedBy: req.user!.id },
    });
  }

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const resident = await prisma.resident.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!resident) {
    throw new AppError(404, 'Residente no encontrado');
  }

  await prisma.resident.update({
    where: { id: resident.id },
    data: { status: 'INACTIVE' },
  });

  res.json({ message: 'Residente desactivado' });
}));

router.post('/:id/approve', asyncHandler(async (req: AuthRequest, res) => {
  const resident = await prisma.resident.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!resident) {
    throw new AppError(404, 'Residente no encontrado');
  }

  const updated = await prisma.resident.update({
    where: { id: resident.id },
    data: { status: 'ACTIVE', approvedAt: new Date(), approvedBy: req.user!.id },
    include: { user: true, unit: true },
  });

  res.json(updated);
}));

router.post('/:id/qr-code', asyncHandler(async (req: AuthRequest, res) => {
  const resident = await prisma.resident.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });

  if (!resident) {
    throw new AppError(404, 'Residente no encontrado');
  }

  const qrCode = `APPSEC-${resident.id}-${Date.now()}`;
  
  const updated = await prisma.resident.update({
    where: { id: resident.id },
    data: { qrCode },
  });

  res.json({ qrCode: updated.qrCode });
}));

export default router;