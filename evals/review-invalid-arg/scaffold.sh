#!/usr/bin/env bash
set -euo pipefail
export GIT_AUTHOR_NAME=Eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=Eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main
mkdir -p src
printf 'export function PageTitle({ title }: { title: string }) {\n  return <h1>{title}</h1>\n}\n' > src/PageTitle.tsx
printf '{ "name": "x", "private": true, "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" } }\n' > package.json
git add -A && git commit -qm "init"
