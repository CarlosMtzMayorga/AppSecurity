'use client';

import { useState, useActionState } from 'react';
import { updateComplex, updateAccessConfig, updateSettings } from '@/app/actions/config';
import { Field, inputCls, btnPrimary, Card } from '@/components/ui';
import { ResidentialComplex } from '@/lib/types';

function Feedback({ state, pending }: { state: { error?: string; ok?: boolean } | undefined; pending: boolean }) {
  if (pending) return <div className="rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-500">Guardando…</div>;
  if (state?.error) {
    return <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 ring-1 ring-red-200">{state.error}</div>;
  }
  if (state?.ok) {
    return <div className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-700 ring-1 ring-emerald-200">Cambios guardados</div>;
  }
  return null;
}

function SubmitRow({ pending }: { pending: boolean }) {
  return (
    <div className="flex justify-end">
      <button type="submit" disabled={pending} className={btnPrimary}>
        {pending ? 'Guardando…' : 'Guardar cambios'}
      </button>
    </div>
  );
}

function ComplexForm({ complex }: { complex: ResidentialComplex }) {
  const [state, action, pending] = useActionState(updateComplex, {});
  return (
    <form action={action} className="space-y-4 p-5">
      <Feedback state={state} pending={pending} />
      <div className="grid grid-cols-2 gap-3">
        <Field label="Nombre">
          <input name="name" defaultValue={complex.name} required className={inputCls} />
        </Field>
        <Field label="Email">
          <input name="email" type="email" defaultValue={complex.email ?? ''} className={inputCls} />
        </Field>
        <Field label="Teléfono">
          <input name="phone" defaultValue={complex.phone ?? ''} className={inputCls} />
        </Field>
        <Field label="Dirección">
          <input name="address" defaultValue={complex.address} className={inputCls} />
        </Field>
        <Field label="Ciudad">
          <input name="city" defaultValue={complex.city} className={inputCls} />
        </Field>
        <Field label="Estado">
          <input name="state" defaultValue={complex.state} className={inputCls} />
        </Field>
        <Field label="Código postal">
          <input name="postalCode" defaultValue={complex.postalCode} className={inputCls} />
        </Field>
      </div>
      <SubmitRow pending={pending} />
    </form>
  );
}

function AccessForm({ config }: { config: ResidentialComplex['accessConfig'][number] | undefined }) {
  const [state, action, pending] = useActionState(updateAccessConfig, {});
  const c = config;
  return (
    <form action={action} className="space-y-4 p-5">
      <Feedback state={state} pending={pending} />
      <div className="grid grid-cols-2 gap-3">
        <Field label="IP de caseta">
          <input name="gateIp" defaultValue={c?.gateIp ?? ''} placeholder="192.168.1.10" className={inputCls} />
        </Field>
        <Field label="Puerto">
          <input name="gatePort" type="number" defaultValue={c?.gatePort ?? ''} className={inputCls} />
        </Field>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <Field label="URL cámara">
          <input name="cameraUrl" defaultValue={c?.cameraUrl ?? ''} className={inputCls} />
        </Field>
        <Field label="Horas máx. visita">
          <input name="maxVisitorHours" type="number" min="1" defaultValue={c?.maxVisitorHours ?? 4} className={inputCls} />
        </Field>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Auto abrir desde">
          <input name="autoOpenHoursStart" type="time" defaultValue={c?.autoOpenHoursStart ?? ''} className={inputCls} />
        </Field>
        <Field label="Auto abrir hasta">
          <input name="autoOpenHoursEnd" type="time" defaultValue={c?.autoOpenHoursEnd ?? ''} className={inputCls} />
        </Field>
      </div>
      <div className="grid grid-cols-2 gap-2 rounded-lg border border-slate-200 p-3 text-sm text-slate-700">
        <Switch name="autoOpenEnabled" label="Auto apertura" defaultOn={c?.autoOpenEnabled ?? false} />
        <Switch name="requirePhoto" label="Requerir foto de visitante" defaultOn={c?.requirePhoto ?? true} />
        <Switch name="requireDocument" label="Requerir documento" defaultOn={c?.requireDocument ?? false} />
        <Switch name="allowRecurring" label="Visitas recurrentes" defaultOn={c?.allowRecurring ?? true} />
        <Switch name="faceRecognition" label="Reconocimiento facial" defaultOn={c?.faceRecognition ?? false} />
        <Switch name="plateRecognition" label="Reconocimiento de placas" defaultOn={c?.plateRecognition ?? false} />
      </div>
      <SubmitRow pending={pending} />
    </form>
  );
}

function SettingsForm({ settings }: { settings: ResidentialComplex['settings'] }) {
  const [state, action, pending] = useActionState(updateSettings, {});
  const s = settings;
  return (
    <form action={action} className="space-y-4 p-5">
      <Feedback state={state} pending={pending} />
      <div className="grid grid-cols-2 gap-3">
        <Field label="Cuota de mantenimiento (MXN)">
          <input name="maintenanceFee" type="number" min="0" step="0.01" defaultValue={s?.maintenanceFee ?? 0} className={inputCls} />
        </Field>
        <Field label="Extraordinaria (MXN)">
          <input name="extraordinaryFee" type="number" min="0" step="0.01" defaultValue={s?.extraordinaryFee ?? 0} className={inputCls} />
        </Field>
        <Field label="Interés por mora (%)">
          <input name="lateFeePercent" type="number" min="0" step="0.1" defaultValue={s?.lateFeePercent ?? 5} className={inputCls} />
        </Field>
        <Field label="Días de gracia">
          <input name="lateFeeGraceDays" type="number" min="0" defaultValue={s?.lateFeeGraceDays ?? 5} className={inputCls} />
        </Field>
      </div>
      <div className="grid grid-cols-2 gap-2 rounded-lg border border-slate-200 p-3 text-sm text-slate-700">
        <Switch name="allowPartialPayment" label="Permitir pagos parciales" defaultOn={s?.allowPartialPayment ?? false} />
        <Switch name="requirePaymentApproval" label="Requiere aprobación de pago" defaultOn={s?.requirePaymentApproval ?? false} />
        <Switch name="notifyNewVisitor" label="Notificar visitas nuevas" defaultOn={s?.notifyNewVisitor ?? true} />
        <Switch name="notifyAccessEntry" label="Notificar accesos" defaultOn={s?.notifyAccessEntry ?? false} />
        <Switch name="notifyServiceUpdates" label="Notificar actualizaciones de servicios" defaultOn={s?.notifyServiceUpdates ?? true} />
      </div>
      <SubmitRow pending={pending} />
    </form>
  );
}

function Switch({ name, label, defaultOn }: { name: string; label: string; defaultOn: boolean }) {
  return (
    <label className="flex items-center gap-2">
      <input type="checkbox" name={name} defaultChecked={defaultOn} className="h-4 w-4 accent-indigo-600" />
      {label}
    </label>
  );
}

const TABS = [
  { key: 'complex', label: 'Complejo' },
  { key: 'access', label: 'Control de accesos' },
  { key: 'settings', label: 'Ajustes generales' },
] as const;

export default function SettingsTabs({ complex }: { complex: ResidentialComplex }) {
  const [tab, setTab] = useState<(typeof TABS)[number]['key']>('complex');

  return (
    <Card>
      <div className="flex border-b border-slate-100">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-5 py-3 text-sm font-medium ${
              tab === t.key
                ? 'border-b-2 border-indigo-600 text-indigo-700'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>
      {tab === 'complex' && <ComplexForm complex={complex} />}
      {tab === 'access' && <AccessForm config={complex.accessConfig[0]} />}
      {tab === 'settings' && <SettingsForm settings={complex.settings} />}
    </Card>
  );
}