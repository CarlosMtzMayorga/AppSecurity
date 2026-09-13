'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { deleteAccountingEntry } from '@/app/actions/accounting';

export function AccountingEntryActions({ id }: { id: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  return (
    <button
      className="rounded-lg border border-red-200 px-2.5 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-60"
      disabled={pending}
      onClick={() =>
        start(async () => {
          await deleteAccountingEntry(id);
          router.refresh();
        })
      }
    >
      Eliminar
    </button>
  );
}