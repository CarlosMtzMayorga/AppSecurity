'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { togglePinned, deleteNotice } from '@/app/actions/notices';

export function NoticeRowActions({ id, isPinned }: { id: string; isPinned: boolean }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  const run = (fn: () => Promise<void>) => start(async () => {
    await fn();
    router.refresh();
  });

  return (
    <div className="flex gap-2">
      <button
        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs text-slate-600 hover:bg-slate-50 disabled:opacity-60"
        disabled={pending}
        onClick={() => run(() => togglePinned(id, isPinned))}
      >
        {isPinned ? 'Quitar pin' : 'Fijar'}
      </button>
      <button
        className="rounded-lg border border-red-200 px-2.5 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-60"
        disabled={pending}
        onClick={() => run(() => deleteNotice(id))}
      >
        Eliminar
      </button>
    </div>
  );
}