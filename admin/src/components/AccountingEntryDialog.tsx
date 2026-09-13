'use client';

import { useState, useActionState } from 'react';
import Modal from '@/components/Modal';
import { createAccountingEntry } from '@/app/actions/accounting';
import { Field, inputCls, btnPrimary } from '@/components/ui';

export default function AccountingEntryDialog() {
  const [open, setOpen] = useState(false);
  const [state, action, pending] = useActionState(createAccountingEntry, {});

  return (
    <>
      <button className={btnPrimary} onClick={() => setOpen(true)}>
        + Registrar partida
      </button>
      <Modal title="Registrar partida contable" open={open} onClose={() => setOpen(false)}>
        <form action={action} className="space-y-4">
          {state.error && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 ring-1 ring-red-200">
              {state.error}
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <Field label="Tipo">
              <select name="type" className={inputCls} defaultValue="EXPENSE">
                <option value="INCOME">Ingreso</option>
                <option value="EXPENSE">Egreso</option>
              </select>
            </Field>
            <Field label="Monto (MXN)">
              <input name="amount" type="number" min="1" step="0.01" required className={inputCls} />
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Categoría">
              <input name="category" required className={inputCls} placeholder="Mantenimiento" />
            </Field>
            <Field label="Subcategoría">
              <input name="subcategory" className={inputCls} />
            </Field>
          </div>
          <Field label="Descripción">
            <input name="description" required className={inputCls} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Fecha">
              <input name="date" type="date" required className={inputCls} />
            </Field>
            <Field label="Referencia">
              <input name="reference" className={inputCls} />
            </Field>
          </div>
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