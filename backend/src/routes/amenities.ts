import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import { createAmenitySchema, paginationSchema } from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  
  const where: any = { complexId: req.user!.complexId };
  if (req.user!.role === 'RESIDENT') where.isActive = true;
  
  const [amenities, total] = await Promise.all([
    prisma.amenity.findMany({
      where,
      include: { schedules: true, _count: { select: { bookings: true } } },
      orderBy: { [sortBy || 'name']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.amenity.count({ where }),
  ]);

  res.json({ data: amenities, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const amenity = await prisma.amenity.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: { schedules: true },
  });
  if (!amenity) throw new AppError(404, 'Amenidad no encontrada');
  res.json(amenity);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createAmenitySchema.parse(req.body);
  
  const amenity = await prisma.amenity.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      schedules: data.schedules ? { create: data.schedules } : undefined,
    },
    include: { schedules: true },
  });

  res.status(201).json(amenity);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createAmenitySchema.partial().parse(req.body);
  
  const amenity = await prisma.amenity.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!amenity) throw new AppError(404, 'Amenidad no encontrada');

  if (data.schedules) {
    await prisma.amenitySchedule.deleteMany({ where: { amenityId: amenity.id } });
    await prisma.amenitySchedule.createMany({
      data: data.schedules.map(s => ({ ...s, amenityId: amenity.id })),
    });
  }

  const { schedules, ...rest } = data;
  const updated = await prisma.amenity.update({
    where: { id: amenity.id },
    data: rest,
    include: { schedules: true },
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const amenity = await prisma.amenity.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!amenity) throw new AppError(404, 'Amenidad no encontrada');

  await prisma.amenity.update({ where: { id: amenity.id }, data: { isActive: false } });
  res.json({ message: 'Amenidad desactivada' });
}));

export default router;