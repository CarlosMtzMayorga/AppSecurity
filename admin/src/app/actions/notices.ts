'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { api, ApiError } from '@/lib/api';
import type { ActionResult } from '@/app/actions/auth';

export async function createNotice(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const targetRoles = formData.getAll('targetRoles').map(String);
  const payload = {
    title: String(formData.get('title') ?? ''),
    content: String(formData.get('content') ?? ''),
    type: String(formData.get('type') ?? 'GENERAL'),
    isPinned: String(formData.get('isPinned') ?? '') === 'on',
    sendPush: String(formData.get('sendPush') ?? '') === 'on',
    publishAt: String(formData.get('publishAt') ?? '') || undefined,
    expiresAt: String(formData.get('expiresAt') ?? '') || undefined,
    targetRoles: targetRoles.length ? targetRoles : undefined,
  };

  try {
    await api('/notices', { method: 'POST', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al crear aviso' };
  }
  revalidatePath('/notices');
  redirect('/notices');
}

export async function togglePinned(id: string, isPinned: boolean) {
  await api(`/notices/${id}`, { method: 'PATCH', body: JSON.stringify({ isPinned: !isPinned }) });
  revalidatePath('/notices');
}

export async function deleteNotice(id: string) {
  await api(`/notices/${id}`, { method: 'DELETE' });
  revalidatePath('/notices');
}