# 08 — Legal / Compliance

**Mission:** Make FixProof trustworthy and lawful by design. We test systems that
people own, only with their verified written permission, only within an agreed
scope. This department is not a formality — for a security company it is the
product's foundation and a core part of the moat.

> This file is internal planning, **not legal advice.** Before any real test of a
> system we don't own, and before incorporation or contracts, a qualified lawyer
> in the relevant jurisdiction reviews the authorization framework.

## What this department owns
- **The rules of engagement** every other department must obey.
- The authorization + ownership-verification framework.
- Data handling and privacy (we may encounter real user data — how we don't
  touch, store, or leak it).
- Customer terms of service, authorization agreements, and disclaimers.
- Responsible-disclosure posture and incident handling.

## Rules of engagement (non-negotiable — inherited by depts 02, 03, 06)
1. **Authorization first.** No scanning, probing, or testing of any system
   without the owner's **explicit, written** authorization. No exceptions, no
   "just a quick look."
2. **Verify ownership / right to authorize.** Confirm the person authorizing
   actually controls the target (domain/app/repo verification) and has the right
   to consent. Keep the record.
3. **Scope is a contract.** Only the assets, domains, and endpoints named in the
   authorization are in scope. Everything else is off-limits, enforced in code.
4. **Harmless by construction.** Demonstrations never destroy data, never
   exfiltrate real user data, never degrade the live service. Prefer staging;
   where production is unavoidable, minimize and log.
5. **Human approval before any change ships.** We propose fixes as pull requests;
   a human merges. We never deploy to anyone's system autonomously.
6. **Least privilege + isolation.** The platform never holds more access than the
   scope needs; tenants are isolated; secrets are protected.
7. **Full audit trail.** Every action against a customer system is logged and
   attributable.
8. **Right to withdraw.** The owner can revoke authorization at any time; testing
   stops immediately.

## Data we might touch
If a test surfaces real user data (that's often *how* you prove an authorization
flaw), we **demonstrate the access without copying or exposing the data**, record
only what's needed to prove and fix it, and purge on a defined schedule. The
privacy policy must say exactly this.

## Current priorities (Phase 0)
1. Draft the **Authorization & Scope Agreement** every validation customer signs
   before a test (the intake GTM, dept 06, runs).
2. Draft the **ownership-verification steps** (how we confirm they control the
   target).
3. Draft the **harmless-testing + data-handling policy** (with Security Research,
   dept 03).
4. Flag what needs a **real lawyer** before we test a system we don't own or take
   a dollar.

## Docs to create here
- `rules-of-engagement.md` · `authorization-agreement-DRAFT.md` ·
  `data-handling-policy.md` · `legal-open-questions.md`

## How it connects
Sets hard boundaries for **Security Research** (03), **Engineering** (02), and
**GTM** (06). Partners with **Operations/Finance** (07) on entity and terms.
Reports legal risk to **Executive** (00).
