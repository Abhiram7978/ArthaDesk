/* ============================================================
   ArthaDesk Service Worker  v2.0
   Enables: PWA install + Offline cache
   ============================================================ */

const CACHE = 'arthadesk-v2';

const PRECACHE = [
  '/ArthaDesk-/',
  '/ArthaDesk-/index.html',
  '/ArthaDesk-/admin.html',
  '/ArthaDesk-/manifest.json',
  '/ArthaDesk-/admin-manifest.json',
  '/ArthaDesk-/sw.js',
  '/ArthaDesk-/icons/icon-192.png',
  '/ArthaDesk-/icons/icon-512.png',
  '/ArthaDesk-/icons/admin-192.png',
  '/ArthaDesk-/icons/admin-512.png',
];

/* ── INSTALL ─────────────────────────────────── */
self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(c => {
      return Promise.allSettled(
        PRECACHE.map(url => c.add(url).catch(() => {}))
      );
    })
  );
});

/* ── ACTIVATE ────────────────────────────────── */
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

/* ── FETCH — Network first, cache fallback ───── */
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  
  const url = new URL(e.request.url);
  
  // Skip cross-origin requests (Supabase API, Google Fonts, CDN)
  if (url.origin !== self.location.origin) return;

  e.respondWith(
    fetch(e.request)
      .then(res => {
        if (res && res.status === 200 && res.type !== 'opaque') {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      })
      .catch(() =>
        caches.match(e.request).then(cached => {
          if (cached) return cached;
          // For HTML navigation, serve index as fallback
          if (e.request.mode === 'navigate') {
            return caches.match('/ArthaDesk-/index.html');
          }
        })
      )
  );
});
