const CACHE = 'vending-refunds-v1';
const FILES = ['./', './index.html', './request.html', './firebase-config.js', './manifest.json'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (e) => {
  // Always go to the network for Firebase; fall back to cache for the app pages
  if (e.request.url.includes('firebase') || e.request.url.includes('googleapis')) return;
  e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
});
