// sw.js - Service Worker para soporte Offline en LEVEL UP
const CACHE_NAME = 'levelup-cache-v3';
const ASSETS = [
    './',
    './index.html',
    './manifest.json',
    './styles.css',
    './db.js',
    './app.js',
    './rpg.js',
    './missions.js',
    './skills.js',
    './assets/icon-192.png',
    './assets/icon-512.png',
    './assets/logo.jpg'
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            console.log('Cacheando archivos de la app...');
            return cache.addAll(ASSETS).catch(err => {
                console.warn('Algunos archivos opcionales no se pudieron cachear en la instalación:', err);
            });
        })
    );
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys.map((key) => {
                    if (key !== CACHE_NAME) {
                        console.log('Borrando cache antiguo:', key);
                        return caches.delete(key);
                    }
                })
            );
        })
    );
});

self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request).then((cachedResponse) => {
            if (cachedResponse) {
                // Retornar de la caché, pero actualizar en segundo plano (stale-while-revalidate)
                fetch(event.request).then((networkResponse) => {
                    if (networkResponse.status === 200) {
                        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, networkResponse));
                    }
                }).catch(() => {/* Ignorar errores de red en segundo plano */});
                
                return cachedResponse;
            }
            return fetch(event.request).catch(() => {
                // Fallback offline para navegación HTML
                if (event.request.headers.get('accept').includes('text/html')) {
                    return caches.match('./index.html');
                }
            });
        })
    );
});
