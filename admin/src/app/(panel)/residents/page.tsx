import { api } from '@/lib/api';
import { Paginated, ResidentListItem, UnitListItem } from '@/lib/types';
import { Card, PageHeader, Pagination, Badge, EmptyState, Th, Td, inputCls, btnSecondary } from '@/components/ui';
import { RESIDENT_STATUS, fmtDate } from '@/lib/format';
import Link from 'next/link';
import ResidentCreateDialog from '@/components/ResidentCreateDialog';

export default async function ResidentsPage({ searchParams }: PageProps<'/residents'>) {
  const sp = await searchParams;
  const page = Number(sp.page ?? 1);
  const status = typeof sp.status === 'string' ? sp.status : '';
  const search = typeof sp.search === 'string' ? sp.search : '';

  const qs = new URLSearchParams({ page: String(page), limit: '15' });
  if (status) qs.set('status', status);
  if (search) qs.set('search', search);

  const [list, units] = await Promise.all([
    api<Paginated<ResidentListItem>>(`/residents?${qs}`),
    api<Paginated<UnitListItem>>('/units?limit=100'),
  ]);

  return (
    <div>
      <PageHeader
        title="Residentes"
        description={`${list.pagination.total} residentes`}
        action={<ResidentCreateDialog units={units.data} />}
      />

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-slate-100 px-5 py-4">
          <form className="flex flex-1 items-center gap-2" method="GET">
            <input name="search" defaultValue={search} placeholder="Buscar por nombre, email o unidad…" className={inputCls} />
            <select name="status" defaultValue={status} className={`${inputCls} max-w-[150px]`}>
              <option value="">Todos los estados</option>
              {Object.entries(RESIDENT_STATUS).map(([k, v]) => (
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
          <EmptyState message="No hay residentes que coincidan" />
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Residente</Th>
                <Th>Email</Th>
                <Th>Unidad</Th>
                <Th>Estado</Th>
                <Th>Ingreso</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {list.data.map((r) => (
                <tr key={r.id} className="hover:bg-slate-50/60">
                  <Td className="font-medium text-slate-900">
                    <Link href={`/residents/${r.id}`} className="hover:underline">
                      {r.user.firstName} {r.user.lastName}
                    </Link>
                  </Td>
                  <Td>{r.user.email}</Td>
                  <Td>
                    {r.unit.number}
                    {r.unit.block ? ` · B${r.unit.block}` : ''}
                  </Td>
                  <Td>
                    <Badge value={r.status} label={RESIDENT_STATUS[r.status]} />
                  </Td>
                  <Td>{fmtDate(r.joinedAt)}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination
          page={page}
          totalPages={list.pagination.totalPages}
          total={list.pagination.total}
          basePath="/residents"
          params={{ status, search }}
        />
      </Card>
    </div>
  );
}