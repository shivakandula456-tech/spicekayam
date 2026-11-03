# KAYAM SPICES — Mobile and PWA update

## Included in this update

- Added an installable web app manifest with KAYAM SPICES identity, app icons, standalone display mode, and Shop/Cart shortcuts.
- Added 192px, 512px, and maskable 512px application icons based on the existing KAYAM emblem.
- Added iOS home-screen metadata and `viewport-fit=cover` to all 11 public storefront pages.
- Added an install action in the shared mobile navigation drawer for browsers that expose the PWA install prompt.
- Added iPhone/iPad instructions for browser Share → Add to Home Screen.
- Added a service worker that precaches the public storefront shell, uses network-first page navigation, refreshes cached static assets, and provides an offline fallback screen.
- Improved mobile safe-area spacing, navigation touch targets, product-card actions, drawer scrolling, and short-landscape hero layout.
- The hero video pauses when it leaves the viewport or the app is backgrounded; reduced-motion and data-saver/slow-2G preferences use the matching poster instead of downloading video.
- Added online/offline connection notices.

## Install

**Android / Chromium browsers:** Open the deployed HTTPS website, open the navigation drawer, then use **Install KAYAM SPICES** when the browser offers installation.

**iPhone / iPad:** Open the website in the browser, open the navigation drawer, choose **How to add to Home Screen**, then follow the Share → Add to Home Screen instructions.

The service worker is registered relative to the website root so it supports the GitHub Pages project path `https://shivakandula456-tech.github.io/kayam-1/`.

## Offline behaviour and limits

- The app shell and public pages in the precache can open offline.
- The existing cart remains stored in browser storage.
- Live catalogue data, current prices and stock checks, Supabase authentication, image uploads, checkout, order submission, and WhatsApp hand-off require an internet connection.
- Large MP4 videos and external product photography are not precached to avoid consuming mobile storage. The local hero poster remains available as a fallback.
- This is an installable Progressive Web App (PWA), not a native Android/iOS application. Push notifications are not configured.

## Validation performed

- Manifest JSON parsed; all 3 declared icon assets exist.
- The service-worker precache list was checked against the actual files (54 entries; no missing files).
- All 11 public pages contain one manifest link, one theme-color declaration, one Apple touch icon link, and `viewport-fit=cover`.
- All local HTML `src` and `href` references resolve.
- All project JavaScript files and the service worker pass `node --check`.
- All 6 stylesheets parse without top-level CSS errors; mobile CSS braces are balanced.

## Still needs a real-device check

A full rendered-browser/device verification of the install prompt, standalone launch, offline loading, and iOS Safari behaviour still needs to be performed on the deployed HTTPS site in Android Chrome and iOS Safari. Live Supabase and checkout operations also remain dependent on the configured project and internet connection.
