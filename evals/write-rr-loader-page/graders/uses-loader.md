---
type: regex
pattern: '\bloader\b|\buseLoaderData\b|\bLoaderFunctionArgs\b|Route\.LoaderArgs'
target: { source: file, path: src/routes/project.tsx }
---
The page gets its data from a route loader. Accept any naming (`loader`, `projectLoader`, ...): the module either names `loader` or reads it with `useLoaderData` / loader arg types. Widened on 2026-11-25: a run whose final message described a loader failed `\bloader\b`, most likely because of a different function name (the run's files were not kept, so this is unconfirmed).
