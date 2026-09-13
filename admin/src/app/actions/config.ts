'use server';

import { revalidatePath } from 'next/cache';
import { api, ApiError } from '@/lib/api';
import type { ActionResult } from '@/app/actions/auth';

const bool = (v: FormDataEntryValue | null) => String(v ?? '') === 'on';

export async function updateComplex(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const payload = {
    name: String(formData.get('name') ?? ''),
    address: String(formData.get('address') ?? ''),
    city: String(formData.get('city') ?? ''),
    state: String(formData.get('state') ?? ''),
    postalCode: String(formData.get('postalCode') ?? ''),
    phone: String(formData.get('phone') ?? '') || undefined,
    email: String(formData.get('email') ?? '') || undefined,
  };
  try {
    await api('/config/complex', { method: 'PATCH', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al guardar' };
  }
  revalidatePath('/settings');
  return { ok: true };
}

export async function updateAccessConfig(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const payload = {
    gateIp: String(formData.get('gateIp') ?? '') || null,
    gatePort: Number(formData.get('gatePort') ?? 0) || null,
    gateUsername: String(formData.get('gateUsername') ?? '') || null,
    cameraUrl: String(formData.get('cameraUrl') ?? '') || null,
    autoOpenEnabled: bool(formData.get('autoOpenEnabled')),
    autoOpenHoursStart: String(formData.get('autoOpenHoursStart') ?? '') || null,
    autoOpenHoursEnd: String(formData.get('autoOpenHoursEnd') ?? '') || null,
    maxVisitorHours: Number(formData.get('maxVisitorHours') ?? 4),
    requirePhoto: bool(formData.get('requirePhoto')),
    requireDocument: bool(formData.get('requireDocument')),
    allowRecurring: bool(formData.get('allowRecurring')),
    faceRecognition: bool(formData.get('faceRecognition')),
    plateRecognition: bool(formData.get('plateRecognition')),
  };
  try {
    await api('/config/access', { method: 'PATCH', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al guardar' };
  }
  revalidatePath('/settings');
  return { ok: true };
}

export async function updateSettings(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const payload = {
    maintenanceFee: Number(formData.get('maintenanceFee') ?? 0),
    extraordinaryFee: Number(formData.get('extraordinaryFee') ?? 0),
    lateFeePercent: Number(formData.get('lateFeePercent') ?? 5),
    lateFeeGraceDays: Number(formData.get('lateFeeGraceDays') ?? 5),
    allowPartialPayment: bool(formData.get('allowPartialPayment')),
    requirePaymentApproval: bool(formData.get('requirePaymentApproval')),
    notifyNewVisitor: bool(formData.get('notifyNewVisitor')),
    notifyAccessEntry: bool(formData.get('notifyAccessEntry')),
    notifyServiceUpdates: bool(formData.get('notifyServiceUpdates')),
  };
  try {
    await api('/config/settings', { method: 'PATCH', body: JSON.stringify(payload) });
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al guardar' };
  }
  revalidatePath('/settings');
  return { ok: true };
}