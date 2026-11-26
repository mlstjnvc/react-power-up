---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a shopping cart with Zustand. Create the store in `src/stores/cart.ts`: cart lines (a `Product` from `src/types.ts` plus a quantity), actions to add a product, change a quantity and remove a line, and a way to get the cart total and the number of items. Then create `src/components/CartBadge.tsx` (shows the item count) and `src/components/CartPanel.tsx` (lists lines with quantity controls and remove buttons, and shows the total). Render both in `src/App.tsx`.
