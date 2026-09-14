import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
  firstName: z.string().min(1, 'Nombre requerido'),
  lastName: z.string().min(1, 'Apellido requerido'),
  phone: z.string().optional(),
  complexId: z.string().optional(),
  unitNumber: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(1, 'Contraseña requerida'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token requerido'),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Email inválido'),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Token requerido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Contraseña actual requerida'),
  newPassword: z.string().min(8, 'Mínimo 8 caracteres'),
});

export const updateProfileSchema = z.object({
  firstName: z.string().min(1, 'Nombre requerido'),
  lastName: z.string().min(1, 'Apellido requerido'),
  phone: z.string().optional().nullable(),
});

export const createResidentSchema = z.object({
  email: z.string().email('Email inválido'),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  phone: z.string().optional(),
  unitId: z.string().uuid('Unit ID inválido'),
  rut: z.string().optional(),
  emergencyContactName: z.string().optional(),
  emergencyContactPhone: z.string().optional(),
  emergencyContactRelation: z.string().optional(),
  vehiclePlates: z.array(z.string()).optional(),
});

export const updateResidentSchema = z.object({
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  phone: z.string().optional(),
  rut: z.string().optional(),
  emergencyContactName: z.string().optional(),
  emergencyContactPhone: z.string().optional(),
  emergencyContactRelation: z.string().optional(),
  vehiclePlates: z.array(z.string()).optional(),
  status: z.enum(['ACTIVE', 'INACTIVE', 'PENDING', 'SUSPENDED']).optional(),
});

export const createVisitorSchema = z.object({
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  phone: z.string().optional(),
  email: z.string().email().optional().or(z.literal('')),
  documentType: z.string().optional(),
  documentNumber: z.string().optional(),
  vehiclePlate: z.string().optional(),
  isRecurring: z.boolean().optional(),
  recurringDays: z.array(z.number().int().min(0).max(6)).optional(),
  recurringStart: z.string().datetime().optional(),
  recurringEnd: z.string().datetime().optional(),
  entryCode: z.string().optional(),
  notes: z.string().optional(),
});

export const updateVisitorSchema = z.object({
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional().or(z.literal('')),
  documentType: z.string().optional(),
  documentNumber: z.string().optional(),
  vehiclePlate: z.string().optional(),
  isRecurring: z.boolean().optional(),
  recurringDays: z.array(z.number().int().min(0).max(6)).optional(),
  recurringStart: z.string().datetime().optional(),
  recurringEnd: z.string().datetime().optional(),
  notes: z.string().optional(),
});

export const createAccessLogSchema = z.object({
  unitId: z.string().uuid().optional(),
  visitorId: z.string().uuid().optional(),
  type: z.enum(['RESIDENT', 'VISITOR', 'SERVICE', 'DELIVERY', 'EMERGENCY']),
  status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'COMPLETED']).optional(),
  scheduledEntry: z.string().datetime().optional(),
  scheduledExit: z.string().datetime().optional(),
  entryMethod: z.string().optional(),
  notes: z.string().optional(),
});

export const approveAccessSchema = z.object({
  status: z.enum(['APPROVED', 'REJECTED']),
  notes: z.string().optional(),
});

export const createPaymentSchema = z.object({
  residentId: z.string().uuid(),
  type: z.enum(['MAINTENANCE', 'EXTRAORDINARY', 'AMENITY', 'PENALTY', 'OTHER']),
  amount: z.number().positive('Monto debe ser positivo'),
  description: z.string().min(1),
  dueDate: z.string().datetime(),
  periodStart: z.string().datetime().optional(),
  periodEnd: z.string().datetime().optional(),
  notes: z.string().optional(),
});

export const updatePaymentSchema = z.object({
  status: z.enum(['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED', 'OVERDUE']).optional(),
  paidAt: z.string().datetime().optional(),
  receiptUrl: z.string().url().optional(),
  notes: z.string().optional(),
});

export const createNoticeSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  type: z.enum(['GENERAL', 'URGENT', 'MAINTENANCE', 'EVENT', 'SECURITY', 'FINANCIAL']).optional(),
  priority: z.number().int().min(0).max(10).optional(),
  isPinned: z.boolean().optional(),
  publishAt: z.string().datetime().optional(),
  expiresAt: z.string().datetime().optional(),
  attachmentUrls: z.array(z.string().url()).optional(),
  targetRoles: z.array(z.enum(['ADMIN', 'RESIDENT', 'SECURITY', 'COMMITTEE'])).optional(),
  targetUnits: z.array(z.string()).optional(),
});

export const updateNoticeSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().min(1).optional(),
  type: z.enum(['GENERAL', 'URGENT', 'MAINTENANCE', 'EVENT', 'SECURITY', 'FINANCIAL']).optional(),
  priority: z.number().int().min(0).max(10).optional(),
  isPinned: z.boolean().optional(),
  publishAt: z.string().datetime().optional(),
  expiresAt: z.string().datetime().optional(),
  attachmentUrls: z.array(z.string().url()).optional(),
  targetRoles: z.array(z.enum(['ADMIN', 'RESIDENT', 'SECURITY', 'COMMITTEE'])).optional(),
  targetUnits: z.array(z.string()).optional(),
});

export const createBookingSchema = z.object({
  amenityId: z.string().uuid(),
  unitId: z.string().uuid(),
  startTime: z.string().datetime(),
  endTime: z.string().datetime(),
  guestsCount: z.number().int().positive().optional(),
  notes: z.string().optional(),
});

export const updateBookingSchema = z.object({
  status: z.enum(['PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'REJECTED']).optional(),
  rejectionReason: z.string().optional(),
});

export const createServiceRequestSchema = z.object({
  unitId: z.string().uuid(),
  title: z.string().min(1).max(200),
  description: z.string().min(1),
  category: z.string().min(1),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).optional(),
  images: z.array(z.string().url()).optional(),
  scheduledAt: z.string().datetime().optional(),
});

export const updateServiceRequestSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().min(1).optional(),
  category: z.string().optional(),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).optional(),
  status: z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED']).optional(),
  assigneeId: z.string().uuid().optional(),
  estimatedCost: z.number().optional(),
  actualCost: z.number().optional(),
  resolutionNotes: z.string().optional(),
  rating: z.number().int().min(1).max(5).optional(),
  feedback: z.string().optional(),
});

export const createAccountingEntrySchema = z.object({
  type: z.enum(['INCOME', 'EXPENSE']),
  category: z.string().min(1),
  subcategory: z.string().optional(),
  amount: z.number().positive(),
  description: z.string().min(1),
  reference: z.string().optional(),
  date: z.string().datetime(),
  attachments: z.array(z.string().url()).optional(),
});

export const createUnitSchema = z.object({
  number: z.string().min(1),
  block: z.string().optional(),
  floor: z.number().int().optional(),
  type: z.string().optional(),
  area: z.number().positive().optional(),
  bedrooms: z.number().int().positive().optional(),
  bathrooms: z.number().positive().optional(),
  hasParking: z.boolean().optional(),
  parkingSpots: z.number().int().min(0).optional(),
  monthlyFee: z.number().min(0).optional(),
  extraordinaryFee: z.number().min(0).optional(),
});

export const createAmenitySchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
  capacity: z.number().int().positive(),
  location: z.string().optional(),
  pricePerHour: z.number().min(0).optional(),
  requiresApproval: z.boolean().optional(),
  maxHoursPerBooking: z.number().int().positive().optional(),
  minHoursNotice: z.number().int().min(0).optional(),
  maxDaysAdvance: z.number().int().positive().optional(),
  images: z.array(z.string().url()).optional(),
  rules: z.string().optional(),
  schedules: z.array(z.object({
    dayOfWeek: z.number().int().min(0).max(6),
    openTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/),
    closeTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/),
    isClosed: z.boolean().optional(),
  })).optional(),
});

export const createComplexSchema = z.object({
  name: z.string().min(1).max(100),
  address: z.string().min(1),
  city: z.string().min(1),
  state: z.string().min(1),
  postalCode: z.string().min(1),
  country: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  timezone: z.string().optional(),
  currency: z.string().optional(),
});

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export const dateRangeSchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
});