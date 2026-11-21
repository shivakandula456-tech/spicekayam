# KAYAM SPICES — Catalogue Photography Plan

**Status:** Provisional implementation  
**Visual direction:** Traditional Indian heritage photography  
**Scope:** Product catalogue cards and product detail imagery only. Homepage category thumbnails are explicitly out of scope and remain unchanged.

## Important audit limitation

The static fallback catalogue in `assets/js/catalogue.js` currently contains eleven products. This is a starting inventory only; it is not a verified count of published Supabase products.

The KAYAM SPICES Supabase project (`hbbrrmdxyhekocdmninc`) reported status `INACTIVE` on 21 November 2026. Live `products` and `product_images` records therefore could not be audited before this provisional update. No Supabase rows, storage objects, schema, or project settings were changed. Do not treat this plan as final approval of the live catalogue.

When Supabase is active, re-check published product rows and their image galleries. The current catalogue code prioritises non-empty `product_images` records over static fallback image paths, so changing fallback URLs alone does not replace stored live images.

## Photo-by-photo status

| # | Fallback product | Current action | Remaining requirement |
|---:|---|---|---|
| 1 | Chilli Powder | Updated fallback to Pexels photo 33440712 — powder in a bowl with dried chillies | Replace with a KAYAM product shoot when available |
| 2 | Turmeric Powder | Updated fallback to Pexels photo 6220707 — turmeric powder in rustic bowls | Replace with a KAYAM product shoot when available |
| 3 | Goda Masala | Existing contextual Indian spice-mix photo retained | Photograph actual Goda Masala; generic spice mix is not proof of this specific blend |
| 4 | Sambar Premix | Updated fallback to Pexels photo 7925765 — source page describes sambar powder | Confirm this accurately represents the actual KAYAM premix; a KAYAM product shoot is preferred |
| 5 | Rasam Premix | Existing generic spice-bowl image retained | Photograph actual Rasam Premix; current image is not product-specific |
| 6 | Chicken Masala | Existing curry serving image retained | Photograph the actual masala powder; a cooked curry is not a product image |
| 7 | Meat Masala | Existing meat-dish image retained | Photograph the actual masala powder; a cooked dish is not a product image |
| 8 | Biryani Masala | Existing spice-box image retained | Photograph the actual ground blend; whole spices in a box are only contextual |
| 9 | Garlic Podi | Existing garlic-preparation image retained | Photograph the finished garlic podi; ingredients in a mortar are not the finished product |
| 10 | Gunpowder Podi | Existing generic spice-powder image retained | Photograph the actual gunpowder podi. A Wikimedia Commons Idli podi photograph by Ravi Dwivedi is a possible CC BY-SA 4.0 candidate, but it is not deployed; assess visible attribution and ShareAlike requirements before use |
| 11 | Groundnut Chutney Powder | Existing whole-groundnut ingredient image retained | Photograph the finished groundnut chutney powder; whole peanuts are not the finished product |

The three changed fallback images are licensed under the Pexels licence. Pexels states that photos can be used for commercial projects without attribution, subject to the licence and third-party rights restrictions. Sources are recorded in `IMAGE_SOURCE_MANIFEST.md`.

## Art direction for the final KAYAM shoot

Use actual KAYAM batches as the subject. The product powder or premix must be the clear primary focus, presented in a restrained traditional Indian kitchen setting:

- Brass, bronze, copper, or unglazed earthen bowls; aged teak or natural stone surfaces.
- Soft, diffused daylight with warm, realistic colour and natural shadows.
- True-to-life powder colour, granularity, and texture. Do not add ingredients or garnish unless confirmed by the actual recipe.
- No invented KAYAM packaging, fabricated labels, competitor packaging, synthetic-looking ingredients, or AI-generated substitute product photographs.
- Capture one clean hero frame and one secondary serving/ingredient context frame per product.
- Keep enough negative space around the bowl for responsive crops. Capture high-resolution originals; crop for the existing catalogue layout only after checking desktop and mobile rendering.
- Write alt text that describes what is visibly present. Do not claim a stock/context image is the actual KAYAM pack or formula.

## Release checklist

- [ ] Restore/activate the KAYAM Supabase project only with owner approval if compute billing will resume.
- [ ] Audit every active product and all related `product_images` rows.
- [ ] Reconcile the live inventory against this eleven-item fallback list.
- [ ] Obtain the actual product photographs and verify each image against the corresponding product.
- [ ] Confirm product-image order, alt text, and storage paths.
- [ ] Update Supabase-backed images only after the live audit; retain the static fallback as a separate offline/demo path.
- [ ] Check shop cards, featured products, product detail galleries, and mobile crops.
- [ ] Confirm homepage category images remain unchanged.
