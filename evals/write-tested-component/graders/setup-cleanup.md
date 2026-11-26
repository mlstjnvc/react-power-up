---
type: regex
pattern: 'afterEach\s*\([\s\S]*cleanup|afterEach\s*\(\s*cleanup\s*\)'
target: { source: file, path: "src/test/setup.ts" }
---
REACT-TEST-010: the scaffold's Vitest config has no `globals: true`, so the setup file must register RTL `cleanup` in `afterEach`.
