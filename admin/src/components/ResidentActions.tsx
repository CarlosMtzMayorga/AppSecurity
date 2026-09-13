'use client';

import { startTransition, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { approveResident, setResidentStatus, deactivateResident } from '@/app/actions/residents';
import { btnPrimary, btnSecondary, btnDanger } from '@/components/ui';

export function ResidentActions({ id, status }: { id: string; status: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  const run = (fn: () => Promise<void>) => startTransition(async () => {
    await fn();
    router.refresh();
  });

  return (
    <div className="flex flex-wrap gap-2">
      {status === 'PENDING' && (
        <button className={btnPrimary} disabled={pending} onClick={() => run(() => approveResident(id))}>
          Aprobar residente
        </button>
      )}
      {status === 'ACTIVE' && (
        <button className={btnDanger} disabled={pending} onClick={() => run(() => deactivateResident(id))}>
          Desactivar
        </button>
      )}
      {status !== 'ACTIVE' && status !== 'PENDING' && (
        <button className={btnSecondary} disabled={pending} onClick={() => run(() => setResidentStatus(id, 'ACTIVE'))}>
          Reactivar
        </button>
      )}
      {status === 'ACTIVE' && (
        <button
          className={btnSecondary}
          disabled={pending}
          onClick={() => run(() => setResidentStatus(id, 'SUSPENDED'))}
        >
          Suspender
        </button>
      )}
    </div>
  );
}