---
type: llm
focus: { source: file, path: src/components/RegistrationForm.tsx }
---

PASS if validation errors are associated with their inputs for assistive technology: invalid inputs get `aria-invalid`, and error messages are connected with `aria-describedby` (or the message is inside the label / uses `role="alert"` next to its labelled field). Every input has an accessible label.

FAIL if error messages are plain text with no `aria-invalid` on the inputs, or inputs lack labels.
