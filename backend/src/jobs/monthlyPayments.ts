import cron from 'node-cron';
import { prisma } from '../index.js';

export function currentMonthRange(date = new Date()) {
  const start = new Date(date.getFullYear(), date.getMonth(), 1);
  const end = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);
  return { start, end };
}

export async function autoCreateMonthlyPayments(date = new Date()): Promise<number> {
  const dueDate = new Date(date.getFullYear(), date.getMonth(), 1);
  const year = dueDate.getFullYear();
  const month = dueDate.getMonth() + 1;
  const { start, end } = currentMonthRange(date);

  const complexes = await prisma.residentialComplex.findMany({
    where: { isActive: true },
    select: { id: true, adminId: true, settings: true },
  });

  let created = 0;

  for (const complex of complexes) {
    const fee = complex.settings?.maintenanceFee ?? 250;
    const currency = complex.settings?.defaultCurrency ?? 'MXN';
    const userId = complex.adminId;
    if (!userId) continue;

    const residents = await prisma.resident.findMany({
      where: { complexId: complex.id, status: 'ACTIVE' },
      include: { unit: true },
    });

    for (const resident of residents) {
      if (!resident.unit) continue;

      const reference = `PAY-${resident.id}-${year}-${month}`;
      const exists = await prisma.payment.findUnique({ where: { reference } });
      if (exists) continue;

      await prisma.payment.create({
        data: {
          complexId: complex.id,
          residentId: resident.id,
          userId,
          unitId: resident.unitId,
          type: 'MAINTENANCE',
          status: 'PENDING',
          amount: fee,
          currency,
          description: `Cuota de mantenimiento ${dueDate.toLocaleString('es-MX', { month: 'long', year: 'numeric' })}`,
          reference,
          dueDate,
          periodStart: start,
          periodEnd: end,
        },
      });
      created++;
    }
  }

  return created;
}

export function startMonthlyPaymentCron() {
  if (process.env.DISABLE_PAYMENT_CRON === 'true') return;
  cron.schedule('30 5 1 * *', async () => {
    try {
      const created = await autoCreateMonthlyPayments();
      console.log(`[cron][monthlyPayments] cuotas creadas automáticamente: ${created}`);
    } catch (error) {
      console.error('[cron][monthlyPayments] error:', error);
    }
  });
  console.log('⏰ Cron de cuotas mensuales activado (día 1, 05:30)');
}