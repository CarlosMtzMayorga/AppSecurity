import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed...');

  const passwordHash = await bcrypt.hash('password123', 12);

  // Create admin user
  const admin = await prisma.user.upsert({
    where: { email: 'admin@appsecurity.com' },
    update: {},
    create: {
      email: 'admin@appsecurity.com',
      passwordHash,
      firstName: 'Admin',
      lastName: 'Sistema',
      role: 'ADMIN',
    },
  });

  // Create residential complex
  const complex = await prisma.residentialComplex.upsert({
    where: { id: 'demo-complex-1' },
    update: {},
    create: {
      id: 'demo-complex-1',
      name: 'Residencial Los Pinos',
      address: 'Av. Principal 123',
      city: 'Ciudad de México',
      state: 'CDMX',
      postalCode: '01000',
      country: 'México',
      phone: '555-123-4567',
      email: 'admin@lospinos.com',
      adminId: admin.id,
      timezone: 'America/Mexico_City',
      currency: 'MXN',
    },
  });

  // Create complex settings
  await prisma.complexSettings.upsert({
    where: { complexId: complex.id },
    update: {},
    create: {
      complexId: complex.id,
      maintenanceFee: 2500,
      extraordinaryFee: 5000,
      lateFeePercent: 5,
      lateFeeGraceDays: 5,
      allowPartialPayment: true,
      requirePaymentApproval: false,
      notifyPaymentDueDays: [7, 3, 1],
      notifyNewVisitor: true,
      notifyAccessEntry: false,
      notifyServiceUpdates: true,
      defaultCurrency: 'MXN',
    },
  });

  // Create access config
  await prisma.accessConfig.upsert({
    where: { complexId: complex.id },
    update: {},
    create: {
      complexId: complex.id,
      maxVisitorHours: 4,
      requirePhoto: true,
      requireDocument: false,
      allowRecurring: true,
      faceRecognition: false,
      plateRecognition: false,
    },
  });

  // Create units
  const units = [];
  for (let i = 1; i <= 20; i++) {
    const block = i <= 10 ? 'A' : 'B';
    const unit = await prisma.unit.upsert({
      where: { id: `unit-${i}` },
      update: {},
      create: {
        id: `unit-${i}`,
        complexId: complex.id,
        number: `${block}-${i <= 10 ? i : i - 10}`,
        block,
        floor: Math.ceil((i <= 10 ? i : i - 10) / 5),
        type: 'HOUSE',
        area: 150 + Math.random() * 50,
        bedrooms: 3,
        bathrooms: 2.5,
        hasParking: true,
        parkingSpots: 2,
        monthlyFee: 2500,
        extraordinaryFee: 5000,
      },
    });
    units.push(unit);
  }

  // Create residents
  const residentData = [
    { email: 'juan.perez@email.com', firstName: 'Juan', lastName: 'Pérez', phone: '555-111-1111', unitIndex: 0 },
    { email: 'maria.garcia@email.com', firstName: 'María', lastName: 'García', phone: '555-222-2222', unitIndex: 1 },
    { email: 'carlos.lopez@email.com', firstName: 'Carlos', lastName: 'López', phone: '555-333-3333', unitIndex: 2 },
    { email: 'ana.martinez@email.com', firstName: 'Ana', lastName: 'Martínez', phone: '555-444-4444', unitIndex: 3 },
    { email: 'pedro.rodriguez@email.com', firstName: 'Pedro', lastName: 'Rodríguez', phone: '555-555-5555', unitIndex: 4 },
  ];

  for (const rd of residentData) {
    const user = await prisma.user.upsert({
      where: { email: rd.email },
      update: {},
      create: {
        email: rd.email,
        passwordHash,
        firstName: rd.firstName,
        lastName: rd.lastName,
        phone: rd.phone,
        role: 'RESIDENT',
      },
    });

    await prisma.resident.upsert({
      where: { userId: user.id },
      update: {},
      create: {
        userId: user.id,
        complexId: complex.id,
        unitId: units[rd.unitIndex].id,
        status: 'ACTIVE',
        rut: `RUT${Math.random().toString(36).substring(2, 10).toUpperCase()}`,
        emergencyContactName: 'Contacto Emergencia',
        emergencyContactPhone: '555-999-9999',
        emergencyContactRelation: 'Familiar',
        vehiclePlates: ['ABC-123', 'XYZ-789'],
      },
    });
  }

  // Create security user
  const securityUser = await prisma.user.upsert({
    where: { email: 'seguridad@lospinos.com' },
    update: {},
    create: {
      email: 'seguridad@lospinos.com',
      passwordHash,
      firstName: 'Seguridad',
      lastName: 'Caseta',
      role: 'SECURITY',
    },
  });

  await prisma.resident.upsert({
    where: { userId: securityUser.id },
    update: {},
    create: {
      userId: securityUser.id,
      complexId: complex.id,
      unitId: units[0].id,
      status: 'ACTIVE',
    },
  });

  // Create committee user
  const committeeUser = await prisma.user.upsert({
    where: { email: 'comite@lospinos.com' },
    update: {},
    create: {
      email: 'comite@lospinos.com',
      passwordHash,
      firstName: 'Comité',
      lastName: 'Administración',
      role: 'COMMITTEE',
    },
  });

  await prisma.resident.upsert({
    where: { userId: committeeUser.id },
    update: {},
    create: {
      userId: committeeUser.id,
      complexId: complex.id,
      unitId: units[1].id,
      status: 'ACTIVE',
    },
  });

  // Create amenities
  const amenitiesData = [
    { name: 'Casa Club', description: 'Salón de eventos con capacidad para 100 personas', capacity: 100, location: 'Planta baja', pricePerHour: 500, requiresApproval: true, maxHoursPerBooking: 6, rules: 'No fumar, música hasta las 22:00' },
    { name: 'Alberca', description: 'Alberca semi-olímpica con chapoteadero', capacity: 50, location: 'Área común', pricePerHour: 200, requiresApproval: false, maxHoursPerBooking: 3, rules: 'Uso de traje de baño obligatorio, ducha antes de entrar' },
    { name: 'Gimnasio', description: 'Gimnasio equipado con máquinas cardio y pesas', capacity: 20, location: 'Planta baja', pricePerHour: 100, requiresApproval: false, maxHoursPerBooking: 2, rules: 'Toalla obligatoria, limpiar equipos después de usar' },
    { name: 'Cancha de Tenis', description: 'Cancha de tenis de superficie dura', capacity: 4, location: 'Área deportiva', pricePerHour: 300, requiresApproval: true, maxHoursPerBooking: 2, rules: 'Zapatos de tenis obligatorios' },
    { name: 'Jardín Principal', description: 'Área verde para eventos al aire libre', capacity: 80, location: 'Centro del fraccionamiento', pricePerHour: 400, requiresApproval: true, maxHoursPerBooking: 4, rules: 'No fogatas, recoger basura' },
  ];

  for (let i = 0; i < amenitiesData.length; i++) {
    const a = amenitiesData[i];
    const amenity = await prisma.amenity.upsert({
      where: { id: `amenity-${i + 1}` },
      update: {},
      create: {
        id: `amenity-${i + 1}`,
        complexId: complex.id,
        ...a,
        currency: 'MXN',
        minHoursNotice: 1,
        maxDaysAdvance: 30,
        images: [],
      },
    });

    // Create schedules (open daily 8:00-22:00)
    for (let day = 0; day < 7; day++) {
      await prisma.amenitySchedule.upsert({
        where: { amenityId_dayOfWeek: { amenityId: amenity.id, dayOfWeek: day } },
        update: {},
        create: {
          amenityId: amenity.id,
          dayOfWeek: day,
          openTime: '08:00',
          closeTime: '22:00',
          isClosed: false,
        },
      });
    }
  }

  // Create some payments
  const residents = await prisma.resident.findMany({ where: { complexId: complex.id, status: 'ACTIVE' } });
  for (const resident of residents) {
    for (let month = 0; month < 6; month++) {
      const dueDate = new Date();
      dueDate.setMonth(dueDate.getMonth() - month);
      dueDate.setDate(1);
      
      await prisma.payment.upsert({
        where: { reference: `PAY-${resident.id}-${dueDate.getFullYear()}-${dueDate.getMonth() + 1}` },
        update: {},
        create: {
          complexId: complex.id,
          residentId: resident.id,
          unitId: resident.unitId,
          userId: admin.id,
          type: 'MAINTENANCE',
          amount: 2500,
          description: `Cuota mantenimiento ${dueDate.toLocaleString('es-MX', { month: 'long', year: 'numeric' })}`,
          reference: `PAY-${resident.id}-${dueDate.getFullYear()}-${dueDate.getMonth() + 1}`,
          dueDate,
          periodStart: new Date(dueDate.getFullYear(), dueDate.getMonth(), 1),
          periodEnd: new Date(dueDate.getFullYear(), dueDate.getMonth() + 1, 0),
          status: month <= 2 ? 'COMPLETED' : (month === 3 ? 'PENDING' : 'OVERDUE'),
          paidAt: month <= 2 ? new Date(dueDate.getTime() + Math.random() * 5 * 24 * 60 * 60 * 1000) : null,
        },
      });
    }
  }

  // Create notices
  await prisma.notice.createMany({
    data: [
      {
        complexId: complex.id,
        authorId: admin.id,
        title: 'Bienvenidos a AppSecurity',
        content: 'Esta es la nueva plataforma de gestión residencial. Aquí encontrarás todos los avisos, pagos, accesos y más.',
        type: 'GENERAL',
        priority: 5,
        isPinned: true,
        targetRoles: ['RESIDENT', 'SECURITY', 'COMMITTEE'],
      },
      {
        complexId: complex.id,
        authorId: admin.id,
        title: 'Mantenimiento de alberca',
        content: 'El próximo lunes 15 de enero la alberca permanecerá cerrada por mantenimiento programado.',
        type: 'MAINTENANCE',
        priority: 8,
        publishAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        targetRoles: ['RESIDENT'],
      },
      {
        complexId: complex.id,
        authorId: admin.id,
        title: 'Asamblea general ordinaria',
        content: 'Se convoca a asamblea general el sábado 20 de enero a las 10:00 en la Casa Club.',
        type: 'EVENT',
        priority: 10,
        isPinned: true,
        publishAt: new Date(),
        expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        targetRoles: ['RESIDENT', 'COMMITTEE'],
      },
    ],
    skipDuplicates: true,
  });

  // Create some access logs
  for (const resident of residents.slice(0, 3)) {
    for (let i = 0; i < 5; i++) {
      const entryTime = new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000);
      await prisma.accessLog.create({
        data: {
          complexId: complex.id,
          unitId: resident.unitId,
          residentId: resident.id,
          type: 'RESIDENT',
          status: 'COMPLETED',
          entryTime,
          exitTime: new Date(entryTime.getTime() + Math.random() * 4 * 60 * 60 * 1000),
          entryMethod: 'APP',
          exitMethod: 'APP',
        },
      });
    }
  }

  // Create service requests
  const categories = ['Plomería', 'Electricidad', 'Jardinería', 'Limpieza', 'Seguridad', 'Otro'];
  for (const resident of residents.slice(0, 3)) {
    for (let i = 0; i < 3; i++) {
      await prisma.serviceRequest.create({
        data: {
          complexId: complex.id,
          unitId: resident.unitId,
          userId: resident.userId,
          title: `${categories[Math.floor(Math.random() * categories.length)]} - Reporte ${i + 1}`,
          description: 'Descripción detallada del problema o solicitud de servicio.',
          category: categories[Math.floor(Math.random() * categories.length)],
          priority: ['LOW', 'MEDIUM', 'HIGH'][Math.floor(Math.random() * 3)] as any,
          status: ['OPEN', 'IN_PROGRESS', 'RESOLVED'][Math.floor(Math.random() * 3)] as any,
        },
      });
    }
  }

  // Create accounting entries
  for (let i = 0; i < 20; i++) {
    const isIncome = Math.random() > 0.4;
    await prisma.accountingEntry.create({
      data: {
        complexId: complex.id,
        type: isIncome ? 'INCOME' : 'EXPENSE',
        category: isIncome ? 'MAINTENANCE' : ['MAINTENANCE', 'SECURITY', 'CLEANING', 'ADMIN', 'UTILITIES'][Math.floor(Math.random() * 5)],
        amount: isIncome ? 2500 + Math.random() * 5000 : 1000 + Math.random() * 10000,
        description: isIncome ? 'Cuota de mantenimiento' : 'Gasto operativo',
        date: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
        createdBy: admin.id,
      },
    });
  }

  console.log('✅ Seed completado');
}

main()
  .catch(e => {
    console.error('❌ Error en seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });