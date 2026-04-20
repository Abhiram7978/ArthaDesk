/* ============================================================
   ArthaDesk Service Worker v5.0
   - Never caches HTML (always fresh from network)
   - Caches icons/assets for offline use
   - Handles skipWaiting for instant updates
   ============================================================ */

const CACHE = 'arthadesk-v5';

const PRECACHE = [
  '/ArthaDesk/icons/icon-72.png',
  '/ArthaDesk/icons/icon-96.png',
  '/ArthaDesk/icons/icon-128.png',
  '/ArthaDesk/icons/icon-144.png',
  '/ArthaDesk/icons/icon-152.png',
  '/ArthaDesk/icons/icon-192.png',
  '/ArthaDesk/icons/icon-384.png',
  '/ArthaDesk/icons/icon-512.png',
];

// Handle skipWaiting message from app
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
});

/* ── INSTALL ─────────────────────────────────── */
self.addEventListener('install', function(e) {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(function(c) {
      return Promise.allSettled(
        PRECACHE.map(function(url) { return c.add(url).catch(function() {}); })
      );
    })
  );
});

/* ── ACTIVATE: delete ALL old caches ─────────── */
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

/* ── FETCH ───────────────────────────────────── */
self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;
  var url = new URL(e.request.url);

  // Always fresh from network for cross-origin (Supabase, CDNs)
  if (url.origin !== self.location.origin) return;

  // Always fetch HTML fresh (contains credentials and app code)
  if (url.pathname.endsWith('.html') || url.pathname.endsWith('/')) {
    e.respondWith(
      fetch(e.request).catch(function() { return caches.match(e.request); })
    );
    return;
  }

  // Icons and static assets: network first, cache fallback
  e.respondWith(
    fetch(e.request).then(function(res) {
      if (res && res.status === 200) {
        var clone = res.clone();
        caches.open(CACHE).then(function(c) { c.put(e.request, clone); });
      }
      return res;
    }).catch(function() { return caches.match(e.request); })
  );
});
