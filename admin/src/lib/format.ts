export const mxn = (n: number | null | undefined) =>
  new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n ?? 0);

export const fmtDate = (iso: string | null | undefined) =>
  iso ? new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(iso)) : '—';

export const fmtDateTime = (iso: string | null | undefined) =>
  iso
    ? new Intl.DateTimeFormat('es-MX', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      }).format(new Date(iso))
    : '—';

export const RESIDENT_STATUS: Record<string, string> = {
  ACTIVE: 'Activo',
  INACTIVE: 'Inactivo',
  PENDING: 'Pendiente',
  SUSPENDED: 'Suspendido',
};

export const PAYMENT_STATUS: Record<string, string> = {
  PENDING: 'Pendiente',
  COMPLETED: 'Completado',
  FAILED: 'Fallido',
  REFUNDED: 'Reembolsado',
  OVERDUE: 'Vencido',
};

export const PAYMENT_TYPE: Record<string, string> = {
  MAINTENANCE: 'Cuota de mantenimiento',
  EXTRAORDINARY: 'Extraordinaria',
  AMENITY: 'Amenidad',
  PENALTY: 'Multa',
  OTHER: 'Otro',
};

export const NOTICE_TYPE: Record<string, string> = {
  GENERAL: 'General',
  URGENT: 'Urgente',
  MAINTENANCE: 'Mantenimiento',
  EVENT: 'Evento',
  SECURITY: 'Seguridad',
  FINANCIAL: 'Financiero',
};

export const ACCESS_TYPE: Record<string, string> = {
  RESIDENT: 'Residente',
  VISITOR: 'Visitante',
  SERVICE: 'Servicio',
  DELIVERY: 'Entrega',
  EMERGENCY: 'Emergencia',
};

export const ACCESS_STATUS: Record<string, string> = {
  PENDING: 'Pendiente',
  APPROVED: 'Aprobado',
  REJECTED: 'Rechazado',
  EXPIRED: 'Expirado',
  COMPLETED: 'Completado',
};

export const ROLES: Record<string, string> = {
  ADMIN: 'Administrador',
  RESIDENT: 'Residente',
  SECURITY: 'Seguridad',
  COMMITTEE: 'Comité',
};