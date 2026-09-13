'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { api } from '@/lib/api';
import { ApiError } from '@/lib/api';
import type { ActionResult } from '@/app/actions/auth';

export async function createResident(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const plates = String(formData.get('vehiclePlates') ?? '')
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean);

  const payload = {
    email: String(formData.get('email') ?? ''),
    firstName: String(formData.get('firstName') ?? ''),
    lastName: String(formData.get('lastName') ?? ''),
    phone: String(formData.get('phone') ?? '') || undefined,
    unitId: String(formData.get('unitId') ?? ''),
    rut: String(formData.get('rut') ?? '') || undefined,
    emergencyContactName: String(formData.get('emergencyContactName') ?? '') || undefined,
    emergencyContactPhone: String(formData.get('emergencyContactPhone') ?? '') || undefined,
    vehiclePlates: plates.length ? plates : undefined,
  };

  try {
    await api('/residents', { method: 'POST', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al crear residente' };
  }
  revalidatePath('/residents');
  redirect('/residents');
}

export async function approveResident(id: string) {
  await api(`/residents/${id}/approve`, { method: 'POST' });
  revalidatePath(`/residents/${id}`);
}

export async function setResidentStatus(id: string, status: string) {
  await api(`/residents/${id}`, { method: 'PATCH', body: JSON.stringify({ status }) });
  revalidatePath(`/residents/${id}`);
}

export async function deactivateResident(id: string) {
  await api(`/residents/${id}`, { method: 'DELETE' });
  revalidatePath('/residents');
  revalidatePath(`/residents/${id}`);
}