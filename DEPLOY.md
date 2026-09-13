# Guía de Despliegue - AppSecurity

## 🎯 Opciones Recomendadas (Más Fácil → Más Control)

---

## 1️⃣ Railway (Recomendado - Todo en uno, $5/mes)

### Backend + PostgreSQL + Frontend Web

```bash
# 1. Instalar CLI
npm i -g @railway/cli

# 2. Login y crear proyecto
railway login
railway init

# 3. Agregar PostgreSQL
railway add postgresql

# 4. Configurar variables en Railway Dashboard:
# DATABASE_URL (auto), JWT_SECRET, JWT_REFRESH_SECRET, FRONTEND_URL, STRIPE keys

# 5. Desplegar backend
railway up --service backend

# 6. Para frontend web (servicio estático):
# En Railway: New Service > GitHub Repo > frontend folder > Static Site
# Build command: flutter build web --release
# Output directory: build/web
```

**Ventajas**: PostgreSQL gestionado, SSL automático, logs, métricas, rollback fácil.

---

## 2️⃣ Render (Gratis para empezar)

### Backend (Web Service)
```yaml
# render.yaml en raíz
services:
  - type: web
    name: appsecurity-api
    runtime: docker
    dockerfilePath: ./backend/Dockerfile
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: appsecurity-db
          property: connectionString
      - key: JWT_SECRET
        generateValue: true
      - key: JWT_REFRESH_SECRET
        generateValue: true
      - key: FRONTEND_URL
        value: https://appsecurity-frontend.onrender.com
```

### PostgreSQL (Managed)
```yaml
databases:
  - name: appsecurity-db
    plan: free
```

### Frontend (Static Site)
```yaml
services:
  - type: web
    name: appsecurity-frontend
    runtime: static
    buildCommand: cd frontend && flutter build web --release
    staticPublishPath: ./frontend/build/web
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

---

## 3️⃣ Fly.io (Edge, $5/mes con VM)

```bash
# Backend
fly launch --dockerfile backend/Dockerfile
fly volumes create pg_data --size 3  # Para PostgreSQL local
# O usar postgres externo (Neon, Supabase)

# Configurar secrets
fly secrets set JWT_SECRET=... JWT_REFRESH_SECRET=... DATABASE_URL=... STRIPE_SECRET_KEY=...

# Desplegar
fly deploy

# Frontend (separado)
cd frontend
fly launch --dockerfile Dockerfile.web
fly deploy
```

---

## 4️⃣ Docker Compose (VPS - DigitalOcean, Hetzner, AWS EC2)

### En tu servidor (Ubuntu 22.04+)

```bash
# 1. Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Instalar Docker Compose
sudo apt install docker-compose-plugin

# 3. Clonar y configurar
git clone https://github.com/CarlosMtzMayorga/AppSecurity.git
cd AppSecurity

# 4. Crear .env.prod
cat > .env.prod << 'EOF'
DB_NAME=appsecurity
DB_USER=postgres
DB_PASSWORD=tu-password-seguro-aqui
JWT_SECRET=tu-jwt-secret-muy-largo-y-seguro
JWT_REFRESH_SECRET=tu-refresh-secret-muy-largo-y-seguro
FRONTEND_URL=https://tu-dominio.com
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
DOMAIN=tu-dominio.com
EOF

# 5. Certificados SSL (Let's Encrypt)
sudo apt install certbot
sudo certbot certonly --standalone -d tu-dominio.com
sudo mkdir -p /etc/nginx/ssl
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem /etc/nginx/ssl/
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem /etc/nginx/ssl/

# 6. Levantar
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# 7. Ver logs
docker compose -f docker-compose.prod.yml logs -f
```

---

## 5️⃣ Supabase + Vercel (Serverless)

### Base de Datos: Supabase (PostgreSQL gratis 500MB)
1. Crear proyecto en supabase.com
2. Copiar `DATABASE_URL` (Settings > Database)
3. Ejecutar migraciones: `npx prisma migrate deploy`

### Backend: Vercel (Serverless Functions)
```json
// vercel.json en backend/
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": null,
  "functions": {
    "dist/index.js": {
      "maxDuration": 30
    }
  }
}
```
```bash
vercel --prod
```

### Frontend: Vercel (Static)
```json
// vercel.json en frontend/
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "framework": "flutter",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

---

## 6️⃣ Kubernetes (Producción Enterprise)

```yaml
# k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: appsecurity-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: appsecurity-backend
  template:
    metadata:
      labels:
        app: appsecurity-backend
    spec:
      containers:
      - name: backend
        image: tu-registry/appsecurity-backend:latest
        ports:
        - containerPort: 3000
        envFrom:
        - secretRef:
            name: appsecurity-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: appsecurity-backend
spec:
  selector:
    app: appsecurity-backend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

---

## 🔧 Variables de Entorno Obligatorias

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET` | Firma access tokens (32+ chars) | `openssl rand -base64 32` |
| `JWT_REFRESH_SECRET` | Firma refresh tokens | `openssl rand -base64 32` |
| `FRONTEND_URL` | URL del frontend (CORS) | `https://app.tudominio.com` |
| `STRIPE_SECRET_KEY` | Stripe secret key | `sk_live_...` |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret | `whsec_...` |

**Generar secrets seguros:**
```bash
openssl rand -base64 32  # Para JWT_SECRET
openssl rand -base64 32  # Para JWT_REFRESH_SECRET
```

---

## 🗄️ Migraciones de Base de Datos

```bash
# En cualquier entorno, después de desplegar backend:
npx prisma migrate deploy

# Si es la primera vez:
npx prisma db push  # O migrate deploy

# Seed (solo desarrollo/staging):
npx tsx prisma/seed.ts
```

---

## 🔒 SSL/HTTPS

### Opción A: Let's Encrypt (Gratis) - Nginx
```bash
# En VPS con docker-compose
certbot certonly --standalone -d tu-dominio.com
# Renovar auto: certbot renew --quiet
```

### Opción B: Cloudflare (Proxy + SSL)
1. DNS en Cloudflare (naranja activado)
2. SSL/TLS: Full (Strict)
3. Page Rules: Always Use HTTPS

### Opción Gestionada: Railway/Render/Fly
- SSL automático incluido

---

## 📱 Build Apps Móviles (Android/iOS)

### Android (APK/AAB)
```bash
cd frontend
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
# Subir a Play Console
```

### iOS (IPA)
```bash
cd frontend
flutter build ios --release
# Abrir build/ios/Runner.xcarchive en Xcode
# Archive > Distribute App > App Store Connect
```

---

## 🧪 Health Checks & Monitoring

```bash
# Backend health
curl https://api.tudominio.com/health
# {"status":"ok","timestamp":"2024-01-15T10:30:00.000Z"}

# Ver logs
docker compose logs -f backend --tail 100

# Métricas básicas (añadir a backend)
# npm install prom-client
# Exponer /metrics para Prometheus/Grafana
```

---

## 🔄 CI/CD con GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Railway
        uses: railway/cli@v1
        with:
          command: up --service backend
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: cd frontend && flutter build web --release
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
```

---

## ✅ Checklist Pre-Despliegue

- [ ] `DATABASE_URL` apunta a PostgreSQL de producción
- [ ] `JWT_SECRET` y `JWT_REFRESH_SECRET` son únicos y seguros (32+ chars)
- [ ] `FRONTEND_URL` coincide con el dominio real (CORS)
- [ ] Stripe keys son de **producción** (`sk_live_`, no `sk_test_`)
- [ ] Webhook de Stripe configurado en Dashboard: `https://api.tudominio.com/api/v1/payments/webhook/stripe`
- [ ] Dominio apunta a la IP correcta (A record) o CNAME
- [ ] SSL certificado válido (Let's Encrypt o Cloudflare)
- [ ] `npm run prisma:generate` y `prisma migrate deploy` ejecutados
- [ ] Backup automático de PostgreSQL configurado
- [ ] Logs centralizados (Papertrail, Datadog, o Loki)

---

## 💰 Costos Estimados Mensuales

| Plataforma | Backend | DB | Frontend | Total |
|------------|---------|-----|----------|-------|
| Railway | $5 | Incluido | $5 | **$10** |
| Render | $7 | Free/7$ | Free | **$7-14** |
| Fly.io | $5 | $5 (volumen) | $5 | **$15** |
| VPS (Hetzner CX22) | - | - | - | **€4.50** |
| Supabase + Vercel | Free | Free (500MB) | Free | **$0** |

---

## 🆘 Troubleshooting Común

| Error | Solución |
|-------|----------|
| `P1001: Can't reach database` | Verificar `DATABASE_URL`, firewall, SSL mode |
| `CORS error` | `FRONTEND_URL` debe coincidir exactamente (incluir `https://`) |
| `JWT expired` | Verificar que `JWT_SECRET` sea igual en todos los pods |
| `Stripe webhook 400` | `STRIPE_WEBHOOK_SECRET` debe ser el del endpoint correcto |
| `flutter build web` falla | `flutter clean && flutter pub get && flutter build web` |
| `nginx 502` | Backend no está healthy, ver `docker compose logs backend` |

---

## 📞 Soporte

- Issues: [GitHub](https://github.com/CarlosMtzMayorga/AppSecurity/issues)
- Docs: [README.md](README.md)