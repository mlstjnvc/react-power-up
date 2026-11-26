#!/bin/sh
# Coexistence check (A16): with react-power-up AND vue-power-up loaded, each prompt
# must fire exactly the expected main skill and never the other one.
#
#   sh tests/coexistence.sh [path/to/vue-power] [name-filter]
#
# Needs `claude` on PATH and network. Each prompt is one headless run (~$0.2) in an
# empty temp dir, tools limited to Read/Glob/Grep/Skill (nothing is written).
set -u
REACT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VUE_DIR=${1:-"$HOME/projects/vue-power"}
FILTER=${2:-}
[ -f "$VUE_DIR/.claude-plugin/plugin.json" ] || { echo "vue-power-up not found at $VUE_DIR"; exit 2; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

fail=0; total=0
check() { # name expected-skill prompt
  case "$1" in *"$FILTER"*) ;; *) return ;; esac
  total=$((total + 1))
  mkdir -p "$WORK/$1"
  (cd "$WORK/$1" && claude -p --plugin-dir "$REACT_DIR" --plugin-dir "$VUE_DIR" \
      --allowedTools "Read,Glob,Grep,Skill" --max-turns 6 \
      --output-format stream-json --verbose "$3" < /dev/null > trace.jsonl 2> err.log)
  fired=$(python3 -I - "$WORK/$1/trace.jsonl" <<'PY'
import json, sys
out = []
for line in open(sys.argv[1]):
    try: d = json.loads(line)
    except ValueError: continue
    m = d.get("message")
    if isinstance(m, dict) and isinstance(m.get("content"), list):
        for c in m["content"]:
            if isinstance(c, dict) and c.get("type") == "tool_use" and c.get("name") == "Skill":
                s = str(c.get("input", {}).get("skill", ""))
                if s.endswith("power-up"): out.append(s.split(":")[-1])
print(",".join(sorted(set(out))) or "none")
PY
)
  if [ "$fired" = "$2" ]; then echo "PASS $1: $fired"; else echo "FAIL $1: expected $2, fired $fired"; fail=$((fail + 1)); fi
}

check vue-component   vue-power-up   'Write a Vue 3 component with <script setup lang="ts"> that shows a paginated table of invoices with sortable columns.'
check nuxt-page       vue-power-up   "Create a Nuxt 4 page at pages/invoices/[id].vue that loads an invoice with useFetch and shows a 404 when it's missing."
check pinia-store     vue-power-up   'Write a Pinia setup store for a shopping cart with add, remove and a total getter, in TypeScript.'
check vue-composable  vue-power-up   'Write a composable useDebounce(value, delay) in TypeScript that returns a debounced ref.'
check vue-query       vue-power-up   'Write a composable useInvoices(page) with @tanstack/vue-query that fetches /api/invoices?page=N.'
check react-component react-power-up 'Write a React component in TypeScript that shows a paginated table of invoices with sortable columns.'
check next-action     react-power-up 'Write a Next.js Server Action that saves a contact form (name, email, message) and shows validation errors on the form.'
check tanstack-hook   react-power-up 'Write a TanStack Query hook useInvoices(page) that fetches /api/invoices?page=N and keeps the previous page visible while the next one loads.'
check python          none           "Write a Python function that reads a CSV file and returns the average of the 'price' column."

echo "$((total - fail))/$total correct"
[ "$fail" -eq 0 ]
