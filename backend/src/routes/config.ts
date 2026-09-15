import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';

const router = Router();

router.get('/complex', asyncHandler(async (req: AuthRequest, res) => {
  const complex = await prisma.residentialComplex.findFirst({
    where: { id: req.user!.complexId },
    include: { accessConfig: true, settings: true },
  });
  if (!complex) throw new AppError(404, 'Complejo no encontrado');
  res.json(complex);
}));

router.patch('/complex', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const { name, address, city, state, postalCode, phone, email, logoUrl } = req.body;
  
  const complex = await prisma.residentialComplex.update({
    where: { id: req.user!.complexId },
    data: { name, address, city, state, postalCode, phone, email, logoUrl },
  });

  res.json(complex);
}));

router.get('/access', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE', 'SECURITY'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const config = await prisma.accessConfig.findUnique({
    where: { complexId: req.user!.complexId },
  });
  res.json(config || {});
}));

router.patch('/access', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = req.body;
  
  const config = await prisma.accessConfig.upsert({
    where: { complexId: req.user!.complexId },
    create: { complexId: req.user!.complexId, ...data },
    update: data,
  });

  res.json(config);
}));

router.get('/settings', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const settings = await prisma.complexSettings.findUnique({
    where: { complexId: req.user!.complexId },
  });
  res.json(settings || {});
}));

router.patch('/settings', asyncHandler(async (req: AuthRequest, res) => {
  if (!['ADMIN', 'COMMITTEE'].includes(req.user!.role)) throw new AppError(403, 'Sin permisos');
  
  const data = req.body;
  
  const settings = await prisma.complexSettings.upsert({
    where: { complexId: req.user!.complexId },
    create: { complexId: req.user!.complexId, ...data },
    update: data,
  });

  res.json(settings);
}));

router.get('/stripe-config', asyncHandler(async (req: AuthRequest, res) => {
  const settings = await prisma.complexSettings.findUnique({
    where: { complexId: req.user!.complexId },
    select: { stripePublishableKey: true },
  });
  res.json({ publishableKey: settings?.stripePublishableKey || process.env.STRIPE_PUBLISHABLE_KEY || '' });
}));

export default router;