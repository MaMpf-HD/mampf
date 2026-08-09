# Roadmap

```admonish info "Last reconciled: 2026-08-09"
Against the working tree, `next`, and the open pull requests — not against the
other planning chapters. Those describe what was intended and are still worth
reading for that; this one describes what is left.

To reconcile it again: take each entry, find the model or controller it names,
and check `git log -S` for it. Where an entry points at a pull request, check
whether that pull request has moved.
```

The [Implementation Plan](plan.md), the [PR Roadmap](implementation-prs.md) and
the [Parallelization Strategy](parallelization.md) were written before any of
this existed. They drifted, in two ways worth naming so this chapter does not
drift the same way.

They **name files**. Every migration filename in the PR roadmap is now wrong,
because timestamps moved when the work was actually done. This chapter names
models and controllers instead; those survive a rebase.

And they know only two states, **planned** and **done**. Most of what is left is
neither: the code is written, it sits in a pull request, and it is waiting for a
person. An entry that says "planned" for three months while a branch rots is
worse than no entry, because it hides the real blockage. Every entry below
therefore ends with what it waits on, and whether that is code or a decision.

```admonish tip "Roles, not names"
Entries say *a reviewer*, not who. Naming makes a document age badly and read as
an accusation; the pull request already carries the names. If your team prefers
names, swap them in — the point is that the waiting is visible either way.
```

---

## Now — close the chain

Nothing in the merged tree writes a point. Every point in the system comes from
`lib/demo`. Grade schemes, performance records and the whole eligibility chain
run, but only ever on seeded data. Until that is fixed, everything downstream is
built on a floor nobody has stood on.

### 1 · Merge the Müsli integration

**Blocked until this lands** — every other Müsli entry, which either builds on it
or conflicts with it.

**Where it is** — PR #1211. The five former slices in one branch, with the
Playwright suite for the assessment area and its own round of review.

**What it needs** — a merge. One end-to-end spec is red for a reason that
predates the branch (see [CI health](#ci-health)); say so in the description
rather than leaving a reviewer to find it.

**Waiting on** — a decision to merge.

### 2 · Point entry

**Blocked until this lands** — the read-only point grid, the grade scheme
pipeline, and the performance and eligibility chain are all fed by hand-entered
points that no interface can produce.

**Where it is** — PR #1150, open since May, code complete. Every review thread on
it is a bot or the author.

**What it needs** — retargeting onto the integration branch, which is also what
makes CI run for the first time: the test workflow fires for pull requests based
on `main` or `next` only, and this one targets a slice branch. Then a duplicate
`note` migration to drop (the integration branch folded that column into the
create-table migration), a rolled-back schema version to fix, and a human
review.

**Waiting on** — a reviewer.

### 3 · Grade entry

**Blocked until this lands** — grades can be written for a whole cohort by
applying a scheme, and in no other way. There is no path for a single correction.

**Where it is** — PR #1196, draft, conflicting against its own base.

**What it needs** — entry 2 first; it is stacked on it.

**Waiting on** — entry 2, then a reviewer.

---

## Next — make it visible to students

The assessment surface is teacher-only from end to end. `AssessmentAbility`
grants everything through the lecture's edit right, and no route reaches a
student.

### 4 · Publication

**Blocked until this lands** — students see nothing. `results_published_at`
already decides whether an exam counts as graded, and no production code sets it.

**What it needs** — an action to publish and one to withdraw, on the assessment,
with the guard that says who may.

**Waiting on** — code.

### 5 · Student results

**Blocked until this lands** — a student cannot see their own points, grade or
achievements anywhere.

**What it needs** — entry 4 first, then the student's own view of a
participation, and an ability that grants it to the participant rather than to
the lecture's staff.

**Waiting on** — entry 4, then code.

---

## Alongside — the cheapest work available

Two pull requests based on `next` are small, green, and have been sitting on
requested changes. They are the only items here that cost nothing to finish.

### 6 · Submission interface simplification

**Where it is** — PR #1116. Touches the same submission views that entry 2
rewrites; the longer it waits, the worse that conflict gets.

**Waiting on** — the author, then a reviewer.

### 7 · Roster change notifications

**Where it is** — PR #1187. Nothing of it is merged.

**Waiting on** — the author, then a reviewer.

---

## Then

### 8 · Exam registration, second pass

Making an exam the fourth thing a student can register for — next to tutorials,
talks and cohorts — left four screens half-fitting. The defects are fixed. What
remains is design, and it was deliberately kept out of the integration branch so
that it would not be reviewed inside a very large diff:

- what the "not assigned to a group yet" notice should say when an exam is one of
  the things a student holds, given that an exam involves no allocation at all
- whether that block should know about the campaigns, so it can speak per kind
  instead of once for everything
- whether the lecture roster should be a prerequisite for registering — today it
  is not, deliberately, and registration is decoupled from content access
- the tutorial-flavoured styling an exam tile inherits

**Waiting on** — entry 1, then a design call.

### 9 · Achievements for students

The teacher's side is complete: achievements, marking view, and the service that
feeds them into performance records. The student's side does not exist — no
progress view, and no way to mark an achievement other than through seeds.

**Waiting on** — entry 5, which establishes how a student reaches their own data.

### 10 · Dashboards

The largest untouched block, and the only one where no code exists at all. Worth
re-specifying before starting: the chapters describing it were written before the
assessment area existed and assume screens that were never built.

**Waiting on** — a specification.

---

## Continuous

### CI health

One end-to-end spec fails on `next` and is not on the skip list, so continuous
integration is red for a reason unrelated to any current work. Reproduced on a
clean `next` — checking the branch out is not enough on its own, the test
database has to be loaded from that branch's schema first, or the failure is a
different one. Either fix it or skip it; a permanently red pipeline hides real
regressions.

The Playwright suite also fails intermittently — roughly two runs in eleven,
always the same shape: a test times out with a navigation in flight. Measured and
excluded: browser memory, server latency, asset serving, recompilation after an
edit, background jobs, disk, CPU, and unhandled dialogs. Not reproducible on
demand. Recorded here so the next person does not start the search from the
beginning.

### The book

The chapters were written ahead of the code and have drifted. The known cases,
each small on its own:

- five controllers documented as if they existed; two live only on unmerged
  branches, three nowhere
- a whole section of student-facing views that no user can reach
- the roster namespace written in the singular throughout, while the models use
  the plural
- the policy engine described as a case statement, where the code dispatches to
  handler objects — and the service that actually decides eligibility has no
  chapter
- the evaluator's result described with fourteen fields where it has five, and
  without the deferred status the whole mechanism exists for
- duplicated sections and one file that is a heading and nothing else

None of it is hard. All of it costs a reader an hour of confusion, and some of it
will send them down the wrong path.
