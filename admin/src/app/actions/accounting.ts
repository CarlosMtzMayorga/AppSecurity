'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { api, ApiError } from '@/lib/api';
import type { ActionResult } from '@/app/actions/auth';

export async function createAccountingEntry(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const payload = {
    type: String(formData.get('type') ?? 'EXPENSE'),
    category: String(formData.get('category') ?? ''),
    subcategory: String(formData.get('subcategory') ?? '') || undefined,
    amount: Number(formData.get('amount') ?? 0),
    description: String(formData.get('description') ?? ''),
    reference: String(formData.get('reference') ?? '') || undefined,
    date: String(formData.get('date') ?? ''),
  };

  if (!payload.category || !payload.amount || !payload.description || !payload.date) {
    return { error: 'Completa categoría, monto, descripción y fecha' };
  }

  try {
    await api('/accounting', { method: 'POST', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al registrar la partida' };
  }
  revalidatePath('/accounting');
  redirect('/accounting');
}

export async function deleteAccountingEntry(id: string) {
  await api(`/accounting/${id}`, { method: 'DELETE' });
  revalidatePath('/accounting');
}