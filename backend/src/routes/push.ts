import { Router } from 'express';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { AuthRequest } from '../middleware/auth.js';
import { pushTokenSchema } from '../validators/schemas.js';

const router = Router();

router.post('/tokens', asyncHandler(async (req: AuthRequest, res) => {
  if (!req.user!.complexId) throw new AppError(400, 'Sin complejo asociado');

  const data = pushTokenSchema.parse(req.body);
  const platform = data.platform || 'web';

  const token = await prisma.pushToken.upsert({
    where: { userId_token: { userId: req.user!.id, token: data.token } },
    create: {
      userId: req.user!.id,
      complexId: req.user!.complexId!,
      token: data.token,
      platform,
      deviceName: data.deviceName,
    },
    update: {
      platform,
      deviceName: data.deviceName || undefined,
      complexId: req.user!.complexId!,
    },
  });

  res.status(201).json(token);
}));

router.get('/tokens', asyncHandler(async (req: AuthRequest, res) => {
  const tokens = await prisma.pushToken.findMany({
    where: { userId: req.user!.id },
    select: { id: true, token: true, platform: true, deviceName: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json(tokens);
}));

router.delete('/tokens', asyncHandler(async (req: AuthRequest, res) => {
  const tokenQuery = typeof req.query.token === 'string' ? req.query.token : (req.body?.token as string | undefined);
  if (!tokenQuery) throw new AppError(400, 'Token requerido');

  await prisma.pushToken.deleteMany({ where: { userId: req.user!.id, token: tokenQuery } });
  res.json({ message: 'Token eliminado' });
}));

export default router;