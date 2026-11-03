# KAYAM SPICES — Asset Link Repair Notes

This package repairs local asset references for the supplied website source.

## Asset wiring completed

- The supplied root `hero (2).mp4` is now wired as `assets/videos/kayam-hero.mp4`.
- A mobile 9:16 crop of that hero footage is included at `assets/videos/kayam-hero-mobile.mp4`.
- Matching desktop and mobile still posters are included as `assets/images/hero-poster.webp` and `assets/images/hero-poster-mobile.webp`.
- The spice-film section uses the supplied portrait `assets/videos/kayam-spice-showcase.mp4` and its local poster `assets/images/kayam-spice-showcase-poster.webp`.
- Header/footer wordmark SVGs and the admin monogram SVG now use the supplied transparent KAYAM monogram, embedded so there are no extra nested image paths.
- Admin screens use the supplied transparent monogram WebP rather than missing JPG/SVG filenames.
- A local `product-placeholder.svg` was added because storefront and admin code already referenced it, but it was absent from the ZIP.
- Open Graph and admin background references were switched from missing `hero-poster.jpg` files to the generated `hero-poster.webp`.
- The supplied `logo.jpeg` is retained as `assets/images/kayam-logo-original.jpeg`; the linked header/footer logo uses the transparent WEBP mark. The supplied `hero (2).mp4` is retained byte-for-byte as `assets/videos/kayam-hero.mp4`.

## Design direction

The main hero, announcement and navigation use charcoal; shopping surfaces remain ivory; forest green remains a heritage accent; antique gold remains the principal accent.

## Image delivery notes

The supplied ZIP contains the KAYAM logo, hero posters and the two video subjects, but it does not contain individual product pack photographs. Existing catalogue and category photography therefore still uses the Pexels CDN mappings in `assets/js/catalogue.js` and `assets/js/home.js`; those images need an internet connection. The image error handler now removes failed `srcset` candidates and uses the local brand-consistent placeholder instead of showing a broken-image icon. Replace the temporary food/ingredient images with approved KAYAM package photography when available.

## Before live ordering

The source still depends on the configured Supabase project, database schema/policies, an enabled administrator account, and confirmed product data. This asset repair does not test a real customer order, stock reservation, payment or admin login against the live database.

## Local test

From the extracted project root, run `py -m http.server 8000` and open `http://localhost:8000`. Check desktop and mobile hero video playback, the spice-film video, product/category images, cart navigation, contact links and admin login page. The mobile hero is a centre-cropped portrait derivative of the supplied 16:9 hero footage.


## Source checks after asset repair

- Local `src`, `href`, `poster`, `srcset`, inline-style and CSS `url()` references were checked. No unresolved local file references remain; the only apparent CSS hit was the `#n` fragment inside an inline SVG noise data URI, not a file path.
- `node --check` passed for all 21 application JavaScript files.
- CSS brace-balance checks passed for all 6 stylesheets.
- The new wordmark, monogram and product placeholder SVG files were parsed and rasterized successfully.
- Video metadata was checked: supplied desktop hero is 1280×720, the generated mobile crop is 540×960, and the existing spice film is 480×854.
- A rendered Chromium browser pass could not be completed in this environment because local browser navigation was blocked with `ERR_BLOCKED_BY_ADMINISTRATOR`. Live Supabase checkout/admin integration was not exercised.
