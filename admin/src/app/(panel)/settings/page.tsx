import { api } from '@/lib/api';
import { ResidentialComplex } from '@/lib/types';
import { PageHeader } from '@/components/ui';
import SettingsTabs from '@/components/SettingsTabs';

export default async function SettingsPage() {
  const complex = await api<ResidentialComplex>('/config/complex');

  return (
    <div>
      <PageHeader title="Configuración" description={complex.name} />
      <SettingsTabs complex={complex} />
    </div>
  );
}