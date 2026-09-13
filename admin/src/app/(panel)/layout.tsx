import { redirect } from 'next/navigation';
import { getSession } from '@/lib/api';
import { Shell } from '@/components/Shell';

export default async function PanelLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();
  if (!session) redirect('/login');
  if (!['ADMIN', 'COMMITTEE', 'SECURITY'].includes(session.role)) redirect('/login');

  return <Shell user={session}>{children}</Shell>;
}