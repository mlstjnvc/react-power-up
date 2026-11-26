---
tags: [trigger]
max_turns: 12
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

Write a TanStack Query hook useInvoices(page) that fetches /api/invoices?page=N and keeps the previous page visible while the next one loads.
