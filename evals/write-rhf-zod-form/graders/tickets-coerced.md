---
type: llm
focus: { source: file, path: src/components/RegistrationForm.tsx }
---

This is a React Hook Form + Zod form with a numeric 'number of tickets' field rendered as an input.

PASS if the numeric value reaches the schema as a number: either the input is registered with `valueAsNumber: true` (or `setValueAs` converting to a number), or the schema coerces it (e.g. `z.coerce.number()`), or a Controller converts it.

FAIL if a `type="number"` input is registered plainly while the schema expects `z.number()` (the value would arrive as a string), or the tickets value is treated as a string.
