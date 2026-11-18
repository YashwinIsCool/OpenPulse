# 01 — Product

**Mission:** Decide what we build and why, so engineering effort always lands on
the thing that moves the one metric (safe-fix rate) and the one goal (paying
customers).

## What this department owns
- The product roadmap, phase by phase (mirrors `00-Company.md`).
- Product requirement docs (PRDs) and specs.
- The user personas and the jobs they hire us for.
- Prioritization — including what is **not** on the roadmap this phase.
- The core loop as a product: discover → prove → fix → re-test → confirm.

## Primary persona (Phase 0)
**"The AI-tool builder."** Shipped a real, working app using AI coding/app-builder
tools. Technical enough to merge a pull request. **Not** security-literate — a
report is noise; a verified, explained fix is gold. Afraid of a breach or leak
but has no idea where to start.

## Current priorities (Phase 0)
1. **PRD for the validation loop** — the thinnest thing that takes an authorized
   app and returns proven findings + a fix. Semi-manual is fine.
2. Define what a **"finding"** must contain: evidence, severity, plain-English
   explanation, the fix, and the re-test result.
3. Define the **free security score** (funnel hook) vs. the **paid verified fix**
   (the product) — what's in each.
4. Spec the **human-approval checkpoint** — nothing ships without a merge.

## Docs to create here
- `PRD-validation-loop.md` · `personas.md` · `roadmap.md`

## How it connects
Takes phase + metric from **Executive** (00). Hands specs to **Engineering** (02)
and method requirements to **Security Research** (03). Gets pain + pricing signal
from **GTM** (06); feeds the funnel definition to **Marketing** (05). Works with
**Legal/Compliance** (08) so authorization is part of the product, not bolted on.
