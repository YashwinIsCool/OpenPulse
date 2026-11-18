# Outreach — the 20-authorized-test engine

**Goal:** get 20 owners of AI-built apps to agree **in writing** to a free,
authorized security test. This is Phase 0's critical path. Quality of consent
matters as much as volume — every yes must be a real owner authorizing a real
app they control (see Legal, dept 08).

**Offer that gets the yes:** *free* test + *free* verified fix for the first
batch, in exchange for honest feedback and (if they're happy) permission to ask
about paying next time. You're buying learning, not revenue, right now.

---

## Where to find them
- AI app-builder communities and showcase feeds ("I built this with [AI tool]").
- Indie-hacker / solo-founder spaces; "built in public" posters.
- X / LinkedIn / YouTube / TikTok creators posting AI-built apps.
- Relevant subreddits and Discords for the AI builder tools.
Pick people with a **live app that has real users or logins** — that's where the
interesting (logic/auth) holes live.

---

## Cold DM (short — for X / Discord / LinkedIn)
> Hey [name] — saw [specific app/post]. Nice build. I'm testing a tool that acts
> like a security engineer for apps built with AI tools: it checks for things like
> exposed keys or "user A can see user B's data," proves anything it finds, and
> writes you the fix. I'm doing it **free** for a first batch of 20 builders in
> exchange for feedback. Only on an app you own, only with your written OK, fully
> scoped. Want me to run it on [app]?

## Cold email (for when you have an address)
**Subject:** a free security check for [app]?

> Hi [name],
>
> I came across [app] — [one genuine specific detail]. Really like what you built.
>
> Quick context: apps built fast with AI tools often ship with security holes the
> builder can't easily see — exposed API keys, open databases, or logic bugs where
> one user can reach another user's data. Most new builders have no one to catch
> these.
>
> I'm building **[FixProof]**, which works like a security engineer for exactly
> these apps: it finds issues, **proves** each one is real (harmlessly — no data
> touched, nothing taken down), and sends you the **fix** to approve. Nothing is
> ever changed without you.
>
> I'm running it **free** for the first 20 builders in exchange for honest
> feedback. It's done only on an app you own, only with your written go-ahead, and
> only on the parts you approve.
>
> If you're open to it, reply "in" and I'll send a one-page authorization form
> (confirms you own it + what's in scope) and we'll get you a result in a few days.
>
> — [you]
>
> *I only test systems with the owner's written permission. You can withdraw
> anytime.*

## Follow-up (once, 3–4 days later)
> Hi [name] — circling back in case this slipped by. Still happy to run a free,
> fully-authorized security check on [app] and hand you fixes for anything I find.
> No pressure — just reply "in" or "not now."

---

## The reply flow (hand to GTM, dept 06)
1. They say "in" → send the **Authorization & Scope Agreement** (Legal, dept 08).
2. **Verify ownership** (confirm they control the domain/app/repo).
3. Agree scope in writing. Then — and only then — test.
4. Deliver findings + verified fix in plain English (Design's report format).
5. Debrief: *Was this useful? Would you have paid for it? What would you pay?*
   Log every answer in `06-GTM-Sales/customer-interviews.md`.

## What we're learning (not just selling)
For each conversation, capture:
- Did they already worry about this? How much?
- Did they ship with zero security review?
- Was the fix the thing they valued, or something else?
- Would they pay? How much? If no — is it the price, the user, or the problem?

## Guardrails
- Never test before written authorization and ownership verification. Ever.
- Never imply you already scanned their app ("I noticed you're vulnerable to…").
  You haven't, and it reads as a threat. Offer; don't ambush.
- Keep the free-batch promise honest: free means free.
