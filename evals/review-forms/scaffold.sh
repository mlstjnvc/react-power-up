#!/usr/bin/env bash
# Next.js 16 App Router + React Hook Form + Zod 4, seeded with form anti-patterns (no node_modules, no git).
set -euo pipefail
mkdir -p app/signup lib
cat > package.json <<'JSON'
{ "name": "saas", "private": true, "dependencies": { "@hookform/resolvers": "^5.2.0", "next": "^16.0.0", "react": "^19.2.0", "react-dom": "^19.2.0", "react-hook-form": "^7.62.0", "zod": "^4.1.0" }, "devDependencies": { "@types/react": "^19.2.0", "typescript": "~5.9.0" } }
JSON
cat > lib/schemas.ts <<'TS'
import { z } from 'zod'
export const teamSchema = z.object({
  company: z.string().min(2),
  seats: z.number().int().min(1).max(500),
  members: z.array(z.object({ email: z.email() })).min(1),
})
export type TeamValues = z.infer<typeof teamSchema>
TS
cat > lib/db.ts <<'TS'
export declare const db: { team: { create(args: { data: unknown }): Promise<{ id: string }> } }
TS
# REACT-FORM-002 (Server Action trusts input; no schema parse)
cat > app/signup/actions.ts <<'TS'
'use server'
import { db } from '@/lib/db'
import type { TeamValues } from '@/lib/schemas'

export async function createTeam(values: TeamValues) {
  const team = await db.team.create({ data: values })
  return { id: team.id }
}
TS
# REACT-FORM-007 (index key in field array), REACT-FORM-008 (number input without coercion), REACT-FORM-005 (watch() of the whole form)
cat > app/signup/TeamForm.tsx <<'TSX'
'use client'
import { useFieldArray, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { teamSchema, type TeamValues } from '@/lib/schemas'
import { createTeam } from './actions'

export function TeamForm() {
  const { register, control, handleSubmit, watch, formState: { errors } } = useForm<TeamValues>({
    resolver: zodResolver(teamSchema),
    defaultValues: { company: '', seats: 1, members: [{ email: '' }] },
  })
  const { fields, append, remove } = useFieldArray({ control, name: 'members' })
  const values = watch()

  return (
    <form onSubmit={handleSubmit(async (v) => { await createTeam(v) })}>
      <label>Company <input {...register('company')} /></label>
      <label>Seats <input type="number" {...register('seats')} /></label>
      <p>Price: {values.seats * 12} €/month</p>
      {fields.map((field, index) => (
        <div key={index}>
          <label>Member email <input type="email" {...register(`members.${index}.email`)} /></label>
          <button type="button" onClick={() => remove(index)}>Remove</button>
        </div>
      ))}
      <button type="button" onClick={() => append({ email: '' })}>Add member</button>
      {errors.seats && <p>{errors.seats.message}</p>}
      <button type="submit">Create team</button>
    </form>
  )
}
TSX
