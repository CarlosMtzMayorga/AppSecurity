import { api } from '@/lib/api';
import { Paginated, AccountingEntry, AccountingSummary, AccountingMonthly } from '@/lib/types';
import { Card, PageHeader, Pagination, StatCard, EmptyState, Th, Td, inputCls, btnSecondary, CardHeader } from '@/components/ui';
import { mxn, fmtDate } from '@/lib/format';
import AccountingEntryDialog from '@/components/AccountingEntryDialog';
import { AccountingEntryActions } from '@/components/AccountingEntryActions';

export default async function AccountingPage({ searchParams }: PageProps<'/accounting'>) {
  const sp = await searchParams;
  const page = Number(sp.page ?? 1);
  const type = typeof sp.type === 'string' ? sp.type : '';

  const qs = new URLSearchParams({ page: String(page), limit: '15' });
  if (type) qs.set('type', type);

  const [summary, monthly, list] = await Promise.all([
    api<AccountingSummary>('/accounting/summary'),
    api<AccountingMonthly[]>('/accounting/monthly'),
    api<Paginated<AccountingEntry>>(`/accounting?${qs}`),
  ]);

  const maxMonth = Math.max(...monthly.map((m) => Math.max(m.income, m.expenses)), 1);
  const thisYear = new Date().getFullYear();

  return (
    <div className="space-y-6">
      <PageHeader title="Contabilidad" description={`Ejercicio ${thisYear}`} action={<AccountingEntryDialog />} />

      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Ingresos" value={mxn(summary.income)} accent="text-emerald-600" />
        <StatCard label="Egresos" value={mxn(summary.expenses)} accent="text-red-600" />
        <StatCard
          label="Balance"
          value={mxn(summary.balance)}
          accent={summary.balance >= 0 ? 'text-emerald-600' : 'text-red-600'}
        />
      </div>

      <Card>
        <CardHeader title="Balance mensual" subtitle="Ingresos vs egresos" />
        <div className="flex items-end gap-3 p-5" style={{ height: 160 }}>
          {monthly.map((m) => (
            <div key={m.month} className="flex flex-1 flex-col items-center gap-1">
              <div className="flex w-full flex-col justify-end gap-0.5" style={{ height: 110 }}>
                <div className="w-full rounded-t bg-emerald-500" style={{ height: `${(m.income / maxMonth) * 100}%` }} />
                <div className="w-full rounded-b bg-red-400" style={{ height: `${(m.expenses / maxMonth) * 100}%` }} />
              </div>
              <span className="text-[10px] text-slate-400">
                {new Date(0, m.month - 1).toLocaleDateString('es-MX', { month: 'short' })}
              </span>
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-slate-100 px-5 py-4">
          <form className="flex items-center gap-2" method="GET">
            <select name="type" defaultValue={type} className={`${inputCls} max-w-[150px]`}>
              <option value="">Todos</option>
              <option value="INCOME">Ingresos</option>
              <option value="EXPENSE">Egresos</option>
            </select>
            <button type="submit" className={btnSecondary}>
              Filtrar
            </button>
          </form>
        </div>

        {list.data.length === 0 ? (
          <EmptyState message="Sin partidas contables" />
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Fecha</Th>
                <Th>Categoría</Th>
                <Th>Descripción</Th>
                <Th>Tipo</Th>
                <Th>Monto</Th>
                <Th className="text-right">Acción</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {list.data.map((e) => (
                <tr key={e.id} className="hover:bg-slate-50/60">
                  <Td>{fmtDate(e.date)}</Td>
                  <Td className="font-medium text-slate-900">
                    {e.category}
                    {e.subcategory && <span className="block text-xs text-slate-400">{e.subcategory}</span>}
                  </Td>
                  <Td>{e.description}</Td>
                  <Td>{e.type === 'INCOME' ? 'Ingreso' : 'Egreso'}</Td>
                  <Td className={`font-medium ${e.type === 'INCOME' ? 'text-emerald-600' : 'text-red-600'}`}>
                    {e.type === 'INCOME' ? '+' : '−'} {mxn(e.amount)}
                  </Td>
                  <Td className="text-right">
                    <AccountingEntryActions id={e.id} />
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
          basePath="/accounting"
          params={{ type }}
        />
      </Card>
    </div>
  );
}