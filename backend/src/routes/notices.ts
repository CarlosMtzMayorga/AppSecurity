import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  createNoticeSchema,
  updateNoticeSchema,
  paginationSchema,
} from '../validators/schemas.js';

const router = Router();

router.get('/', asyncHandler(async (req: AuthRequest, res) => {
  const { page, limit, sortBy, sortOrder } = paginationSchema.parse(req.query);
  const { type, isPinned } = req.query;
  
  const where: any = { 
    complexId: req.user!.complexId,
    publishAt: { lte: new Date() },
    OR: [
      { expiresAt: null },
      { expiresAt: { gte: new Date() } },
    ],
  };
  if (type) where.type = type;
  if (isPinned !== undefined) where.isPinned = isPinned === 'true';

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (resident) {
      where.AND = [
        { OR: [{ targetRoles: { has: 'RESIDENT' } }, { targetRoles: { equals: [] } }] },
        { OR: [{ targetUnits: { has: resident.unitId } }, { targetUnits: { equals: [] } }] },
      ];
    }
  }

  const [notices, total] = await Promise.all([
    prisma.notice.findMany({
      where,
      include: {
        author: { select: { firstName: true, lastName: true } },
      },
      orderBy: [{ isPinned: 'desc' }, { [sortBy || 'publishAt']: sortOrder }],
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.notice.count({ where }),
  ]);

  const noticeIds = notices.map(n => n.id);
  const readStatus = await prisma.notice.findMany({
    where: { id: { in: noticeIds } },
    select: { id: true, readBy: true },
  });

  const noticesWithRead = notices.map(n => ({
    ...n,
    isRead: readStatus.find(r => r.id === n.id)?.readBy.includes(req.user!.id) || false,
  }));

  res.json({ data: noticesWithRead, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
}));

router.get('/unread-count', asyncHandler(async (req: AuthRequest, res) => {
  const where: any = { 
    complexId: req.user!.complexId,
    publishAt: { lte: new Date() },
    OR: [{ expiresAt: null }, { expiresAt: { gte: new Date() } }],
    NOT: { readBy: { has: req.user!.id } },
  };

  if (req.user!.role === 'RESIDENT') {
    const resident = await prisma.resident.findUnique({ where: { userId: req.user!.id } });
    if (resident) {
      where.AND = [
        { OR: [{ targetRoles: { has: 'RESIDENT' } }, { targetRoles: { equals: [] } }] },
        { OR: [{ targetUnits: { has: resident.unitId } }, { targetUnits: { equals: [] } }] },
      ];
    }
  }

  const count = await prisma.notice.count({ where });
  res.json({ count });
}));

router.get('/:id', asyncHandler(async (req: AuthRequest, res) => {
  const notice = await prisma.notice.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
    include: { author: { select: { firstName: true, lastName: true } } },
  });

  if (!notice) throw new AppError(404, 'Aviso no encontrado');
  res.json({ ...notice, isRead: notice.readBy.includes(req.user!.id) });
}));

router.post('/:id/read', asyncHandler(async (req: AuthRequest, res) => {
  const notice = await prisma.notice.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!notice) throw new AppError(404, 'Aviso no encontrado');

  if (!notice.readBy.includes(req.user!.id)) {
    await prisma.notice.update({
      where: { id: notice.id },
      data: { readBy: { push: req.user!.id } },
    });
  }

  res.json({ message: 'Marcado como leído' });
}));

router.post('/', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = createNoticeSchema.parse(req.body);
  
  const notice = await prisma.notice.create({
    data: {
      ...data,
      complexId: req.user!.complexId!,
      authorId: req.user!.id,
      publishAt: data.publishAt ? new Date(data.publishAt) : new Date(),
      expiresAt: data.expiresAt ? new Date(data.expiresAt) : null,
    },
    include: { author: { select: { firstName: true, lastName: true } } },
  });

  res.status(201).json(notice);
}));

router.patch('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = updateNoticeSchema.parse(req.body);
  
  const notice = await prisma.notice.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!notice) throw new AppError(404, 'Aviso no encontrado');

  const updated = await prisma.notice.update({
    where: { id: notice.id },
    data: {
      ...data,
      publishAt: data.publishAt ? new Date(data.publishAt) : undefined,
      expiresAt: data.expiresAt ? new Date(data.expiresAt) : undefined,
    },
    include: { author: { select: { firstName: true, lastName: true } } },
  });

  res.json(updated);
}));

router.delete('/:id', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const notice = await prisma.notice.findFirst({
    where: { id: req.params.id, complexId: req.user!.complexId },
  });
  if (!notice) throw new AppError(404, 'Aviso no encontrado');

  await prisma.notice.delete({ where: { id: notice.id } });
  res.json({ message: 'Aviso eliminado' });
}));

export default router;