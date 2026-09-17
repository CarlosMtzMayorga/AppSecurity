import { prisma } from '../index.js';
import { currentMonthRange } from '../jobs/monthlyPayments.js';

export const VEHICLE_GRACE_DAY = 7;
export const VEHICLE_BLOCK_MESSAGE = 'Cuota del mes pendiente. Acceso vehicular suspendido.';

export function isPastVehicleGraceDay(date = new Date()): boolean {
  return date.getDate() >= VEHICLE_GRACE_DAY;
}

export async function getVehicleBlockStatus(
  complexId: string,
  unitId: string,
): Promise<{ blocked: boolean; message: string | null }> {
  if (!isPastVehicleGraceDay()) {
    return { blocked: false, message: null };
  }

  const { start, end } = currentMonthRange();

  const unpaid = await prisma.payment.findFirst({
    where: {
      complexId,
      unitId,
      status: { in: ['PENDING', 'OVERDUE'] },
      dueDate: { gte: start, lte: end },
    },
    select: { id: true },
  });

  if (unpaid) {
    return { blocked: true, message: VEHICLE_BLOCK_MESSAGE };
  }

  return { blocked: false, message: null };
}