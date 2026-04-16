/* ============================================================
   ArthaDesk Service Worker  v4.0
   IMPORTANT: Version bumped to force cache refresh on all devices
   Old cached files with wrong credentials will be deleted.
   ============================================================ */

const CACHE = 'arthadesk-v4';

/* Only cache static assets — NOT html files (they contain credentials) */
const PRECACHE = [
  '/ArthaDesk/icons/icon-192.png',
  '/ArthaDesk/icons/icon-512.png',
  '/ArthaDesk/icons/admin-192.png',
  '/ArthaDesk/icons/admin-512.png',
];

/* ── INSTALL ─────────────────────────────────── */
self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(c =>
      Promise.allSettled(PRECACHE.map(url => c.add(url).catch(() => {})))
    )
  );
});

/* ── ACTIVATE: delete ALL old caches ─────────── */
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => {
        console.log('[SW] Deleting old cache:', k);
        return caches.delete(k);
      }))
    ).then(() => self.clients.claim())
  );
});

/* ── FETCH ───────────────────────────────────── */
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;

  const url = new URL(e.request.url);

  // Always fetch from network for cross-origin (Supabase, CDNs)
  if (url.origin !== self.location.origin) return;

  // Always fetch HTML files fresh from network (contain credentials)
  if (url.pathname.endsWith('.html') || url.pathname.endsWith('/')) {
    e.respondWith(
      fetch(e.request).catch(() => caches.match(e.request))
    );
    return;
  }

  // For icons/assets: network first, cache fallback
  e.respondWith(
    fetch(e.request)
      .then(res => {
        if (res && res.status === 200) {
          caches.open(CACHE).then(c => c.put(e.request, res.clone()));
        }
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
