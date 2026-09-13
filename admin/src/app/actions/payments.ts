'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { api, ApiError } from '@/lib/api';
import type { ActionResult } from '@/app/actions/auth';

export async function bulkCreatePayments(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const residentIds = formData.getAll('residentIds').map(String);
  const payload = {
    type: String(formData.get('type') ?? 'MAINTENANCE'),
    amount: Number(formData.get('amount') ?? 0),
    description: String(formData.get('description') ?? ''),
    dueDate: String(formData.get('dueDate') ?? ''),
    periodStart: String(formData.get('periodStart') ?? '') || undefined,
    periodEnd: String(formData.get('periodEnd') ?? '') || undefined,
    residentIds,
  };

  if (!residentIds.length || !payload.amount || !payload.description || !payload.dueDate) {
    return { error: 'Completa residentes, monto, descripción y fecha de vencimiento' };
  }

  try {
    await api('/payments/bulk', { method: 'POST', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al crear pagos' };
  }
  revalidatePath('/payments');
  redirect('/payments');
}

export async function markPaymentStatus(id: string, status: string) {
  await api(`/payments/${id}`, { method: 'PATCH', body: JSON.stringify({ status }) });
  revalidatePath('/payments');
}