import { api } from '@/lib/api';
import { Paginated, PaymentItem, PaymentStats, ResidentListItem } from '@/lib/types';
import { Card, PageHeader, Pagination, Badge, StatCard, EmptyState, Th, Td, inputCls, btnSecondary } from '@/components/ui';
import { mxn, fmtDate, PAYMENT_STATUS, PAYMENT_TYPE } from '@/lib/format';
import BulkPaymentDialog from '@/components/BulkPaymentDialog';
import { PaymentStatusAction } from '@/components/PaymentStatusAction';

export default async function PaymentsPage({ searchParams }: PageProps<'/payments'>) {
  const sp = await searchParams;
  const page = Number(sp.page ?? 1);
  const status = typeof sp.status === 'string' ? sp.status : '';
  const type = typeof sp.type === 'string' ? sp.type : '';

  const qs = new URLSearchParams({ page: String(page), limit: '15' });
  if (status) qs.set('status', status);
  if (type) qs.set('type', type);

  const [list, stats, residents] = await Promise.all([
    api<Paginated<PaymentItem>>(`/payments?${qs}`),
    api<PaymentStats>('/payments/stats/summary'),
    api<Paginated<ResidentListItem>>('/residents?status=ACTIVE&limit=100'),
  ]);

  const activeResidents = residents.data.map((r) => ({
    id: r.id,
    label: `${r.user.firstName} ${r.user.lastName} · ${r.unit.number}`,
  }));

  return (
    <div className="space-y-6">
      <PageHeader
        title="Pagos"
        description="Cuotas de mantenimiento y cobros especiales"
        action={<BulkPaymentDialog residents={activeResidents} />}
      />

      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Monto total" value={mxn(stats.totalAmount)} />
        <StatCard
          label="Pendientes / vencidos"
          value={`${stats.pending} / ${stats.overdue}`}
          accent={stats.overdue > 0 ? 'text-orange-600' : 'text-slate-900'}
        />
        <StatCard label="Completados" value={stats.completed} />
      </div>

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-slate-100 px-5 py-4">
          <form className="flex flex-wrap items-center gap-2" method="GET">
            <select name="status" defaultValue={status} className={`${inputCls} max-w-[150px]`}>
              <option value="">Todos los estados</option>
              {Object.entries(PAYMENT_STATUS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
            <select name="type" defaultValue={type} className={`${inputCls} max-w-[170px]`}>
              <option value="">Todos los tipos</option>
              {Object.entries(PAYMENT_TYPE).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
            <button type="submit" className={btnSecondary}>
              Filtrar
            </button>
          </form>
        </div>

        {list.data.length === 0 ? (
          <EmptyState message="No hay pagos que coincidan" />
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Residente</Th>
                <Th>Descripción</Th>
                <Th>Vence</Th>
                <Th>Monto</Th>
                <Th>Estado</Th>
                <Th>Actualizar</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {list.data.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50/60">
                  <Td className="font-medium text-slate-900">
                    {p.resident.user.firstName} {p.resident.user.lastName}
                    <span className="block text-xs text-slate-400">
                      Unidad {p.unit.number}
                    </span>
                  </Td>
                  <Td>
                    {p.description}
                    <span className="block text-xs text-slate-400">{PAYMENT_TYPE[p.type]}</span>
                  </Td>
                  <Td>{fmtDate(p.dueDate)}</Td>
                  <Td className="font-medium">{mxn(p.amount)}</Td>
                  <Td>
                    <Badge value={p.status} label={PAYMENT_STATUS[p.status]} />
                  </Td>
                  <Td>
                    <PaymentStatusAction id={p.id} status={p.status} />
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination
          page={page}
          totalPages={list.pagination.totalPages}
          total={list.pagination.total}
          basePath="/payments"
          params={{ status, type }}
        />
      </Card>
    </div>
  );
}