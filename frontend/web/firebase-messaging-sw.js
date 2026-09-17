// Service Worker para Firebase Cloud Messaging (Web Push) — AppSecurity Flutter Web.
//
// IMPORTANTE: reemplaza FIREBASE_CONFIG por la configuración web de tu proyecto
// Firebase (debe coincidir con la que devuelve GET /config/messaging del backend
// y con las variables FIREBASE_API_KEY / AUTH_DOMAIN / PROJECT_ID / ... del .env).
// Los valores deben ir en comillas simples o JSON válido.
//
// Para desplegar con tu propia config también puedes:
//   cp web/firebase-config.example.json web/firebase-config.json
// y el service worker la usará automáticamente (si existe, tiene prioridad).

var FIREBASE_CONFIG = {
  apiKey: '',
  authDomain: '',
  projectId: '',
  storageBucket: '',
  messagingSenderId: '',
  appId: '',
};

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      try {
        const res = await fetch('firebase-config.json', { cache: 'no-cache' });
        if (res.ok) {
          const cfg = await res.json();
          if (cfg && cfg.projectId) FIREBASE_CONFIG = cfg;
        }
      } catch (e) {
        // sin firebase-config.json, se usa FIREBASE_CONFIG de arriba.
      }

      firebase.initializeApp(FIREBASE_CONFIG);
      const messaging = firebase.messaging();

      messaging.onBackgroundMessage((payload) => {
        const data = payload.data || {};
        const route = data.route || '/notices';
        const notification = payload.notification || {};
        self.registration.showNotification(notification.title || 'AppSecurity', {
          body: notification.body || '',
          icon: 'icons/Icon-192.png',
          badge: 'icons/Icon-192.png',
          data: { route },
        });
      });

      self.skipWaiting();
    })()
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const route = (event.notification.data && event.notification.data.route) || '/notices';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.postMessage({ type: 'FLUTTER_NOTIFICATION_CLICK', route });
          return client.focus();
        }
      }
      return self.clients.openWindow(route);
    })
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'NOTIFICATION_CLICKED') {
    event.waitUntil(self.clients.openWindow(event.data.route || '/notices'));
  }
});