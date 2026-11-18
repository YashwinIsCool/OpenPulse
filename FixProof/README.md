# FixProof

> **FixProof** (working name — rename anytime) is an **autonomous AI security
> engineer for software built with AI tools**. A builder connects their app;
> FixProof safely and with explicit, written authorization probes it for real
> vulnerabilities, proves each one with a harmless demonstration, writes a code
> fix, opens a pull request for a human to approve, and re-tests to confirm the
> hole is closed.
>
> **Defensive security only.** FixProof tests a system **only** with the owner's
> verified, written authorization and within an agreed scope. See
> `08-Legal-Compliance.md`.

---

## Why this company exists
AI tools now write software faster than anyone can check whether it's safe to
ship. Generating code is cheap; knowing it's secure is the bottleneck. A huge,
growing population ships real apps built with AI tools and has **nobody** who
understands security. They can't read a vulnerability report — so a list of
findings is useless to them. **What's valuable is a verified fix.** That's the wedge.

The enterprise AI-pentest players (XBOW, Horizon3, Pentera, Aikido, Escape) are
built for companies that already have security teams. Our customer is the
opposite: the solo builder and small team with no security skill at all.

**Long game:** become the **built-in security step inside the AI app builders
and coding agents themselves**, so every app they generate passes through
FixProof before launch — the infrastructure layer everyone building on AI needs.

## Our one defensible edge
**The share of fixes that close the hole without breaking the app** — the
*safe-fix rate*. Everything we build serves that number, and it's the whole pitch.

---

## How this folder works (departments)
This folder is the company's operating system. Each numbered file is a
**department** with its mission, what it owns, and its current priorities.

**Work it like a real company:** open **one chat per department** in the Claude
app, and in that chat point me at the matching file (e.g. "work in
`FixProof/05-Marketing.md`"). Each chat stays focused on that department's
mandate, the way a real team has separate rooms sharing one strategy.

| File | Department | Owns |
|------|------------|------|
| `00-Company.md` | Company / Executive | Vision, strategy, OKRs, the current priority |
| `01-Product.md` | Product | Roadmap, specs, what we build and why |
| `02-Engineering.md` | Engineering | The platform, architecture, our own security |
| `03-Security-Research.md` | Security Research | The find→prove→fix→retest method |
| `04-Design.md` | Design | Product UX, the report/fix experience, brand |
| `05-Marketing.md` | Marketing | Brand, content, demand, the free-score funnel |
| `06-GTM-Sales.md` | Go-To-Market / Sales | Customer development, pricing, the 20-interview test |
| `07-Operations-Finance.md` | Operations / Finance | Model, fundraising, hiring, entity, tooling |
| `08-Legal-Compliance.md` | Legal / Compliance | Authorization framework, data handling, rules of engagement |

## Operating principle (how big tech actually started)
Big companies started with **one wedge, one user, one metric**, and earned the
right to expand:
1. **One wedge:** verified fixes for AI-built apps.
2. **One user:** the builder with no security skill.
3. **One metric:** safe-fix rate.
4. **Earn expansion:** widen scope only after the wedge is proven.

**Current phase: Phase 0 — Validation.** We don't build the full platform yet.
We prove demand first. Details in `00-Company.md`.

---
*Internal planning workspace. Nothing here is a public claim, a security
assessment of any real system, or legal advice.*
