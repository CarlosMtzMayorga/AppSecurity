import { notFound } from 'next/navigation';
import { api, ApiError } from '@/lib/api';
import { ResidentDetail } from '@/lib/types';
import { Card, CardHeader, Badge, PageHeader, Th, Td, EmptyState } from '@/components/ui';
import { RESIDENT_STATUS, fmtDate, fmtDateTime, mxn, ACCESS_TYPE, ACCESS_STATUS, PAYMENT_STATUS } from '@/lib/format';
import { ResidentActions } from '@/components/ResidentActions';
import Link from 'next/link';

export default async function ResidentDetailPage({ params }: PageProps<'/residents/[id]'>) {
  const { id } = await params;

  let resident: ResidentDetail;
  try {
    resident = await api<ResidentDetail>(`/residents/${id}`);
  } catch (e) {
    if (e instanceof ApiError && e.status === 404) notFound();
    throw e;
  }

  const payments = resident.payments ?? [];
  const accesses = resident.accesses ?? [];
  const visitors = resident.visitors ?? [];

  return (
    <div className="space-y-6">
      <PageHeader
        title={`${resident.user.firstName} ${resident.user.lastName}`}
        description={`${resident.user.email} · ${resident.unit.number}${resident.unit.block ? ` · Bloque ${resident.unit.block}` : ''}`}
      />

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader title="Información del residente" action={<Badge value={resident.status} label={RESIDENT_STATUS[resident.status]} />} />
          <div className="grid grid-cols-2 gap-x-6 gap-y-4 px-5 py-4 text-sm">
            <Info label="RFC / CURP" value={resident.rut ?? '—'} />
            <Info label="QR" value={resident.qrCode ?? '—'} />
            <Info label="Vehículos" value={resident.vehiclePlates.length ? resident.vehiclePlates.join(', ') : '—'} />
            <Info label="Tarjetas" value={resident.accessCards.length ? resident.accessCards.join(', ') : '—'} />
            <Info label="Face ID" value={resident.faceIdEnabled ? 'Habilitado' : 'Deshabilitado'} />
            <Info label="Miembro desde" value={fmtDate(resident.joinedAt)} />
            <Info label="Aprobado el" value={fmtDateTime(resident.approvedAt)} />
            <Info label="Contacto emergencia" value={resident.emergencyContactName ?? '—'} />
            {resident.emergencyContactPhone && <Info label="Tel. emergencia" value={resident.emergencyContactPhone} />}
          </div>
          <div className="border-t border-slate-100 px-5 py-4">
            <ResidentActions id={resident.id} status={resident.status} />
          </div>
        </Card>

        <Card>
          <CardHeader title="Unidad" />
          <div className="space-y-3 px-5 py-4 text-sm">
            <Info label="Número / Bloque" value={`${resident.unit.number}${resident.unit.block ? ` / ${resident.unit.block}` : ''}`} />
            <Info label="Tipo" value={resident.unit.type} />
            <Info label="Área" value={resident.unit.area ? `${resident.unit.area} m²` : '—'} />
            <Info label="Cuota mensual" value={mxn(resident.unit.monthlyFee)} />
          </div>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Accesos recientes" />
          {accesses.length === 0 ? (
            <EmptyState message="Sin accesos registrados" />
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-100">
                  <Th>Fecha</Th>
                  <Th>Tipo</Th>
                  <Th>Método</Th>
                  <Th>Estado</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {accesses.slice(0, 6).map((a) => (
                  <tr key={a.id}>
                    <Td>{fmtDateTime(a.entryTime ?? a.createdAt)}</Td>
                    <Td>{ACCESS_TYPE[a.type] ?? a.type}</Td>
                    <Td>{a.entryMethod ?? '—'}</Td>
                    <Td>
                      <Badge value={a.status} label={ACCESS_STATUS[a.status]} />
                    </Td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </Card>

        <Card>
          <CardHeader title="Pagos recientes" action={<Link href="/payments" className="text-xs text-indigo-600 hover:underline">Ver todos</Link>} />
          {payments.length === 0 ? (
            <EmptyState message="Sin pagos registrados" />
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-100">
                  <Th>Descripción</Th>
                  <Th>Monto</Th>
                  <Th>Vence</Th>
                  <Th>Estado</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {payments.slice(0, 5).map((p) => (
                  <tr key={p.id}>
                    <Td>{p.description}</Td>
                    <Td>{mxn(p.amount)}</Td>
                    <Td>{fmtDate(p.dueDate)}</Td>
                    <Td>
                      <Badge value={p.status} label={PAYMENT_STATUS[p.status]} />
                    </Td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </Card>
      </div>

      {visitors.length > 0 && (
        <Card>
          <CardHeader title="Visitantes frecuentes" />
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <Th>Nombre</Th>
                <Th>Teléfono</Th>
                <Th>Placa</Th>
                <Th>Recurrente</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {visitors.map((v) => (
                <tr key={v.id}>
                  <Td>{v.firstName} {v.lastName}</Td>
                  <Td>{v.phone ?? '—'}</Td>
                  <Td>{v.vehiclePlate ?? '—'}</Td>
                  <Td>{v.isRecurring ? 'Sí' : 'No'}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs font-medium uppercase tracking-wide text-slate-400">{label}</p>
      <p className="mt-0.5 text-sm text-slate-800">{value}</p>
    </div>
  );
}