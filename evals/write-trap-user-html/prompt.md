---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/MemberProfile.tsx` that shows a `Member` (from `src/types.ts`): their name, a link to their website, and their bio. Members write their bio in a rich-text box on their settings page, and it's stored as HTML in `bioHtml`, so just render that HTML with `dangerouslySetInnerHTML` so their formatting shows up.
