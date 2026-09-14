export type Role = 'ADMIN' | 'RESIDENT' | 'SECURITY' | 'COMMITTEE';

export interface Paginated<T> {
  data: T[];
  pagination: { page: number; limit: number; total: number; totalPages: number };
}

export interface SessionUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  avatarUrl: string | null;
  role: Role;
  createdAt: string;
  lastLoginAt: string | null;
  complexId?: string;
  residentStatus?: string;
  unit?: { id: string; number: string; block?: string | null } | null;
}

export interface UserRef {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  avatarUrl: string | null;
  lastLoginAt: string | null;
  createdAt?: string;
}

export interface UnitRef {
  id: string;
  number: string;
  block: string | null;
  floor: number | null;
  type: string;
}

export type ResidentStatus = 'ACTIVE' | 'INACTIVE' | 'PENDING' | 'SUSPENDED';

export interface ResidentListItem {
  id: string;
  status: ResidentStatus;
  rut: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
  vehiclePlates: string[];
  accessCards: string[];
  faceIdEnabled: boolean;
  qrCode: string | null;
  joinedAt: string;
  approvedAt: string | null;
  user: UserRef;
  unit: UnitRef;
}

export interface ResidentDetail extends ResidentListItem {
  complexId: string;
  unitId: string;
  userId: string;
  emergencyContactRelation: string | null;
  approvedBy: string | null;
  createdAt: string;
  updatedAt: string;
  unit: {
    id: string;
    number: string;
    block: string | null;
    floor: number | null;
    type: string;
    area: number | null;
    monthlyFee: number;
  };
  user: UserRef & { createdAt: string };
  payments: ResidentPayment[];
  accesses: ResidentAccess[];
  visitors: ResidentVisitor[];
}

export interface ResidentPayment {
  id: string;
  type: PaymentType;
  status: PaymentStatus;
  amount: number;
  description: string;
  dueDate: string;
}

export interface ResidentAccess {
  id: string;
  type: AccessType;
  status: AccessStatus;
  entryTime: string | null;
  createdAt: string;
  entryMethod: string | null;
}

export interface ResidentVisitor {
  id: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  vehiclePlate: string | null;
  isRecurring: boolean;
}

export interface UnitListItem {
  id: string;
  complexId: string;
  number: string;
  block: string | null;
  floor: number | null;
  type: string;
  area: number | null;
  bedrooms: number | null;
  bathrooms: number | null;
  hasParking: boolean;
  parkingSpots: number;
  monthlyFee: number;
  extraordinaryFee: number;
  isActive: boolean;
  resident: { id: string; user: { firstName: string; lastName: string }; status: string } | null;
  hasResident: boolean;
  residentName: string | null;
  residentStatus: string | null;
}

export type PaymentStatus = 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED' | 'OVERDUE';
export type PaymentType = 'MAINTENANCE' | 'EXTRAORDINARY' | 'AMENITY' | 'PENALTY' | 'OTHER';

export interface PaymentItem {
  id: string;
  type: PaymentType;
  status: PaymentStatus;
  amount: number;
  currency: string;
  description: string;
  reference: string | null;
  dueDate: string;
  periodStart: string | null;
  periodEnd: string | null;
  paidAt: string | null;
  notes: string | null;
  createdAt: string;
  resident: { user: { firstName: string; lastName: string }; unit: { number: string } };
  unit: { number: string; block: string | null };
}

export interface PaymentStats {
  totalAmount: number;
  pending: number;
  completed: number;
  failed: number;
  overdue: number;
  byType: Array<{ type: PaymentType; amount: number; count: number }>;
}

export type NoticeType = 'GENERAL' | 'URGENT' | 'MAINTENANCE' | 'EVENT' | 'SECURITY' | 'FINANCIAL';

export interface NoticeItem {
  id: string;
  title: string;
  content: string;
  type: NoticeType;
  priority: number;
  isPinned: boolean;
  publishAt: string;
  expiresAt: string | null;
  attachmentUrls: string[];
  targetRoles: string[];
  targetUnits: string[];
  readBy: string[];
  createdAt: string;
  author: { firstName: string; lastName: string };
  isRead: boolean;
}

export type AccessType = 'RESIDENT' | 'VISITOR' | 'SERVICE' | 'DELIVERY' | 'EMERGENCY';
export type AccessStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED' | 'COMPLETED';

export interface AccessLogItem {
  id: string;
  type: AccessType;
  status: AccessStatus;
  entryTime: string | null;
  exitTime: string | null;
  scheduledEntry: string | null;
  entryMethod: string | null;
  exitMethod: string | null;
  plateRecognized: string | null;
  faceRecognized: boolean;
  qrCodeUsed: string | null;
  tokenUsed: string | null;
  notes: string | null;
  createdAt: string;
  unit: { number: string; block: string | null } | null;
  resident: { user: { firstName: string; lastName: string } } | null;
  visitor: { firstName: string; lastName: string } | null;
  securityUser: { firstName: string; lastName: string } | null;
}

export interface DashboardOverview {
  residents: { total: number; active: number; occupancyRate: number };
  units: { total: number; occupied: number; vacant: number };
  payments: { total: number; pending: number; overdue: number };
  finances: { income: number; expenses: number; balance: number };
  services: { open: number };
  security: { activeAccesses: number };
  communications: { notices: number };
}

export interface PaymentTrend {
  month: string;
  collected: number;
  pending: number;
  overdue: number;
}

export interface AccessTrend {
  date: string;
  total: number;
  residents: number;
  visitors: number;
  services: number;
}

export interface AccountingEntry {
  id: string;
  type: 'INCOME' | 'EXPENSE';
  category: string;
  subcategory: string | null;
  amount: number;
  currency: string;
  description: string;
  reference: string | null;
  date: string;
  attachments: string[];
  createdBy: string;
  createdAt: string;
}

export interface AccountingSummary {
  income: number;
  expenses: number;
  balance: number;
  byCategory: Array<{ type: 'INCOME' | 'EXPENSE'; category: string; amount: number; count: number }>;
}

export interface AccountingMonthly {
  month: number;
  income: number;
  expenses: number;
}

export interface ServiceRequest {
  id: string;
  title: string;
  description: string;
  category: string;
  priority: string;
  status: string;
  createdAt: string;
  scheduledAt: string | null;
  unit: { number: string } | null;
  user: { firstName: string; lastName: string } | null;
}

export interface ResidentialComplex {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  phone: string | null;
  email: string | null;
  logoUrl: string | null;
  timezone: string;
  currency: string;
  isActive: boolean;
  adminId: string;
  createdAt: string;
  accessConfig: AccessConfig[];
  settings: ComplexSettings | null;
}

export interface AccessConfig {
  id: string;
  complexId: string;
  gateIp: string | null;
  gatePort: number | null;
  gateUsername: string | null;
  gatePassword: string | null;
  cameraUrl: string | null;
  cameraUsername: string | null;
  cameraPassword: string | null;
  autoOpenEnabled: boolean;
  autoOpenHoursStart: string | null;
  autoOpenHoursEnd: string | null;
  maxVisitorHours: number;
  requirePhoto: boolean;
  requireDocument: boolean;
  allowRecurring: boolean;
  faceRecognition: boolean;
  plateRecognition: boolean;
}

export interface ComplexSettings {
  id: string;
  complexId: string;
  maintenanceFee: number;
  extraordinaryFee: number;
  lateFeePercent: number;
  lateFeeGraceDays: number;
  allowPartialPayment: boolean;
  requirePaymentApproval: boolean;
  notifyPaymentDueDays: number[];
  notifyNewVisitor: boolean;
  notifyAccessEntry: boolean;
  notifyServiceUpdates: boolean;
  defaultCurrency: string;
  stripePublishableKey: string | null;
  stripeSecretKey: string | null;
  stripeWebhookSecret: string | null;
}