import { ReactNode } from 'react';
import Link from 'next/link';

export const inputCls =
  'w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 bg-white';

export const btnPrimary =
  'inline-flex items-center justify-center rounded-lg bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-60';

export const btnSecondary =
  'inline-flex items-center justify-center rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60';

export const btnDanger =
  'inline-flex items-center justify-center rounded-lg bg-red-600 px-3 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60';

export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`rounded-xl bg-white shadow-sm ring-1 ring-slate-200 ${className}`}>
      {children}
    </div>
  );
}

export function CardHeader({ title, subtitle, action }: { title: string; subtitle?: string; action?: ReactNode }) {
  return (
    <div className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
      <div>
        <h2 className="text-sm font-semibold text-slate-900">{title}</h2>
        {subtitle && <p className="mt-0.5 text-xs text-slate-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function StatCard({
  label,
  value,
  hint,
  accent = 'text-slate-900',
}: {
  label: string;
  value: ReactNode;
  hint?: string;
  accent?: string;
}) {
  return (
    <Card className="px-5 py-4">
      <p className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</p>
      <p className={`mt-1 text-2xl font-semibold ${accent}`}>{value}</p>
      {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
    </Card>
  );
}

const badgeColors: Record<string, string> = {
  ACTIVE: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  COMPLETED: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  APPROVED: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  PENDING: 'bg-amber-50 text-amber-700 ring-amber-200',
  INACTIVE: 'bg-slate-100 text-slate-600 ring-slate-200',
  FAILED: 'bg-red-50 text-red-700 ring-red-200',
  REJECTED: 'bg-red-50 text-red-700 ring-red-200',
  SUSPENDED: 'bg-red-50 text-red-700 ring-red-200',
  OVERDUE: 'bg-orange-50 text-orange-700 ring-orange-200',
  EXPIRED: 'bg-slate-100 text-slate-600 ring-slate-200',
  REFUNDED: 'bg-slate-100 text-slate-600 ring-slate-200',
};

export function Badge({ value, label }: { value: string; label?: string }) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ${
        badgeColors[value] ?? 'bg-slate-50 text-slate-700 ring-slate-200'
      }`}
    >
      {label ?? value}
    </span>
  );
}

export function PageHeader({ title, description, action }: { title: string; description?: string; action?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">{title}</h1>
        {description && <p className="mt-1 text-sm text-slate-500">{description}</p>}
      </div>
      {action}
    </div>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="px-5 py-10 text-center text-sm text-slate-400">{message}</div>
  );
}

export function Field({ label, children, hint }: { label: string; children: ReactNode; hint?: string }) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium text-slate-700">{label}</span>
      {children}
      {hint && <span className="mt-1 block text-xs text-slate-400">{hint}</span>}
    </label>
  );
}

export function Pagination({
  page,
  totalPages,
  total,
  params,
  basePath,
}: {
  page: number;
  totalPages: number;
  total: number;
  params: Record<string, string | undefined>;
  basePath: string;
}) {
  const build = (p: number) => {
    const sp = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v) sp.set(k, v);
    }
    sp.set('page', String(p));
    return `${basePath}?${sp.toString()}`;
  };

  return (
    <div className="flex items-center justify-between border-t border-slate-100 px-5 py-3 text-sm">
      <p className="text-slate-500">
        {total === 0 ? 'Sin resultados' : `Mostrando página ${page} de ${totalPages} · ${total} registros`}
      </p>
      {totalPages > 1 && (
        <div className="flex gap-2">
          {page > 1 ? (
            <Link href={build(page - 1)} className={btnSecondary}>
              Anterior
            </Link>
          ) : (
            <span />
          )}
          {page < totalPages ? (
            <Link href={build(page + 1)} className={btnSecondary}>
              Siguiente
            </Link>
          ) : (
            <span />
          )}
        </div>
      )}
    </div>
  );
}

export function Th({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <th className={`px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 ${className}`}>
      {children}
    </th>
  );
}

export function Td({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <td className={`px-4 py-3 text-sm text-slate-700 ${className}`}>{children}</td>;
}