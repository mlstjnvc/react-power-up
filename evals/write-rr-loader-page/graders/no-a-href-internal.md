---
type: regex
pattern: '<a\s[^>]*href=[\"''{]\s*[\"''`]?/'
match: not_contains
target: { source: file, path: src/routes/project.tsx }
---
