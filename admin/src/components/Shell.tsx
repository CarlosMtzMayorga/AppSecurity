import Link from 'next/link';
import { logoutAction } from '@/app/actions/auth';
import { SessionUser } from '@/lib/types';
import { ROLES } from '@/lib/format';

interface NavItem {
  href: string;
  label: string;
  icon: string;
  roles: string[];
}

const NAV: NavItem[] = [
  { href: '/dashboard', label: 'Inicio', icon: '▦', roles: ['ADMIN', 'COMMITTEE', 'SECURITY'] },
  { href: '/residents', label: 'Residentes', icon: '▤', roles: ['ADMIN', 'COMMITTEE', 'SECURITY'] },
  { href: '/access', label: 'Accesos', icon: '⌁', roles: ['ADMIN', 'COMMITTEE', 'SECURITY'] },
  { href: '/payments', label: 'Pagos', icon: '◈', roles: ['ADMIN', 'COMMITTEE'] },
  { href: '/notices', label: 'Avisos', icon: '☰', roles: ['ADMIN', 'COMMITTEE', 'SECURITY'] },
  { href: '/accounting', label: 'Contabilidad', icon: '§', roles: ['ADMIN', 'COMMITTEE'] },
  { href: '/settings', label: 'Configuración', icon: '⚙', roles: ['ADMIN', 'COMMITTEE'] },
];

export function Shell({ user, children }: { user: SessionUser; children: React.ReactNode }) {
  const items = NAV.filter((n) => n.roles.includes(user.role));

  return (
    <div className="flex min-h-screen bg-slate-100">
      <aside className="flex w-60 shrink-0 flex-col bg-slate-900">
        <div className="flex items-center gap-3 px-5 py-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-indigo-500 text-sm font-bold text-white">
            AS
          </div>
          <div>
            <p className="text-sm font-semibold text-white">AppSecurity</p>
            <p className="text-xs text-slate-400">Panel Admin</p>
          </div>
        </div>
        <nav className="mt-2 flex-1 space-y-1 px-3">
          {items.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 hover:text-white"
            >
              <span className="text-slate-500">{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </nav>
        <div className="border-t border-slate-800 px-5 py-4">
          <p className="text-sm font-medium text-white">
            {user.firstName} {user.lastName}
          </p>
          <p className="text-xs text-slate-400">{ROLES[user.role] ?? user.role}</p>
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
          <p className="text-sm text-slate-500">{user.email}</p>
          <form action={logoutAction}>
            <button
              type="submit"
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
            >
              Cerrar sesión
            </button>
          </form>
        </header>
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}