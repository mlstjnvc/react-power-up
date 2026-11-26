---
tags: [trigger]
max_turns: 12
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this component for bugs and best practices:

```tsx
export function Counter({ start }: { start: number }) {
  const [count, setCount] = useState(start)
  useEffect(() => { setCount(start) }, [start])
  return <div onClick={() => setCount(count + 1)}>{count}</div>
}
```
