import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../index.js';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
    complexId?: string;
  };
  token?: string;
}

export const authMiddleware = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Token de autorización requerido' });
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      id: string;
      email: string;
      role: string;
    };

    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: { id: true, email: true, role: true, isActive: true },
    });

    if (!user || !user.isActive) {
      res.status(401).json({ error: 'Usuario no válido o inactivo' });
      return;
    }

    let complexId: string | undefined;
    if (user.role === 'RESIDENT' || user.role === 'SECURITY' || user.role === 'COMMITTEE') {
      const resident = await prisma.resident.findUnique({
        where: { userId: user.id },
        select: { complexId: true, status: true },
      });
      if (resident && resident.status === 'ACTIVE') {
        complexId = resident.complexId;
      }
    } else if (user.role === 'ADMIN') {
      const complex = await prisma.residentialComplex.findFirst({
        where: { adminId: user.id, isActive: true },
        select: { id: true },
      });
      complexId = complex?.id;
    }

    req.user = { ...user, complexId };
    req.token = token;
    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      res.status(401).json({ error: 'Token expirado' });
      return;
    }
    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({ error: 'Token inválido' });
      return;
    }
    res.status(500).json({ error: 'Error de autenticación' });
  }
};

export const requireRole = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      res.status(403).json({ error: 'No tienes permisos para esta acción' });
      return;
    }
    next();
  };
};

export const requireComplexAccess = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user?.complexId) {
    res.status(403).json({ error: 'No tienes acceso a ningún complejo residencial' });
    return;
  }
  next();
};