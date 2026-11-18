# 06 — Go-To-Market / Sales

**Mission:** Run the validation that decides whether FixProof is a company —
talk to real app owners, get authorized tests, and find out whether they'll pay
for a verified fix.

## What this department owns
- Customer development: the interviews and the authorized-test pipeline.
- Pricing experiments.
- The sales motion (self-serve-led, founder-sold at first).
- Letters of intent, prepayments, early contracts.
- The authorization intake — getting written, verified consent before any test
  (with Legal, dept 08).

## The Phase 0 play (this is the whole job right now)
1. **Recruit 20 owners of AI-built apps** who agree **in writing** to an
   authorized security test of an app they own.
2. **Verify ownership + scope** for each (dept 08's intake).
3. Run the find→prove→fix→re-test loop (Security Research + Engineering) and
   deliver each a **verified fix**.
4. **Ask for the sale.** Measure how many pay, what they'll pay, and why the
   others won't.
5. Report results against `00-Company.md` OKRs.

## Pricing to test (hypotheses, not decisions)
- **Free:** security score (the hook).
- **Paid per fix:** one-time price for a verified, merged fix.
- **Subscription:** continuous re-testing on every change.
Find the price where a non-expert builder says "yes, obviously" to remove a real
fear. Validate one, don't over-engineer the tiers yet.

## The gate
Hand Executive a clear read: **≥5 paying + safe-fix rate ≥80% = build Phase 1.**
Fewer, and we learn whether it's the user, the wedge, or the price.

## Docs to create here
- `customer-interviews.md` (log) · `authorized-test-pipeline.md` ·
  `pricing-experiments.md` · `objections-and-learnings.md`

## How it connects
Gets qualified leads + outreach from **Marketing** (05). Pulls delivery from
**Security Research** (03) + **Engineering** (02). Routes consent through
**Legal/Compliance** (08). Feeds the pay/price signal to **Product** (01) and the
go/stop read to **Executive** (00).
