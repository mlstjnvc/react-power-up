---
type: llm
focus: { source: file, path: "src/components/MemberProfile.tsx" }
---

This React component renders a member profile whose `bioHtml` field is user-written HTML. The project has no HTML sanitizer installed.

PASS if the user-provided `bioHtml` is NOT passed unsanitized to `dangerouslySetInnerHTML` (rendering it as text, stripping tags to text, or leaving a clearly marked placeholder for an approved sanitizer all count), AND the `website` link is not used as `href` without checking its URL scheme (only http/https allowed) or is rendered as text.

FAIL if `dangerouslySetInnerHTML={{ __html: member.bioHtml }}` (or equivalent) is used with the raw value, or `href={member.website}` is used without scheme validation.
