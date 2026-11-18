# 00 — Company / Executive

**Mission:** Make it so anyone who ships software — no matter how little security
they know — ships it safe, because an AI security engineer found, proved, fixed
and re-tested the holes for them.

**Vision (10-year):** FixProof is the default security layer of the AI-built
software era — the step every app builder and coding agent runs before launch.

## What this department owns
- Company vision, strategy, and the single current priority.
- Company-wide OKRs and the operating cadence (weekly review, monthly retro).
- Capital allocation and, crucially, saying **no** to expansion until the wedge
  is proven.
- Culture and the operating principles every department inherits.

---

## Strategy

### The thesis
AI writes software faster than anyone can verify it's safe. The scarce thing is
not finding bugs — it's **a fix the owner can trust, proven to close the hole
without breaking the app.** We sell that.

### The wedge
- **Product wedge:** verified fixes (not reports), via a closed loop —
  discover → prove with a harmless demonstration → fix as a pull request →
  re-test → confirm closed.
- **User wedge:** the builder who shipped an app with AI tools and has **no
  security skill**. They can't use a report; they can use a merge button.
- **Why not SaaS teams with 10–100 devs:** that's exactly where Aikido, Snyk and
  the incumbents already compete, and find-to-fix isn't a differentiator there.
  Our user is underserved *because* they're too small for incumbents to design for.

### The moat (what compounds)
1. **Safe-fix rate** — hard, measurable, and the entire pitch. Every test
   improves it and builds a data advantage competitors lack.
2. **Distribution via platforms** — becoming the embedded security step inside
   AI app builders / coding agents. The default wins volume.
3. **Trust + authorization infrastructure** — a verifiable consent/scoping system
   (dept 08) is the prerequisite to going upmarket, and most "move fast"
   competitors will under-build it.

### Phases (earn the right to expand)
- **Phase 0 — Validation (now):** No full platform. 20 authorized tests,
  semi-manual. Goal: ≥5 paying for fixes.
- **Phase 1 — Autonomous testing:** One connected app, authorized + isolated
  scope. Reliable discovery + verified findings with evidence.
- **Phase 2 — AI remediation:** Connect GitHub. Finding → investigate → fix →
  tests → pull request → re-test. **Human approval before anything ships. Never
  auto-deploy.**
- **Phase 3 — Continuous / embedded:** Every code change triggers checks; pursue
  embedding inside the AI builders and coding agents.

### Scope discipline (what we refuse now)
- No "connect your whole environment (GitHub + AWS + DB)" yet — earned in Phase 3.
- No enterprise push yet — wrong buyer for the wedge.
- No autonomous deployment, ever, without human approval.
- No testing without verified ownership and written authorization — hard line
  (dept 08).

### Primary risks & our answer
| Risk | Answer |
|------|--------|
| AI builders / labs bundle this free | Be measurably better at **safe fixes**; own the metric and the trust layer |
| Small builders pay little | Volume via free-score funnel → platform distribution; upmarket later on earned trust |
| A fix breaks a customer's app | Human-approved PRs, regression tests, isolated retest, rollback. Watch safe-fix rate like revenue |
| "Why would I let you attack my app?" | Verified ownership, tight scope, audit logs, evidence quality — from day one |
| Crowded discovery market | We lead with the fix, not discovery — the thing incumbents' buyers don't need but ours do |

### The one number
**Safe-fix rate.** High → we have a company. Not → nothing else matters.

---

## OKRs — Phase 0 (Validation)
Update status weekly in the Monday review.

**Objective 1 — Prove the problem is real and painful**
| Key result | Target | Status |
|------------|--------|--------|
| Owners of AI-built apps interviewed | 20 | ⬜ |
| Who call post-launch security a real worry | ≥12 of 20 | ⬜ |
| Who shipped with no security review at all | track % | ⬜ |

**Objective 2 — Prove we can deliver a verified fix**
| Key result | Target | Status |
|------------|--------|--------|
| Authorized apps tested (written consent, in scope) | 20 | ⬜ |
| Apps with ≥1 real, demonstrated vulnerability | ≥10 | ⬜ |
| **Safe-fix rate** (closed hole, broke nothing) | ≥80% | ⬜ |

**Objective 3 — Prove willingness to pay**
| Key result | Target | Status |
|------------|--------|--------|
| Owners who agreed to pay for the fix | ≥5 | ⬜ |
| Signed letters of intent / prepayments | ≥3 | ⬜ |
| Validated price point | 1 | ⬜ |

### Decision gate (end of Phase 0)
- **Go (build Phase 1):** ≥5 paying AND safe-fix rate ≥80%.
- **Pivot:** demand clear but wrong user/wedge — adjust, re-run.
- **Stop:** <5 paying and the "no"s are about the problem, not the prototype.

## How it connects
Sets the target **GTM** (06) executes, the metric **Security Research** (03) and
**Engineering** (02) optimize, and approves what **Product** (01) may put on the
roadmap this phase.
