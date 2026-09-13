import { api } from '@/lib/api';
import { Paginated, AccessLogItem } from '@/lib/types';
import { Card, PageHeader, Pagination, Badge, StatCard, EmptyState, Th, Td, inputCls, btnSecondary, CardHeader } from '@/components/ui';
import { fmtDateTime, ACCESS_TYPE, ACCESS_STATUS } from '@/lib/format';
import { AccessActions } from '@/components/AccessActions';

export default async function AccessPage({ searchParams }: PageProps<'/access'>) {
  const sp = await searchParams;
  const page = Number(sp.page ?? 1);
  const status = typeof sp.status === 'string' ? sp.status : '';
  const type = typeof sp.type === 'string' ? sp.type : '';

  const qs = new URLSearchParams({ page: String(page), limit: '15' });
  if (status) qs.set('status', status);
  if (type) qs.set('type', type);

  const [list, active, stats] = await Promise.all([
    api<Paginated<AccessLogItem>>(`/access?${qs}`),
    api<AccessLogItem[]>('/access/active'),
    api<{ total: number; residents: number; visitors: number; services: number; deliveries: number; active: number }>(
      '/access/stats/summary',
    ),
  ]);

  return (
    <div className="space-y-6">
      <PageHeader title="Accesos" description="Bitácora y control de acceso" />

      <div className="grid grid-cols-4 gap-4">
        <StatCard label="Total registros" value={stats.total} />
        <StatCard label="Residentes" value={stats.residents} />
        <StatCard label="Visitantes" value={stats.visitors} />
        <StatCard label="Dentro del complejo" value={stats.active} accent="text-emerald-600" />
      </div>

      {active.length > 0 && (
        <Card>
          <CardHeader title="Personas dentro del complejo" subtitle={`${active.length} activas ahora`} />
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Persona</Th>
                <Th>Tipo</Th>
                <Th>Unidad</Th>
                <Th>Entrada</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {active.map((a) => (
                <tr key={a.id}>
                  <Td className="font-medium">
                    {a.resident?.user
                      ? `${a.resident.user.firstName} ${a.resident.user.lastName}`
                      : a.visitor
                        ? `${a.visitor.firstName} ${a.visitor.lastName}`
                        : '—'}
                  </Td>
                  <Td>{ACCESS_TYPE[a.type] ?? a.type}</Td>
                  <Td>{a.unit?.number ?? '—'}</Td>
                  <Td>{fmtDateTime(a.entryTime)}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-slate-100 px-5 py-4">
          <form className="flex flex-wrap items-center gap-2" method="GET">
            <select name="status" defaultValue={status} className={`${inputCls} max-w-[150px]`}>
              <option value="">Todos los estados</option>
              {Object.entries(ACCESS_STATUS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
            <select name="type" defaultValue={type} className={`${inputCls} max-w-[150px]`}>
              <option value="">Todos los tipos</option>
              {Object.entries(ACCESS_TYPE).map(([k, v]) => (
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
          <EmptyState message="No hay registros de acceso" />
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Persona</Th>
                <Th>Tipo</Th>
                <Th>Unidad</Th>
                <Th>Entrada</Th>
                <Th>Salida</Th>
                <Th>Estado</Th>
                <Th className="text-right">Acción</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {list.data.map((a) => (
                <tr key={a.id} className="hover:bg-slate-50/60">
                  <Td className="font-medium text-slate-900">
                    {a.resident?.user
                      ? `${a.resident.user.firstName} ${a.resident.user.lastName}`
                      : a.visitor
                        ? `${a.visitor.firstName} ${a.visitor.lastName}`
                        : a.plateRecognized ?? '—'}
                  </Td>
                  <Td>{ACCESS_TYPE[a.type] ?? a.type}</Td>
                  <Td>{a.unit?.number ?? '—'}</Td>
                  <Td>{fmtDateTime(a.entryTime)}</Td>
                  <Td>{fmtDateTime(a.exitTime)}</Td>
                  <Td>
                    <Badge value={a.status} label={ACCESS_STATUS[a.status]} />
                  </Td>
                  <Td className="text-right">
                    <AccessActions id={a.id} status={a.status} />
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
          basePath="/access"
          params={{ status, type }}
        />
      </Card>
    </div>
  );
}