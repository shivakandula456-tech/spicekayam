/* KAYAM SPICES PWA service worker. Keep Supabase/API requests and video streams network-only. */
const CACHE_NAME = "kayam-spices-shell-v2-security";
const APP_SCOPE = new URL("./", self.registration.scope);
const PRECACHE = [
  "./", "./index.html", "./shop.html", "./product.html", "./cart.html", "./checkout.html",
  "./order-confirmation.html", "./story.html", "./contact.html", "./privacy.html", "./terms.html",
  "./404.html", "./offline.html", "./manifest.webmanifest",
  "./assets/css/tokens.css", "./assets/css/base.css", "./assets/css/components.css",
  "./assets/css/desktop.css", "./assets/css/mobile.css",
  "./assets/js/config.js", "./assets/js/supabase-client.js", "./assets/js/common.js",
  "./assets/js/whatsapp.js", "./assets/js/catalogue.js", "./assets/js/cart.js", "./assets/js/home.js",
  "./assets/js/cart-page.js", "./assets/js/checkout.js", "./assets/js/confirmation.js",
  "./assets/js/contact.js", "./assets/js/product.js", "./assets/js/shop.js",
  "./assets/vendor/supabase.js",
  "./assets/images/favicon.png", "./assets/images/apple-touch-icon.png",
  "./assets/images/app-icon-192.png", "./assets/images/app-icon-512.png", "./assets/images/app-icon-maskable-512.png",
  "./assets/images/kayam-wordmark.svg", "./assets/images/kayam-wordmark-light.svg",
  "./assets/images/kayam-monogram.svg", "./assets/images/kayam-logo-transparent.webp",
  "./assets/images/kayam-monogram-transparent.webp", "./assets/images/product-placeholder.svg",
  "./assets/images/hero-poster.webp", "./assets/images/hero-poster-mobile.webp",
  "./assets/images/kayam-spice-showcase-poster.webp",
  "./assets/fonts/cormorant-garamond-latin-400-normal.woff2",
  "./assets/fonts/cormorant-garamond-latin-500-normal.woff2",
  "./assets/fonts/cormorant-garamond-latin-600-normal.woff2",
  "./assets/fonts/cormorant-garamond-latin-400-italic.woff2",
  "./assets/fonts/manrope-latin-400-normal.woff2",
  "./assets/fonts/manrope-latin-500-normal.woff2",
  "./assets/fonts/manrope-latin-600-normal.woff2",
  "./assets/fonts/manrope-latin-700-normal.woff2"
];

self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    const requests = PRECACHE.map((path) => new Request(new URL(path, APP_SCOPE), { cache: "reload" }));
    await cache.addAll(requests);
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) => name.startsWith("kayam-spices-") && name !== CACHE_NAME).map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  // Large videos are deliberately network-only to avoid filling a phone's storage.
  if (request.destination === "video" || /\.mp4(?:$|\?)/i.test(url.pathname + url.search)) return;

  if (request.mode === "navigate") {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE_NAME);
      try {
        return await fetch(request);
      } catch (error) {
        const cached = await cache.match(request, { ignoreSearch: true });
        if (cached) return cached;
        const offline = await cache.match(new URL("./offline.html", APP_SCOPE));
        return offline || Response.error();
      }
    })());
    return;
  }

  if (["style", "script", "image", "font"].includes(request.destination)) {
    const refresh = caches.open(CACHE_NAME).then((cache) => fetch(request).then((response) => {
      if (response && response.ok && response.type === "basic") cache.put(request, response.clone()).catch(() => {});
      return response;
    }));
    // Extend the fetch event for the background refresh while returning any cached asset immediately.
    event.waitUntil(refresh.then(() => undefined).catch(() => undefined));
    event.respondWith((async () => {
      const cached = await caches.match(request);
      if (cached) return cached;
      try {
        return await refresh;
      } catch (error) {
        return Response.error();
      }
    })());
  }
});
