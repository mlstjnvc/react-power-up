---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a product detail page at `app/products/[id]/page.tsx` using the functions in `lib/products.ts`. Show the product name, price and description, a list of related products (linking to their pages), and the reviews (which are slow to load, so the rest of the page shouldn't wait for them). Add an "Add to cart" button with a quantity selector in `app/products/[id]/AddToCart.tsx` that keeps the quantity in local state and logs the product id and quantity for now. Show a not-found page for unknown ids.
