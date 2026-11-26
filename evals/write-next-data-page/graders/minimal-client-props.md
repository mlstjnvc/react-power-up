---
type: llm
focus: { source: file, path: "app/products/[id]/page.tsx" }
---

This is a Next.js App Router Server Component page that renders a client component `AddToCart`.

PASS if the props passed to the client component are plain serializable data and limited to what it needs (for example the product id, maybe name/price/stock), and the page does not pass functions (other than Server Actions) or the full product object including internal fields like `supplierCost`.

FAIL if it passes a non-serializable prop (a regular function, class instance) or spreads/passes the whole product record including `supplierCost` to the client component.
