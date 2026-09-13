import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import { createUnitSchema, paginationSchema } from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { block, hasResident } = req.query;
  
  const where: any = { complexId: req.user!.complexId, isActive: true };
  if (block) where.block = block;
  
  const [units, total] = await Promise.all([
    prisma.unit.findMany({
      where,
      include: {
        residents: { take: 1, select: { id: true, user: { select: { firstName: true, lastName: true } }, status: true } },
      },
      orderBy: { [sortBy || 'number']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.unit.count({ where }),
  ]);

  const unitsWithStatus = units.map(u => {
    const resident = u.residents[0] ?? null;
    return {
      ...u,
      hasResident: !!resident,
      residentName: resident?.user ? `${resident.user.firstName} ${resident.user.lastName}` : null,
      residentStatus: resident?.status || null,
    };
  });

  res.json({ data: unitsWithStatus, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/blocks', asyncHandler(async (req: AuthRequest, res) => {
  const blocks = await prisma.unit.findMany({
    where: { complexId: req.user!.complexId, isActive: true },
    select: { block: true },
    distinct: ['block'],
  });
  res.json(blocks.map(b => b.block).filter(Boolean));
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const unit = await prisma.unit.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: { residents: { take: 1, include: { user: { select: { firstName: true, lastName: true, email: true, phone: true } } } } },
  });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');
  res.json(unit);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createUnitSchema.parse(req.body);
  
  const existing = await prisma.unit.findFirst({
    where: { complexId: req.user!.complexId, number: data.number },
  });
  if (existing) throw new AppError(409, 'El número de unidad ya existe');

  const unit = await prisma.unit.create({
    data: { ...data, complexId: req.user!.complexId! },
  });

  res.status(201).json(unit);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createUnitSchema.partial().parse(req.body);
  
  const unit = await prisma.unit.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');

  if (data.number && data.number !== unit.number) {
    const existing = await prisma.unit.findFirst({
      where: { complexId: req.user!.complexId, number: data.number },
    });
    if (existing) throw new AppError(409, 'El número de unidad ya existe');
  }

  const updated = await prisma.unit.update({
    where: { id: unit.id },
    data,
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const unit = await prisma.unit.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');

  if (unit.residents.length) {
    throw new AppError(400, 'No se puede eliminar una unidad con residente asignado');
  }

  await prisma.unit.update({ where: { id: unit.id }, data: { isActive: false } });
  res.json({ message: 'Unidad desactivada' });
}));

export default router;