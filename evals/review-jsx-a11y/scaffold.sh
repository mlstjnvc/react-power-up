#!/usr/bin/env bash
# React 19 SPA seeded with JSX and a11y anti-patterns (no node_modules, no git).
set -euo pipefail
mkdir -p src/components
printf '{ "name": "inbox", "private": true, "type": "module", "dependencies": { "react": "^19.2.0", "react-dom": "^19.2.0" }, "devDependencies": { "@types/react": "^19.2.0", "typescript": "~5.9.0" } }\n' > package.json
cat > src/types.ts <<'TS'
export interface Message { id: string; from: string; subject: string; read: boolean }
TS
# JSX-001 index key on a removable list, JSX-002 length &&, JSX-003 clickable div, JSX-007 handler called during render
cat > src/components/Inbox.tsx <<'TSX'
import { useState } from 'react'
import type { Message } from '../types'

export function Inbox({ initial }: { initial: Message[] }) {
  const [messages, setMessages] = useState(initial)
  const unread = messages.filter((m) => !m.read)

  function remove(id: string) {
    setMessages((prev) => prev.filter((m) => m.id !== id))
  }

  return (
    <section>
      {unread.length && <p>{unread.length} unread</p>}
      <ul>
        {messages.map((m, index) => (
          <li key={index}>
            <input type="text" defaultValue={m.subject} />
            <span>{m.from}</span>
            <div className="trash" onClick={() => remove(m.id)}>🗑</div>
            <button onClick={remove(m.id)}>Archive</button>
          </li>
        ))}
      </ul>
    </section>
  )
}
TSX
