import { api } from '@/lib/api';
import { Paginated, NoticeItem } from '@/lib/types';
import { Card, PageHeader, Pagination, Badge, EmptyState, Th, Td, inputCls } from '@/components/ui';
import { NOTICE_TYPE, fmtDateTime } from '@/lib/format';
import NoticeCreateDialog from '@/components/NoticeCreateDialog';
import { NoticeRowActions } from '@/components/NoticeRowActions';

export default async function NoticesPage({ searchParams }: PageProps<'/notices'>) {
  const sp = await searchParams;
  const page = Number(sp.page ?? 1);
  const type = typeof sp.type === 'string' ? sp.type : '';

  const qs = new URLSearchParams({ page: String(page), limit: '15' });
  if (type) qs.set('type', type);

  const list = await api<Paginated<NoticeItem>>(`/notices?${qs}`);

  return (
    <div>
      <PageHeader
        title="Avisos"
        description={`${list.pagination.total} avisos publicados`}
        action={<NoticeCreateDialog />}
      />

      <Card>
        <div className="flex items-center gap-3 border-b border-slate-100 px-5 py-4">
          <form className="flex items-center gap-2" method="GET">
            <select name="type" defaultValue={type} className={`${inputCls} max-w-[160px]`}>
              <option value="">Todos los tipos</option>
              {Object.entries(NOTICE_TYPE).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
            <button className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-600 hover:bg-slate-50">
              Filtrar
            </button>
          </form>
        </div>

        {list.data.length === 0 ? (
          <EmptyState message="No hay avisos" />
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Título</Th>
                <Th>Tipo</Th>
                <Th>Autor</Th>
                <Th>Publicado</Th>
                <Th className="text-right">Acciones</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {list.data.map((n) => (
                <tr key={n.id} className="hover:bg-slate-50/60">
                  <Td className="font-medium text-slate-900">
                    <span className="flex items-center gap-2">
                      {n.isPinned && <span className="text-amber-500" title="Fijado">◆</span>}
                      {n.title}
                    </span>
                    <span className="mt-0.5 block max-w-md truncate text-xs text-slate-400">{n.content}</span>
                  </Td>
                  <Td>
                    <Badge value={n.type} label={NOTICE_TYPE[n.type]} />
                  </Td>
                  <Td>
                    {n.author.firstName} {n.author.lastName}
                  </Td>
                  <Td>{fmtDateTime(n.publishAt)}</Td>
                  <Td className="text-right">
                    <NoticeRowActions id={n.id} isPinned={n.isPinned} />
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
          basePath="/notices"
          params={{ type }}
        />
      </Card>
    </div>
  );
}