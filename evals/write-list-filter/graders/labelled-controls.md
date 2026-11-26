---
type: llm
focus: { source: file, path: src/components/TaskList.tsx }
---

This is a React task list with a text filter, per-task checkboxes, delete controls and an expand control.

PASS if: the filter input has an accessible label (an associated `<label>`, or `aria-label`/`aria-labelledby`; a placeholder alone does not count); each checkbox is labelled (e.g. wrapped in a `<label>` with the task title, or `aria-label`); the delete and expand controls are `<button>` elements (with `type="button"`) whose accessible name identifies the task when the visible text is only an icon or a generic word; and event handlers are passed as functions (no `onClick={remove(task.id)}`).

FAIL if any form control lacks an accessible label, an action uses a non-button element with onClick, or a handler is called during render.
