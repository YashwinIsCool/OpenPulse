# 02 — Engineering

**Mission:** Build the platform that runs the find→prove→fix→re-test loop
reliably, safely, and with airtight authorization — and keep our own systems more
secure than anyone we test.

## What this department owns
- The FixProof platform: orchestration, the specialist agents, the fix pipeline.
- Integrations (starting with GitHub pull-request creation).
- Isolated, sandboxed testing environments and safe re-test infrastructure.
- Our own security, tenant isolation, secrets handling, audit logging.
- Reliability, rollback, and the regression tests that protect customers.

## Architecture principles
1. **Small team of coordinated, specialized agents + an orchestrator** — not a
   swarm of thousands. Quality of reasoning over agent count; the orchestrator
   dedupes findings and prevents conflicting or wasteful work.
2. **Everything scoped and authorized.** No agent acts outside the explicit,
   owner-authorized target. Scope is enforced in code, not policy alone.
3. **Prove, don't guess.** A finding ships only with a harmless, reproducible
   demonstration. No unverified scanner noise.
4. **Human approval before any change ships.** Fixes are pull requests. Never
   auto-deploy. Isolated retest → evidence → human merges.
5. **Rollback and regression tests** on every proposed fix.
6. **Audit everything.** Every action against a customer system is logged,
   attributable, reviewable.

## Current priorities (Phase 0 → 1)
1. **Semi-manual loop tooling** so one engineer can run an authorized test and
   produce a clean findings+fix package.
2. Design the **authorization + ownership-verification mechanism** with dept 08.
3. Prototype **GitHub PR creation** for a fix (read repo → propose patch → PR).
4. Define how **safe-fix rate** is measured and recorded automatically.

## Docs to create here
- `architecture.md` · `tech-stack.md` · `security-of-our-platform.md`

## How it connects
Builds to **Product** (01) specs using **Security Research** (03) methods.
Enforces **Legal/Compliance** (08) scope rules in the platform itself. Reports
the safe-fix metric to **Executive** (00).
