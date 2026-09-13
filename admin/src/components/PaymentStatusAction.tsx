'use client';

import { startTransition, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { markPaymentStatus } from '@/app/actions/payments';
import { PAYMENT_STATUS } from '@/lib/format';

export function PaymentStatusAction({ id, status }: { id: string; status: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  return (
    <select
      value={status}
      disabled={pending}
      onChange={(e) =>
        start(() =>
          markPaymentStatus(id, e.target.value).then(() => {
            startTransition(() => router.refresh());
          }),
        )
      }
      className="rounded-lg border border-slate-300 bg-white px-2 py-1 text-xs disabled:opacity-60"
    >
      {Object.entries(PAYMENT_STATUS).map(([k, v]) => (
        <option key={k} value={k}>
          {v}
        </option>
      ))}
    </select>
  );
}