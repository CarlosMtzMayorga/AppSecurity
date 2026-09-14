import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import fs from 'node:fs';
import path from 'node:path';
import multer from 'multer';
import { prisma } from '../index.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import { authMiddleware, AuthRequest } from '../middleware/auth.js';
import {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  changePasswordSchema,
  updateProfileSchema,
} from '../validators/schemas.js';

const router = Router();

const UPLOAD_DIR = path.resolve(process.cwd(), process.env.UPLOAD_DIR || './uploads');
const AVATAR_DIR = path.join(UPLOAD_DIR, 'avatars');

const avatarStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    fs.mkdirSync(AVATAR_DIR, { recursive: true });
    cb(null, AVATAR_DIR);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.png';
    cb(null, `avatar-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10) },
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new AppError(400, 'Solo se permiten imágenes (jpeg, png, webp, gif)'));
  },
});

const generateTokens = (user: { id: string; email: string; role: string }) => {
  const accessToken = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
  
  const refreshToken = jwt.sign(
    { id: user.id, type: 'refresh' },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
  );

  return { accessToken, refreshToken };
};

const buildUserPayload = async (user: {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  avatarUrl: string | null;
  role: string;
  createdAt: Date;
  lastLoginAt: Date | null;
}) => {
  let complexId: string | undefined;
  let residentStatus: string | undefined;
  let unit: { id: string; number: string; block: string | null } | undefined;

  if (user.role === 'RESIDENT' || user.role === 'SECURITY' || user.role === 'COMMITTEE') {
    const resident = await prisma.resident.findUnique({
      where: { userId: user.id },
      select: { complexId: true, status: true, unit: { select: { id: true, number: true, block: true } } },
    });
    if (resident) {
      complexId = resident.complexId;
      residentStatus = resident.status;
      unit = resident.unit;
    }
  } else if (user.role === 'ADMIN') {
    const complex = await prisma.residentialComplex.findFirst({
      where: { adminId: user.id, isActive: true },
      select: { id: true },
    });
    complexId = complex?.id;
  }

  return {
    id: user.id,
    email: user.email,
    firstName: user.firstName,
    lastName: user.lastName,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    role: user.role,
    createdAt: user.createdAt,
    lastLoginAt: user.lastLoginAt,
    complexId,
    residentStatus,
    unit,
  };
};

router.post('/register', asyncHandler(async (req, res) => {
  const data = registerSchema.parse(req.body);
  
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email },
  });

  if (existingUser) {
    throw new AppError(409, 'El email ya está registrado');
  }

  const passwordHash = await bcrypt.hash(data.password, 12);

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

  if (data.complexId && data.unitNumber) {
    const unit = await prisma.unit.findFirst({
      where: { complexId: data.complexId, number: data.unitNumber },
    });
    
    if (unit) {
      await prisma.resident.create({
        data: {
          userId: user.id,
          complexId: data.complexId,
          unitId: unit.id,
          status: 'PENDING',
        },
      });
    }
  }

  const tokens = generateTokens({ id: user.id, email: user.email, role: user.role });
  
  await prisma.authToken.create({
    data: {
      token: tokens.refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });

  res.status(201).json({
    message: 'Usuario registrado exitosamente',
    user: await buildUserPayload(user),
    ...tokens,
  });
}));

router.post('/login', asyncHandler(async (req, res) => {
  const data = loginSchema.parse(req.body);
  
  const user = await prisma.user.findUnique({
    where: { email: data.email },
  });

  if (!user || !user.isActive) {
    throw new AppError(401, 'Credenciales inválidas');
  }

  const isValid = await bcrypt.compare(data.password, user.passwordHash);
  if (!isValid) {
    throw new AppError(401, 'Credenciales inválidas');
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  const tokens = generateTokens({ id: user.id, email: user.email, role: user.role });
  
  await prisma.authToken.create({
    data: {
      token: tokens.refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });

  res.json({
    message: 'Login exitoso',
    user: await buildUserPayload(user),
    ...tokens,
  });
}));

router.post('/refresh', asyncHandler(async (req, res) => {
  const data = refreshTokenSchema.parse(req.body);
  
  const decoded = jwt.verify(data.refreshToken, process.env.JWT_REFRESH_SECRET!) as {
    id: string;
    type: string;
  };

  if (decoded.type !== 'refresh') {
    throw new AppError(401, 'Token inválido');
  }

  const storedToken = await prisma.authToken.findUnique({
    where: { token: data.refreshToken },
  });

  if (!storedToken || storedToken.expiresAt < new Date()) {
    throw new AppError(401, 'Token expirado o revocado');
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.id },
    select: { id: true, email: true, role: true, isActive: true },
  });

  if (!user || !user.isActive) {
    throw new AppError(401, 'Usuario no válido');
  }

  await prisma.authToken.delete({ where: { token: data.refreshToken } });

  const tokens = generateTokens({ id: user.id, email: user.email, role: user.role });
  
  await prisma.authToken.create({
    data: {
      token: tokens.refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });

  res.json(tokens);
}));

router.post('/logout', asyncHandler(async (req: AuthRequest, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    await prisma.authToken.deleteMany({ where: { token } });
  }
  res.json({ message: 'Sesión cerrada' });
}));

router.post('/change-password', authMiddleware, asyncHandler(async (req: AuthRequest, res) => {
  const data = changePasswordSchema.parse(req.body);
  
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
  });

  if (!user) {
    throw new AppError(404, 'Usuario no encontrado');
  }

  const isValid = await bcrypt.compare(data.currentPassword, user.passwordHash);
  if (!isValid) {
    throw new AppError(401, 'Contraseña actual incorrecta');
  }

  const newPasswordHash = await bcrypt.hash(data.newPassword, 12);
  
  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash: newPasswordHash },
  });

  await prisma.authToken.deleteMany({ where: { userId: user.id } });

  res.json({ message: 'Contraseña actualizada. Inicia sesión nuevamente.' });
}));

router.post('/avatar', authMiddleware, avatarUpload.single('avatar'), asyncHandler(async (req: AuthRequest, res) => {
  if (!req.file) throw new AppError(400, 'Se requiere un archivo de imagen');

  const avatarPath = `/uploads/avatars/${req.file.filename}`;

  const previous = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: { avatarUrl: true },
  });

  const user = await prisma.user.update({
    where: { id: req.user!.id },
    data: { avatarUrl: avatarPath },
    select: {
      id: true,
      email: true,
      firstName: true,
      lastName: true,
      phone: true,
      avatarUrl: true,
      role: true,
      createdAt: true,
      lastLoginAt: true,
    },
  });

  if (previous?.avatarUrl?.startsWith('/uploads/avatars/')) {
    const oldPath = path.join(UPLOAD_DIR, 'avatars', path.basename(previous.avatarUrl));
    fs.unlink(oldPath, () => {});
  }

  res.json({ user: await buildUserPayload(user) });
}));

router.get('/me', authMiddleware, asyncHandler(async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: {
      id: true,
      email: true,
      firstName: true,
      lastName: true,
      phone: true,
      avatarUrl: true,
      role: true,
      createdAt: true,
      lastLoginAt: true,
    },
  });

  if (!user) {
    throw new AppError(404, 'Usuario no encontrado');
  }

  res.json({ user: await buildUserPayload(user) });
}));

router.patch('/me', authMiddleware, asyncHandler(async (req: AuthRequest, res) => {
  const data = updateProfileSchema.parse(req.body);

  const user = await prisma.user.update({
    where: { id: req.user!.id },
    data: {
      firstName: data.firstName,
      lastName: data.lastName,
      phone: data.phone,
    },
    select: {
      id: true,
      email: true,
      firstName: true,
      lastName: true,
      phone: true,
      avatarUrl: true,
      role: true,
      createdAt: true,
      lastLoginAt: true,
    },
  });

  res.json({ user: await buildUserPayload(user) });
}));

export default router;