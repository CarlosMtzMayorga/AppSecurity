'use server';

import { revalidatePath } from 'next/cache';
import { api } from '@/lib/api';

export async function approveAccess(id: string, status: 'APPROVED' | 'REJECTED') {
  await api(`/access/${id}/approve`, { method: 'PATCH', body: JSON.stringify({ status }) });
  revalidatePath('/access');
}

export async function exitAccess(id: string) {
  await api(`/access/${id}/exit`, { method: 'PATCH' });
  revalidatePath('/access');
}