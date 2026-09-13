'use client';

import { useState, useActionState } from 'react';
import Modal from '@/components/Modal';
import { createResident } from '@/app/actions/residents';
import { Field, inputCls, btnPrimary } from '@/components/ui';
import { UnitListItem } from '@/lib/types';

export default function ResidentCreateDialog({ units }: { units: UnitListItem[] }) {
  const [open, setOpen] = useState(false);
  const [state, action, pending] = useActionState(createResident, {});

  return (
    <>
      <button className={btnPrimary} onClick={() => setOpen(true)}>
        + Adicionar residente
      </button>
      <Modal title="Adicionar residente" open={open} onClose={() => setOpen(false)}>
        <form action={action} className="space-y-4">
          {state.error && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 ring-1 ring-red-200">
              {state.error}
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <Field label="Nombre">
              <input name="firstName" required className={inputCls} />
            </Field>
            <Field label="Apellido">
              <input name="lastName" required className={inputCls} />
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Email">
              <input name="email" type="email" required className={inputCls} />
            </Field>
            <Field label="Teléfono">
              <input name="phone" className={inputCls} />
            </Field>
          </div>
          <Field label="Unidad">
            <select name="unitId" required className={inputCls}>
              <option value="">Selecciona una unidad…</option>
              {units.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.number}
                  {u.block ? ` · Bloque ${u.block}` : ''}
                  {u.hasResident ? ' (ocupada)' : ''}
                </option>
              ))}
            </select>
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="RFC / CURP">
              <input name="rut" className={inputCls} />
            </Field>
            <Field label="Teléfono emergencia">
              <input name="emergencyContactPhone" className={inputCls} />
            </Field>
          </div>
          <Field label="Placas de vehículos" hint="Separadas por comas">
            <input name="vehiclePlates" className={inputCls} placeholder="ABC-123, DEF-456" />
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
              {pending ? 'Guardando…' : 'Guardar'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}