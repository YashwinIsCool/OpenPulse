# 03 — Security Research

**Mission:** Own the method — how we find real vulnerabilities (especially the
logic flaws scanners miss), prove them harmlessly, fix them, and confirm the fix
holds. This is the R&D core of the company.

## What this department owns
- The vulnerability discovery methodology for AI-built apps.
- The **harmless demonstration** standard: proving a hole is real without causing
  harm, touching real user data, or disrupting the app.
- The fix-generation approach and how fixes are validated.
- The taxonomy of what we look for, and the benchmark we measure ourselves by.

## Focus areas (where AI-built apps actually break)
1. **Broken authorization / logic flaws** — e.g. one user able to read or modify
   another user's data. The high-value frontier: scanners struggle with
   app-specific logic, and AI reasoning is newly good at it. Our wedge within the
   wedge.
2. **Exposed secrets** — API keys/credentials committed or shipped to clients.
3. **Open/unprotected data stores** — misconfigured databases, public buckets.
4. **Missing or broken authentication** — unprotected endpoints, weak sessions.
5. **AI-integration-specific risks** — prompt injection, leaked system prompts,
   over-permissioned tool access in the app's own AI features.

## Hard rules (from dept 08, enforced in dept 02)
- Test **only** authorized, in-scope targets with verified ownership.
- Demonstrations are **harmless and reversible** — never destructive, never
  exfiltrate real user data, never degrade the live service.
- Everything reproducible and logged.

## Current priorities (Phase 0)
1. Write the **harmless-demonstration standard** — our most important doc.
2. Build the **vulnerability taxonomy + severity model** for AI-built apps.
3. Define the **safe-fix validation protocol**: proving a fix closed the hole and
   broke nothing.
4. Draft the **benchmark** we'll use to measure (and later publicly prove) quality.

## Docs to create here
- `harmless-demonstration-standard.md` · `vulnerability-taxonomy.md` ·
  `safe-fix-validation-protocol.md`

## How it connects
Supplies methods to **Engineering** (02) and finding-content rules to **Product**
(01). Its benchmark results feed **Marketing** (05) once credible. Operates
strictly inside **Legal/Compliance** (08) boundaries.
