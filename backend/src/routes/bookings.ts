import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createBookingSchema,
  updateBookingSchema,
  paginationSchema,
  dateRangeSchema,
} from '../validators/schemas.js';
import { sendPushToUsers } from '../services/pushService.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { startDate, endDate } = dateRangeSchema.parse(req.query);
  const { status, amenityId, unitId } = req.query;
  
  const where: any = { complexId: req.user!.complexId };
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (resident) where.unitId = resident.unitId;
  }
  if (status) where.status = status;
  if (amenityId) where.amenityId = amenityId;
  if (unitId && req.user!.role !== 'RESIDENT') where.unitId = unitId;
  if (startDate || endDate) {
    where.startTime = {};
    if (startDate) where.startTime.gte = new Date(startDate);
    if (endDate) where.startTime.lte = new Date(endDate);
  }

  const [bookings, total] = await Promise.all([
    prisma.booking.findMany({
      where,
      include: {
        amenity: { select: { name: true, location: true, pricePerHour: true } },
        unit: { select: { number: true, block: true } },
        user: { select: { firstName: true, lastName: true } },
      },
      orderBy: { [sortBy || 'startTime']: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.booking.count({ where }),
  ]);

  res.json({ data: bookings, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/my-bookings', asyncHandler(async (req: AuthRequest, res) => {
  if (req.user!.role !== 'RESIDENT') throw new AppError(403, 'Solo residentes');
  
  const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
  if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');

  const bookings = await prisma.booking.findMany({
    where: { unitId: resident.unitId },
    include: { amenity: { select: { name: true, location: true, pricePerHour: true } } },
    orderBy: { startTime: 'desc' },
  });

  res.json(bookings);
}));

router.get('/availability/:amenityId', asyncHandler(async (req: AuthRequest, res) => {
  const { date } = req.query;
  const amenityId = req.params.amenityId;
  
  const amenity = await prisma.amenity.findUnique({
    where: { id: amenityId, complexId: req.user!.complexId },
    include: { schedules: true },
  });
  if (!amenity) throw new AppError(404, 'Amenidad no encontrada');

  const targetDate = date ? new Date(date as string) : new Date();
  const dayOfWeek = targetDate.getDay();
  const schedule = amenity.schedules.find(s => s.dayOfWeek === dayOfWeek && !s.isClosed);
  
  if (!schedule) {
    return res.json({ available: false, reason: 'Cerrado este día', slots: [] });
  }

  const bookings = await prisma.booking.findMany({
    where: {
      amenityId,
      startTime: { gte: new Date(targetDate.setHours(0,0,0,0)), lt: new Date(targetDate.setHours(23,59,59,999)) },
      status: { in: ['PENDING', 'CONFIRMED'] },
    },
    select: { startTime: true, endTime: true },
  });

  const slots = [];
  const [openH, openM] = schedule.openTime.split(':').map(Number);
  const [closeH, closeM] = schedule.closeTime.split(':').map(Number);
  
  let current = new Date(targetDate);
  current.setHours(openH, openM, 0, 0);
  const end = new Date(targetDate);
  end.setHours(closeH, closeM, 0, 0);

  while (current < end) {
    const slotEnd = new Date(current.getTime() + 60 * 60 * 1000); // 1 hour slots
    if (slotEnd > end) break;
    
    const isBooked = bookings.some(b => 
      current >= new Date(b.startTime) && current < new Date(b.endTime)
    );
    
    slots.push({
      start: current.toISOString(),
      end: slotEnd.toISOString(),
      available: !isBooked,
    });
    
    current = slotEnd;
  }

  res.json({ available: true, slots });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const booking = await prisma.booking.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: {
      amenity: { select: { name: true, location: true, pricePerHour: true, rules: true } },
      unit: { select: { number: true, block: true } },
      user: { select: { firstName: true, lastName: true, phone: true, email: true } },
    },
  });

  if (!booking) throw new AppError(404, 'Reserva no encontrada');
  res.json(booking);
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  const data = createBookingSchema.parse(req.body);
  
  let unitId: string;
  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident) throw new AppError(404, 'Perfil de residente no encontrado');
    unitId = resident.unitId;
  } else {
    unitId = data.unitId;
  }

  const amenity = await prisma.amenity.findFirst({
    where: { id: data.amenityId, complexId: req.user!.complexId, isActive: true },
  });
  if (!amenity) throw new AppError(404, 'Amenidad no encontrada');

  const unit = await prisma.unit.findFirst({ where: { id: unitId, complexId: req.user!.complexId } });
  if (!unit) throw new AppError(404, 'Unidad no encontrada');

  const startTime = new Date(data.startTime);
  const endTime = new Date(data.endTime);
  const hours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);

  if (hours > amenity.maxHoursPerBooking) {
    throw new AppError(400, `Máximo ${amenity.maxHoursPerBooking} horas por reserva`);
  }

  const noticeHours = (startTime.getTime() - Date.now()) / (1000 * 60 * 60);
  if (noticeHours < amenity.minHoursNotice) {
    throw new AppError(400, `Reserva mínima con ${amenity.minHoursNotice} horas de anticipación`);
  }

  const maxAdvance = new Date();
  maxAdvance.setDate(maxAdvance.getDate() + amenity.maxDaysAdvance);
  if (startTime > maxAdvance) {
    throw new AppError(400, `Máximo ${amenity.maxDaysAdvance} días de anticipación`);
  }

  const conflicting = await prisma.booking.findFirst({
    where: {
      amenityId: data.amenityId,
      status: { in: ['PENDING', 'CONFIRMED'] },
      OR: [
        { startTime: { lt: endTime }, endTime: { gt: startTime } },
      ],
    },
  });

  if (conflicting) throw new AppError(409, 'Horario no disponible');

  const totalPrice = hours * amenity.pricePerHour;

  const booking = await prisma.booking.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      unitId,
      userId: req.user!.id,
      residentId: (await prisma.resident.findUnique({ where: { unitId } }))!.id,
      startTime,
      endTime,
      totalPrice,
      status: amenity.requiresApproval ? 'PENDING' : 'CONFIRMED',
    },
    include: { amenity: { select: { name: true } } },
  });

  res.status(201).json(booking);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const data = updateBookingSchema.parse(req.body);
  
  const booking = await prisma.booking.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!booking) throw new AppError(404, 'Reserva no encontrada');

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident || booking.unitId !== resident.unitId) throw new AppError(403, 'Sin permisos');
    if (data.status && data.status !== 'CANCELLED') throw new AppError(403, 'Solo puedes cancelar');
  }

  const updated = await prisma.booking.update({
    where: { id: booking.id },
    data: {
      ...data,
      approvedBy: data.status === 'CONFIRMED' ? req.user!.id : undefined,
      approvedAt: data.status === 'CONFIRMED' ? new Date() : undefined,
    },
    include: { amenity: { select: { name: true } } },
  });

  if (data.status && data.status !== booking.status && ['CONFIRMED', 'CANCELLED', 'REJECTED'].includes(data.status)) {
    const labels: Record<string, string> = {
      CONFIRMED: '✓ Reserva confirmada',
      CANCELLED: 'Reserva cancelada',
      REJECTED: 'Reserva rechazada',
    };
    sendPushToUsers([updated.userId], {
      title: labels[data.status],
      body: `Tu reserva de ${updated.amenity.name} ${data.status === 'REJECTED' && data.rejectionReason ? `(${data.rejectionReason})` : ''}`.trim(),
      route: `/bookings/${updated.id}`,
    }).catch((e) => console.error('Error enviando push de reserva:', e));
  }

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const booking = await prisma.booking.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!booking) throw new AppError(404, 'Reserva no encontrada');

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (!resident || booking.unitId !== resident.unitId) throw new AppError(403, 'Sin permisos');
  }

  await prisma.booking.delete({ where: { id: booking.id } });
  res.json({ message: 'Reserva eliminada' });
}));

export default router;