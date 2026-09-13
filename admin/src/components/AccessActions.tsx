'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { approveAccess, exitAccess } from '@/app/actions/access';

export function AccessActions({ id, status }: { id: string; status: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  const run = (fn: () => Promise<void>) =>
    start(async () => {
      await fn();
      router.refresh();
    });

  if (status === 'PENDING') {
    return (
      <div className="flex gap-2">
        <button
          className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs text-white hover:bg-emerald-700 disabled:opacity-60"
          disabled={pending}
          onClick={() => run(() => approveAccess(id, 'APPROVED'))}
        >
          Aprobar
        </button>
        <button
          className="rounded-lg bg-red-600 px-2.5 py-1 text-xs text-white hover:bg-red-700 disabled:opacity-60"
          disabled={pending}
          onClick={() => run(() => approveAccess(id, 'REJECTED'))}
        >
          Rechazar
        </button>
      </div>
    );
  }

  if (status === 'APPROVED') {
    return (
      <button
        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs text-slate-600 hover:bg-slate-50 disabled:opacity-60"
        disabled={pending}
        onClick={() => run(() => exitAccess(id))}
      >
        Registrar salida
      </button>
    );
  }

  return <span className="text-xs text-slate-400">—</span>;
}