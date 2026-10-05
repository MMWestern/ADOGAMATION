// Service worker for the Idea Capture PWA.
// Cache-first for static assets, network-first for API calls.
// Local draft recovery is handled by localStorage in the app, not here.

const CACHE_NAME = 'idea-capture-v2';
const STATIC_ASSETS = [
  '/mobile.html',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png'
];

self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (key) { return key !== CACHE_NAME; })
            .map(function (key) { return caches.delete(key); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function (event) {
  var url = new URL(event.request.url);

  // API calls: network-first, fall back to cache.
  if (url.pathname.startsWith('/api/') || url.hostname.indexOf('supabase') !== -1) {
    event.respondWith(
      fetch(event.request).catch(function () {
        return caches.match(event.request);
      })
    );
    return;
  }

  // HTML and JS (the app shell): network-first so a normal refresh always
  // picks up the latest code. Cache-first was leaving stale markup and scripts
  // in place after deploys — only a hard refresh bypassed the service worker.
  if (event.request.mode === 'navigate' || url.pathname.endsWith('.html') || url.pathname.endsWith('.js')) {
    event.respondWith(
      fetch(event.request).then(function (response) {
        if (response.ok && event.request.method === 'GET') {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function (cache) {
            cache.put(event.request, clone);
          });
        }
        return response;
      }).catch(function () {
        return caches.match(event.request);
      })
    );
    return;
  }

  // Images, fonts, icons: cache-first (they rarely change and are safe to reuse).
  event.respondWith(
    caches.match(event.request).then(function (cached) {
      return cached || fetch(event.request).then(function (response) {
        if (response.ok && event.request.method === 'GET') {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function (cache) {
            cache.put(event.request, clone);
          });
        }
        return response;
      });
    })
  );
});
