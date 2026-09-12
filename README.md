# AppSecurity - Sistema de Gestión Residencial

Una aplicación completa de gestión residencial tipo **BeResident** construida con **Flutter** (frontend) y **Node.js + PostgreSQL** (backend).

## 🏗️ Arquitectura

```
AppSecurity/
├── backend/          # API REST con Node.js + TypeScript + Prisma ORM
├── frontend/         # App móvil con Flutter + Riverpod
└── README.md
```

## ✨ Características Principales

### 🔐 Control de Accesos
- Entrada/salida de residentes (app, tarjeta, QR, facial)
- Registro y gestión de visitantes (únicos y recurrentes)
- Accesos de servicios y entregas
- Bitácora completa con filtros y estadísticas
- Panel de accesos activos en tiempo real

### 💰 Gestión de Pagos
- Cuotas de mantenimiento y extraordinarias
- Integración con Stripe para pagos con tarjeta
- Pagos masivos y recurrentes
- Reportes de morosidad y tendencias
- Comprobantes digitales

### 📢 Comunicaciones
- Avisos del comité (generales, urgentes, mantenimiento, eventos, seguridad)
- Notificaciones push y en-app
- Lectura confirmada
- Avisos fijados y programados

### 🏠 Reservas de Amenidades
- Casa club, alberca, gimnasio, canchas, jardines
- Horarios y reglas por amenidad
- Aprobación automática o manual
- Calendario de disponibilidad

### 🔧 Solicitudes de Servicio
- Reportes de mantenimiento (plomería, electricidad, jardinería, etc.)
- Prioridades (baja, media, alta, urgente)
- Asignación a personal
- Seguimiento de estado y calificación

### 📊 Contabilidad y Reportes
- Ingresos y egresos por categoría
- Balance mensual y anual
- Tendencias de pagos y accesos
- Dashboard ejecutivo en tiempo real

### ⚙️ Administración
- Gestión de residentes y unidades
- Configuración de fraccionamiento
- Control de accesos (caseta, horarios, requerimientos)
- Configuración de Stripe y notificaciones

## 🛠️ Stack Tecnológico

### Backend
- **Node.js** + **TypeScript** + **Express**
- **Prisma ORM** + **PostgreSQL**
- **JWT** para autenticación (access + refresh tokens)
- **Stripe** para pagos
- **Zod** para validación
- **bcryptjs** para hash de contraseñas

### Frontend
- **Flutter 3.x** + **Dart 3.x**
- **Riverpod** para manejo de estado
- **Dio** + **Retrofit** para networking
- **GoRouter** para navegación
- **FL Chart** para gráficas
- **Material 3** + **Google Fonts (Inter)**

## 🚀 Inicio Rápido

### Prerrequisitos
- Node.js 20+
- Flutter 3.19+
- PostgreSQL 15+
- Cuenta Stripe (opcional, para pagos)

### Backend
```bash
cd backend
cp .env.example .env
# Editar .env con tus credenciales
npm install
npm run prisma:generate
npm run prisma:migrate
npm run db:seed
npm run dev
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome  # Web
# flutter run -d android/ios  # Móvil
```

## 🔧 Configuración

### Variables de Entorno (Backend)
```env
DATABASE_URL="postgresql://user:pass@localhost:5432/appsecurity"
JWT_SECRET="tu-secreto-super-seguro"
JWT_REFRESH_SECRET="tu-refresh-secreto"
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
FRONTEND_URL="http://localhost:3000"
```

### Usuarios de Prueba (después de seed)
```
Admin:      admin@appsecurity.com / password123
Residente:  juan.perez@email.com / password123
Seguridad:  seguridad@lospinos.com / password123
Comité:     comite@lospinos.com / password123
```

## 📱 Capturas de Pantalla

*(Agregar capturas aquí)*

## 🧪 Testing
```bash
# Backend
cd backend && npm test

# Frontend
cd frontend && flutter test
```

## 📦 Build para Producción

### Backend
```bash
cd backend
npm run build
npm start
```

### Frontend (Web)
```bash
cd frontend
flutter build web --release
```

### Frontend (Android)
```bash
cd frontend
flutter build apk --release
# o
flutter build appbundle --release
```

### Frontend (iOS)
```bash
cd frontend
flutter build ios --release
```

## 🔒 Seguridad
- Contraseñas hasheadas con bcrypt (12 rounds)
- JWT con access tokens cortos (7d) + refresh tokens (30d)
- Validación estricta en backend y frontend
- Rate limiting recomendado en producción
- HTTPS obligatorio en producción

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📞 Soporte

- Issues: [GitHub Issues](https://github.com/CarlosMtzMayorga/AppSecurity/issues)
- Email: carlos.mtz.mayorga@gmail.com

---

Desarrollado con ❤️ por [Carlos Martínez Mayorga](https://github.com/CarlosMtzMayorga)