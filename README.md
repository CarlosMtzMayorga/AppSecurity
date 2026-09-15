# AppSecurity - Sistema de Gestión Residencial

Plataforma completa de gestión residencial tipo **BeResident** compuesta por tres aplicaciones:

1. **App Residente** (Flutter Web/Mobile) — Control de portones, tokens QR para visitantes, pagos, avisos, bitácora de accesos
2. **Panel Administrativo** (Next.js) — Gestión de residentes, pagos, accesos, configuración
3. **API Backend** (Node.js + PostgreSQL) — REST API con autenticación JWT, Stripe, Prisma ORM

## Arquitectura

```
AppSecurity/
├── backend/          # API REST — Node.js + TypeScript + Express + Prisma ORM
├── frontend/         # App residente — Flutter + Riverpod + GoRouter
├── admin/            # Panel administrativo — Next.js 16 + Tailwind CSS
└── README.md
```

## Stack Tecnológico

### Backend
- **Node.js 20+** + **TypeScript** + **Express**
- **Prisma ORM** + **PostgreSQL 15+**
- **JWT** (access + refresh tokens) para autenticación
- **Stripe** para pagos con tarjeta
- **Zod** para validación de schemas

### App Residente (Flutter)
- **Flutter 3.x** + **Dart 3.x**
- **Riverpod** para manejo de estado
- **Dio** para networking con proxy a API
- **GoRouter** para navegación (menú estilo beResident)
- **QR Flutter** para tokens de visitantes
- **Material 3**

### Panel Administrativo (Next.js)
- **Next.js 16** + **React 19**
- **Tailwind CSS** + **shadcn/ui**
- **Server-side cookies** para sesión JWT

## Inicio Rápido

### Prerrequisitos
- Node.js 20+
- Flutter 3.19+
- PostgreSQL 15+

### Backend
```bash
cd backend
cp .env.example .env
# Editar .env con tus credenciales de PostgreSQL
npm install
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
npm run dev
# API corriendo en http://localhost:3000
```

### App Residente (Flutter Web)
```bash
cd frontend
flutter pub get
flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Copiar build/web/ al servidor SPA:
python3 -c "
import http.server, socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.path='/build/web'+self.path
        return super().do_GET()
socketserver.TCPServer(('',8080),H).serve_forever()
" &
# App en http://localhost:8080
```

### Panel Administrativo
```bash
cd admin
npm install
npm run dev
# Panel en http://localhost:3001
```

## Usuarios de Prueba (después de seed)

| Rol         | Email                        | Contraseña    |
|-------------|------------------------------|---------------|
| Admin       | admin@appsecurity.com        | password123   |
| Residente   | juan.perez@email.com         | password123   |
| Seguridad   | seguridad@lospinos.com       | password123   |
| Comité      | comite@lospinos.com          | password123   |

## Funcionalidades Implementadas

### App Residente
- **Control de portones** — 4 botones estilo beResident: Entrada, Salida, Peatonal, Botonera (mantener 2s)
- **Tokens QR para visitantes** — Generar, compartir y escanear tokens de acceso
- **Mis Visitantes** — Crear, editar, eliminar visitantes con código de acceso único
- **Bitácora de accesos** — Historial completo con filtros y búsqueda
- **Panel de Avisos** — Lectura de avisos de la administración
- **Pagos** — Pago con tarjeta vía **Stripe PaymentSheet**, historial, estado por pago y comprobante PDF (o receipt de Stripe)
- **Home estilo beResident** — Menú de navegación (Accesos, Avisos, Pago, Bitácora, Delegar)

### Panel Administrativo
- **Dashboard** — Vista general con estadísticas y actividad reciente
- **Gestión de Residentes** — Listado y detalle de residentes por unidad
- **Pagos** — Historial de pagos y estado de cuentas
- **Accesos** — Monitoreo de accesos activos y bitácora
- **Avisos** — Publicación de avisos a la comunidad
- **Configuración** — Ajustes del fraccionamiento

### Backend API
- Autenticación JWT con refresh tokens
- CRUD completo de residentes, unidades, pagos, accesos, visitantes
- Endpoints de portón: `/access/peatonal`, `/access/botonera`
- Validación con Zod y manejo de errores

## Endpoints Principales

```
POST   /auth/login          # Iniciar sesión
POST   /auth/register       # Registrar usuario
GET    /auth/me             # Obtener usuario actual
GET    /dashboard/overview  # Resumen del dashboard
POST   /access/resident-entry  # Registrar entrada residente
POST   /access/resident-exit   # Registrar salida residente
POST   /access/peatonal     # Abrir puerta peatonal
POST   /access/botonera     # Activar botonera
POST   /visitors            # Crear visitante (con token QR)
GET    /payments             # Listar pagos
POST   /payments/:id/stripe-intent  # Crear PaymentIntent de Stripe para un pago
POST   /payments/webhook/stripe     # Webhook de Stripe (payment_intent.succeeded/failed)
GET    /notices             # Listar avisos
```

## Pagos con Stripe

- **Checkout**: la app obtiene la *publishable key* desde `GET /config/stripe-config` y abre el **PaymentSheet** de `flutter_stripe` (Flutter Web vía `flutter_stripe_web` + Stripe.js).
- **Intento de pago**: `POST /payments/:id/stripe-intent` crea un PaymentIntent ligado al residente (Stripe Customer) con `metadata.paymentId`.
- **Webhook**: `POST /payments/webhook/stripe` recibe `payment_intent.succeeded` / `payment_intent.payment_failed`, actualiza el estado del pago (`COMPLETED` / `FAILED`), guarda `receiptUrl` del charge y registra la entrada contable (con dedupe por `reference`).
- **Recibo**: el residente puede descargar un comprobante PDF generado en el cliente (`pdf` + `printing`).

Para desarrollo local reenvía los webhooks de Stripe:
```bash
stripe listen --forward-to localhost:3000/api/v1/payments/webhook/stripe
# usa el whsec_ impreso en STRIPE_WEBHOOK_SECRET del backend/.env
```
Tarjeta de prueba: `4242 4242 4242 4242` (cualquier fecha futura, CVC cualquiera).

## Despliegue

### Docker
```bash
docker-compose up -d
```

### Variables de Entorno (Backend)
```env
DATABASE_URL="postgresql://user:pass@localhost:5432/appsecurity"
JWT_SECRET="tu-secreto-super-seguro"
JWT_REFRESH_SECRET="tu-refresh-secreto"
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
FRONTEND_URL="http://localhost:8080"
PORT=3000
```

## Roadmap

- [x] Pasarela de pagos integrada (Stripe checkout + webhooks)
- [ ] Reservas de amenidades
- [ ] Solicitudes de servicio e incidencias
- [ ] App SaaS para empresas (multi-colonia, contabilidad consolidada, cuadrillas)
- [ ] Notificaciones push (Firebase Cloud Messaging)
- [ ] Autometracción biométrica (huella/rostro)
- [ ] Integración con hardware IoT de caseta

## Licencia

MIT License

---

Desarrollado por [Carlos Martínez Mayorga](https://github.com/CarlosMtzMayorga)
