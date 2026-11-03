# KAYAM SPICES — HTTPS and browser security hardening

## Applied in this package

- Added an early Content Security Policy to every HTML page. It allows only same-origin scripts plus the one existing inline JavaScript bootstrap by SHA-256 hash; local CSS/scripts/fonts/media; Pexels product/story images; and the configured Supabase project for API, storage, and realtime connections.
- Disabled plugin/object content and embedded frames, restricted form submissions and base URLs to this site, and enabled `upgrade-insecure-requests`.
- Added a strict-origin-when-cross-origin referrer policy.
- Marked admin, cart, checkout, and order-confirmation pages `noindex` to reduce accidental search indexing. This is not authentication or access control.
- Bumped the PWA cache version so updated policies and assets replace the previous cached shell. The service worker continues to leave cross-origin API requests and video streams network-only.
- Rechecked the HTML files for literal HTTP network resources. The remaining `http://` strings are SVG/XML namespace identifiers and data-URI content, not insecure network requests.

## HTTPS on GitHub Pages — owner action required

The site uses the `github.io` hostname, which GitHub Pages serves over HTTPS. To ensure HTTP visitors are redirected to HTTPS, open:

`https://github.com/shivakandula456-tech/kayam-1/settings/pages`

Under **GitHub Pages**, enable **Enforce HTTPS** (if it is not already enabled). I could not read or change this Pages-specific setting through the available GitHub connection. After the next deployment, verify that `http://shivakandula456-tech.github.io/kayam-1/` redirects to `https://shivakandula456-tech.github.io/kayam-1/`.

## GitHub Pages security-header limitation

GitHub Pages does not provide a supported `_headers` or `.htaccess` mechanism for custom HTTP response headers. A CSP meta policy can enforce most resource-loading restrictions, but it cannot provide header-only protections such as HSTS, `X-Frame-Options`, `X-Content-Type-Options`, or CSP `frame-ancestors`. Do not add a `_headers` file expecting GitHub Pages to apply it. For those protections, use a hosting/proxy platform that supports response headers (for example, Cloudflare Pages/Workers) or another host with header configuration.

## Supabase and application security still required

- The `sb_publishable_...` key in `assets/js/config.js` is a public browser key, not a secret. Never place a Supabase `service_role` or secret key in this repository.
- Supabase Row Level Security (RLS) and storage policies must enforce access on the server. Hiding admin links or marking admin pages `noindex` does not secure data.
- I did not have access to the Supabase project policies, so RLS, storage bucket permissions, password policy, and admin role assignment remain unaudited.
- Keep checkout/order operations behind authenticated, validated database policies or trusted server-side functions; do not rely on front-end checks alone.

## Validation performed

- Checked all HTML pages contain the policy before resource links/scripts.
- Verified the inline bootstrap hash matches the source exactly.
- Confirmed there are no external HTTP asset/API URLs in HTML, JS, or CSS (excluding namespace declarations embedded in SVG/data content).
- JavaScript syntax checks and ZIP integrity checks were run after the changes.
- A live TLS handshake/header scan could not be completed from this execution environment, so certificate chain, redirect status, and deployed response headers are not independently attested here.
