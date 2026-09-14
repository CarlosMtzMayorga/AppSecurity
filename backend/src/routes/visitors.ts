import { Router } from 'express';
import crypto from 'crypto';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createVisitorSchema,
  updateVisitorSchema,
  paginationSchema,
} from '../validators/schemas.js';

const router = Router();

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const randomEntryCode = () => {
  const bytes = crypto.randomBytes(8);
  let code = '';
  for (let i = 0; i < 8; i++) code += ALPHABET[bytes[i] % ALPHABET.length];
  return code;
};

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { residentId, search } = req.query;
  
  const where: any = { resident: { complexId: req.user!.complexId } };
  if (residentId) where.residentId = residentId;
  if (search) {
    where.OR = [
      { firstName: { contains: search as string, mode: 'insensitive' } },
      { lastName: { contains: search as string, mode: 'insensitive' } },
      { phone: { contains: search as string, mode: 'insensitive' } },
    ];
  }

  const [visitors, total] = await Promise.all([
    prisma.visitor.findMany({
      where,
      include: {
        resident: { select: { id: true, user: { select: { firstName: true, lastName: true } }, unit: { select: { number: true } } } },
        accesses: { orderBy: { entryTime: 'desc' }, take: 5 },
      },
      orderBy: { [sortBy || 'createdAt']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.visitor.count({ where }),
  ]);

  res.json({ data: visitors, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/my-visitors', asyncHandler(async (req: AuthRequest, res) => {
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const visitors = await prisma.visitor.findMany({
    where: { residentId: resident.id },
    include: { accesses: { orderBy: { entryTime: 'desc' }, take: 5 } },
    orderBy: { createdAt: 'desc' },
  });

  res.json(visitors);
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const visitor = await prisma.visitor.findFirst({
    where: { id: req.params.id, resident: { complexId: req.user!.complexId } },
    include: {
      resident: { select: { id: true, user: { select: { firstName: true, lastName: true } }, unit: { select: { number: true } } } },
      accesses: { orderBy: { entryTime: 'desc' } },
    },
  });

  if (!visitor) throw new AppError(404, 'Visitante no encontrado');
  res.json(visitor);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  const data = createVisitorSchema.parse(req.body);
  
  let residentId: string;
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');
    residentId = resident.id;
  } else {
    if (!data.residentId) throw new AppError(400, 'residentId requerido para admin/seguridad');
    const resident = await prisma.resident.findFirst({
      where: { id: data.residentId, complexId: req.user!.complexId },
    });
    if (!resident) throw new AppError(404, 'Residente no encontrado');
    residentId = resident.id;
  }

  const visitor = await prisma.visitor.create({
    data: { ...data, residentId, entryCode: data.entryCode || randomEntryCode() },
    include: { resident: { select: { user: { select: { firstName: true, lastName: true } } } } },
  });

  res.status(201).json(visitor);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const data = updateVisitorSchema.parse(req.body);
  
  const visitor = await prisma.visitor.findFirst({
    where: { id: req.params.id, resident: { complexId: req.user!.complexId } },
  });

  if (!visitor) throw new AppError(404, 'Visitante no encontrado');

  const updated = await prisma.visitor.update({
    where: { id: visitor.id },
    data,
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const visitor = await prisma.visitor.findFirst({
    where: { id: req.params.id, resident: { complexId: req.user!.complexId } },
  });

  if (!visitor) throw new AppError(404, 'Visitante no encontrado');

  await prisma.visitor.delete({ where: { id: visitor.id } });
  res.json({ message: 'Visitante eliminado' });
}));

export default router;