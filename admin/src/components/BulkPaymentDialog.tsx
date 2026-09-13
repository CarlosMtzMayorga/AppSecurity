'use client';

import { useState, useActionState } from 'react';
import Modal from '@/components/Modal';
import { bulkCreatePayments } from '@/app/actions/payments';
import { Field, inputCls, btnPrimary } from '@/components/ui';
import { PAYMENT_TYPE } from '@/lib/format';

export default function BulkPaymentDialog({ residents }: { residents: Array<{ id: string; label: string }> }) {
  const [open, setOpen] = useState(false);
  const [state, action, pending] = useActionState(bulkCreatePayments, {});

  return (
    <>
      <button className={btnPrimary} onClick={() => setOpen(true)}>
        + Cobro masivo
      </button>
      <Modal title="Cobro masivo" open={open} onClose={() => setOpen(false)}>
        <form action={action} className="space-y-4">
          {state.error && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 ring-1 ring-red-200">
              {state.error}
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <Field label="Tipo de pago">
              <select name="type" className={inputCls}>
                {Object.entries(PAYMENT_TYPE).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Monto (MXN)">
              <input name="amount" type="number" min="1" step="0.01" required className={inputCls} />
            </Field>
          </div>
          <Field label="Descripción">
            <input name="description" required className={inputCls} placeholder="Cuota de mantenimiento septiembre" />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Vencimiento">
              <input name="dueDate" type="date" required className={inputCls} />
            </Field>
            <Field label="Periodo (ini)">
              <input name="periodStart" type="date" className={inputCls} />
            </Field>
          </div>
          <Field label="Residentes activos" hint={`${residents.length} disponibles`}>
            <div className="max-h-52 space-y-1.5 overflow-y-auto rounded-lg border border-slate-200 p-3">
              {residents.map((r) => (
                <label key={r.id} className="flex items-center gap-2 text-sm text-slate-700">
                  <input type="checkbox" name="residentIds" value={r.id} />
                  {r.label}
                </label>
              ))}
            </div>
          </Field>
          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50"
              onClick={() => setOpen(false)}
            >
              Cancelar
            </button>
            <button type="submit" disabled={pending} className={btnPrimary}>
              {pending ? 'Generando…' : 'Generar pagos'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}