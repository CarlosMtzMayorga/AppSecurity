'use server';

import { redirect } from 'next/navigation';
import { api, ApiError, createSession, destroySession } from '@/lib/api';
import { SessionUser } from '@/lib/types';

export interface ActionResult {
  error?: string;
  ok?: boolean;
}

export async function loginAction(_prev: ActionResult, formData: FormData): Promise<ActionResult> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');

  try {
    const data = await api<{ user: SessionUser; accessToken: string; refreshToken: string }>(
      '/auth/login',
      { method: 'POST', body: JSON.stringify({ email, password }) },
    );
    await createSession(data.accessToken, data.refreshToken);
  } catch (e) {
    return { error: e instanceof ApiError ? e.message : 'Error al iniciar sesión' };
  }

  redirect('/dashboard');
}

export async function logoutAction() {
  try {
    await api('/auth/logout', { method: 'POST' });
  } catch {
    /* token may already be expired */
  }
  await destroySession();
  redirect('/login');
}