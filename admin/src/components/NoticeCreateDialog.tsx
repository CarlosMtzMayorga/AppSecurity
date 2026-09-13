'use client';

import { useState, useActionState } from 'react';
import Modal from '@/components/Modal';
import { createNotice } from '@/app/actions/notices';
import { Field, inputCls, btnPrimary } from '@/components/ui';
import { NOTICE_TYPE } from '@/lib/format';

const ROLES = [
  { value: 'ADMIN', label: 'Administración' },
  { value: 'COMMITTEE', label: 'Comité' },
  { value: 'SECURITY', label: 'Seguridad' },
  { value: 'RESIDENT', label: 'Residentes' },
];

export default function NoticeCreateDialog() {
  const [open, setOpen] = useState(false);
  const [state, action, pending] = useActionState(createNotice, {});

  return (
    <>
      <button className={btnPrimary} onClick={() => setOpen(true)}>
        + Nuevo aviso
      </button>
      <Modal title="Nuevo aviso" open={open} onClose={() => setOpen(false)}>
        <form action={action} className="space-y-4">
          {state.error && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 ring-1 ring-red-200">
              {state.error}
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <Field label="Título">
              <input name="title" required className={inputCls} />
            </Field>
            <Field label="Tipo">
              <select name="type" className={inputCls}>
                {Object.entries(NOTICE_TYPE).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <Field label="Contenido">
            <textarea name="content" required rows={4} className={inputCls} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Publicar en">
              <input name="publishAt" type="datetime-local" className={inputCls} />
            </Field>
            <Field label="Expira">
              <input name="expiresAt" type="datetime-local" className={inputCls} />
            </Field>
          </div>
          <Field label="Dirigido a">
            <div className="flex flex-wrap gap-3 rounded-lg border border-slate-200 p-3">
              {ROLES.map((r) => (
                <label key={r.value} className="flex items-center gap-2 text-sm text-slate-700">
                  <input type="checkbox" name="targetRoles" value={r.value} defaultChecked={r.value === 'RESIDENT'} />
                  {r.label}
                </label>
              ))}
            </div>
          </Field>
          <label className="flex items-center gap-2 text-sm text-slate-700">
            <input type="checkbox" name="isPinned" />
            Fijar aviso
          </label>
          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50"
              onClick={() => setOpen(false)}
            >
              Cancelar
            </button>
            <button type="submit" disabled={pending} className={btnPrimary}>
              {pending ? 'Publicando…' : 'Publicar'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}