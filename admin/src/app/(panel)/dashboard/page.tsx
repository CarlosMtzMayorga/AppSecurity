import { api } from '@/lib/api';
import {
  AccessLogItem,
  AccessTrend,
  DashboardOverview,
  PaymentItem,
  PaymentTrend,
  ServiceRequest,
} from '@/lib/types';
import { Card, CardHeader, StatCard, Badge, Td, Th } from '@/components/ui';
import { mxn, fmtDateTime, ACCESS_TYPE, ACCESS_STATUS, PAYMENT_STATUS } from '@/lib/format';

interface ActivityResponse {
  recentAccesses: AccessLogItem[];
  recentPayments: PaymentItem[];
  recentRequests: ServiceRequest[];
  recentNotices: [];
}

type BarDatum = { month?: string; date?: string };

interface BarsProps<T> {
  data: T[];
  valueKey: keyof T;
  height?: number;
}

function Bars<T extends BarDatum>({ data, valueKey, height = 140 }: BarsProps<T>) {
  const values = data.map((d) => (d[valueKey] as number) ?? 0);
  const max = Math.max(...values, 1);
  const label = (d: T) => String(d.month ?? d.date).slice(5);
  return (
    <div className="flex items-end gap-2 px-1" style={{ height }}>
      {data.map((d, i) => (
        <div key={i} className="flex flex-1 flex-col items-center gap-1" title={`${label(d)}: ${d[valueKey]}`}>
          <div
            className="w-full rounded-t bg-indigo-500"
            style={{ height: Math.max((((d[valueKey] as number) ?? 0) / max) * (height - 36), 2) }}
          />
          <span className="text-[10px] text-slate-400">{label(d)}</span>
        </div>
      ))}
    </div>
  );
}

export default async function DashboardPage() {
  const [overview, trends, accessTrends, activity] = await Promise.all([
    api<DashboardOverview>('/dashboard/overview'),
    api<PaymentTrend[]>('/dashboard/payment-trends?months=6'),
    api<AccessTrend[]>('/dashboard/access-trends?days=14'),
    api<ActivityResponse>('/dashboard/recent-activity'),
  ]);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          label="Residentes"
          value={overview.residents.total}
          hint={`${overview.residents.active} activos · ${overview.residents.occupancyRate}% ocupación`}
        />
        <StatCard
          label="Pagos"
          value={overview.payments.total}
          hint={`${overview.payments.pending} pendientes · ${overview.payments.overdue} vencidos`}
          accent={overview.payments.overdue > 0 ? 'text-orange-600' : 'text-slate-900'}
        />
        <StatCard
          label="Finanzas"
          value={mxn(overview.finances.balance)}
          hint={`${mxn(overview.finances.income)} ingresos · ${mxn(overview.finances.expenses)} egresos`}
        />
        <StatCard
          label="Seguridad"
          value={`${overview.security.activeAccesses} activos`}
          hint={`${overview.services.open} solicitudes abiertas`}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Cobros por mes" subtitle="Colocados vs pendientes y vencidos" />
          <div className="p-5">
            <div className="flex items-end gap-6 px-1">
              <div className="flex flex-1 flex-col gap-1">
                <Bars data={trends} valueKey="collected" />
                <p className="text-center text-xs text-slate-400">Colocados</p>
              </div>
              <div className="flex flex-1 flex-col gap-1">
                <Bars data={trends} valueKey="pending" />
                <p className="text-center text-xs text-slate-400">Pendientes</p>
              </div>
            </div>
          </div>
        </Card>
        <Card>
          <CardHeader title="Accesos por día" subtitle="Últimos 14 días" />
          <div className="p-5">
            <Bars data={accessTrends} valueKey="total" />
          </div>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Accesos recientes" />
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Persona</Th>
                <Th>Tipo</Th>
                <Th>Hora</Th>
                <Th>Estado</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {activity.recentAccesses.slice(0, 6).map((a) => (
                <tr key={a.id}>
                  <Td>
                    {a.resident?.user
                      ? `${a.resident.user.firstName} ${a.resident.user.lastName}`
                      : a.visitor
                        ? `${a.visitor.firstName} ${a.visitor.lastName}`
                        : a.unit?.number ?? '—'}
                  </Td>
                  <Td>{ACCESS_TYPE[a.type] ?? a.type}</Td>
                  <Td>{fmtDateTime(a.entryTime)}</Td>
                  <Td>
                    <Badge value={a.status} label={ACCESS_STATUS[a.status]} />
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>

        <Card>
          <CardHeader title="Pagos recientes" />
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Residente</Th>
                <Th>Descripción</Th>
                <Th>Monto</Th>
                <Th>Estado</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {activity.recentPayments.slice(0, 6).map((p) => (
                <tr key={p.id}>
                  <Td>
                    {p.resident?.user?.firstName} {p.resident?.user?.lastName}
                  </Td>
                  <Td>{p.description}</Td>
                  <Td>{mxn(p.amount)}</Td>
                  <Td>
                    <Badge value={p.status} label={PAYMENT_STATUS[p.status]} />
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      </div>
    </div>
  );
}