# Slice 1 — Decisions

```admonish question "How to read this page"
Ten places where slice 1 makes a choice that cannot be read off the diff. Each
entry leads with a **question for the reviewer**. Answer it — if the answer is
"yes, that is what we want", the entry is settled and you never need to open the
file.

**Status** is one of:
- **settled** — rationale and a test both exist
- **reconstructed** — the intent was inferred from the code; the author should confirm it
- **open** — no discernible intent; needs a decision
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`1b18286c`](https://github.com/MaMpf-HD/mampf/commit/1b18286c708e89d5982b00eaf6a216c54c2b0584),
the tip of `muesli-01-assessment-core`. Pinning is what makes them resolve at
all — this branch starts from `next`, where the code does not exist yet — and it
freezes the line numbers so they stay accurate after the branch is merged.
All URLs live in one block at the end of the file.
```

---

## E-1.1 · Capabilities are concerns, not columns

> **Should "can be pointed" and "can be graded" be expressed by including a
> module rather than by flags on a row?**

**As built.** A three-step ladder: `Assessable` grants the assessment
association, `Pointable` and `Gradable` each include it and add their own
entry point. A model opts in by including one.

**Code.** [`Assessable`][c1-assessable] · [`Pointable`][c1-pointable] ·
[`Gradable#set_grade!`][c1-setgrade]

**Example.** `Assignment` includes `Pointable`, so it answers
`ensure_pointbook!`. `Achievement` (slice 2) includes plain `Assessable` — it is
assessable but carries no points. `Exam` (slice 4) includes **both**
`Pointable` and `Gradable`.

Because the ladder is compile-time, "is this gradable?" is answered by
`assessable.is_a?(Assessment::Gradable)` — which is exactly what
`Participation#assessment_must_be_gradable` checks before allowing a numeric
grade.

**Why it matters.** It makes the capability a property of the *class*, not of
the row, so it cannot drift per record — but it also means adding a capability to
an existing type is a code change plus a data backfill, never a setting.

**Status:** settled.

---

## E-1.2 · One assessment per assessable, created idempotently

> **Should an assessable ever be able to carry more than one assessment?**

**As built.** No. `has_one :assessment, as: :assessable`, and
`ensure_assessment!` builds or updates the existing one rather than creating a
second.

**Code.** [`ensure_assessment!`][c1-ensure]

**Example.** `Achievement#setup_assessment` (slice 2) calls
`ensure_assessment!(requires_points: false, …)` in an `after_create`. If the
achievement is later edited and the hook runs again, the same assessment is
reused and only its flags are updated — no duplicate, no orphan.

**Why it matters.** Every later slice reaches an assessment through
`assessable.assessment` and assumes uniqueness; a `has_many` here would break
that assumption everywhere at once.

**Status:** settled.

---

## E-1.3 · Grading opens only once nobody can still submit

> **Is "deadline plus grace period elapsed" the right moment to allow grading to
> begin?**

**As built.** `Assessable#grading_open?` defaults to `true`, and `Assignment`
overrides it:

```ruby
alias grading_open? totally_expired?    # !semiactive?
```

So for an assignment, grading opens only once the deadline *and* the grace period
have passed. `Participation#grading_lifecycle_must_be_open` then rejects any
change to `grade_numeric`, `grade_text`, `points_total`, `grader_id`, `graded_at`,
or any move away from `pending`, while grading is still closed.
`Assessment::TaskPoint` carries the same guard, so individual point entries are
covered too.

**Code.** [`grading_open?` in `Assessable`][c1-open] ·
[the alias in `Assignment`][c1-assignopen] ·
[the guard that consumes it][c1-lifecycle]

**Example.** A tutor tries to enter points for *Übungsblatt 5* three days before
its deadline:

- `assessment.grading_open?` delegates to `Assignment#grading_open?` →
  `totally_expired?` → **false**
- the participation fails validation with `early_grading_not_allowed`

Once the deadline and grace period have elapsed, the same write succeeds.

**Why it matters.** It stops a tutor from grading while classmates can still
submit or revise — no partial grading, no early leak of results. Note the
consequence in the other direction: because the same guard blocks *changes*, it
also constrains corrections made while an assignment is briefly reopened.

Assessables that do not override it — `Exam`, `Achievement` — are always open,
which is the sensible default for things without a submission deadline.

**Status:** settled.

```admonish warning "Correction"
An earlier version of this entry claimed the override did not exist and that the
guard was dead code. That was wrong: the sweep searched for `def grading_open?`,
which does not match an `alias`. The guard is live and demonstrably rejects
early grading.
```

---

## E-1.4 · An explicit total overrides the sum of task points

> **Should a manually set `total_points` win over the tasks that actually
> exist?**

**As built.** `effective_total_points` returns `total_points` when present, and
only otherwise falls back to `tasks.sum(:max_points)`.

**Code.** [`effective_total_points`][c1-effective]

**Example.** An assignment has three tasks worth 10 points each, and a teacher
enters 25 as the total.

- `effective_total_points` → **25**, not 30
- slice 2's computation service uses exactly this value as the denominator, so
  every student's percentage is computed against 25
- a student with all 30 points therefore scores **120 %**

**Why it matters.** The override is the single source of truth for percentages
downstream, and nothing reconciles it with the tasks or caps the result.

**Alternative.** Treat the task sum as authoritative and use `total_points` only
where no tasks exist.

**Status:** reconstructed.

---

## E-1.5 · Participations are seeded with `insert_all`

> **Is it acceptable that seeding participations bypasses validations and
> callbacks?**

**As built.** `seed_participations_from!` builds raw rows and uses `insert_all`
with `unique_by: [:assessment_id, :user_id]`, mapping the enum by hand because
`insert_all` does not apply it.

**Code.** [`seed_participations_from!`][c1-seed]

**Example.** A lecture with 400 members gets an achievement. Slice 2's
`Achievement#setup_assessment` seeds one participation per member in a single
statement instead of 400 `create!` calls.

The trade-off is visible in the code: the enum has to be written as
`Participation.statuses[:pending]` rather than `:pending`, and none of the
model's validations (`user_id` uniqueness, the grading lifecycle guard) run.
Uniqueness is delegated to the database via `unique_by`.

**Why it matters.** It is the right call for a bulk seed, but it establishes a
second, validation-free write path into a table whose invariants are otherwise
enforced in Ruby.

**Status:** reconstructed.

---

## E-1.6 · The grade scale is a hardcoded list

> **Should the set of valid grades live in an inclusion validation rather than in
> configuration?**

**As built.** `grade_numeric` must be one of
`1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0`.

**Code.** [the inclusion validation][c1-grades]

**Example.** The German scale skips 4.3 and 4.7 — everything below 4.0 is 5.0.
A teacher trying to award 4.3 gets a validation error.

Slice 5 repeats the same list as `GradeScheme::PASSING_GRADES` (without 5.0)
when generating band schemes, so the scale now exists in two places.

**Why it matters.** It hardcodes one institution's scale into a validation. A
lecture using a different scheme cannot be represented, and the duplication in
slice 5 means a change has to be made twice.

**Status:** reconstructed.

---

## E-1.7 · A task cannot be deleted once points were entered

> **Should entered points block deleting a task outright, rather than warning?**

**As built.** Two `before_destroy … prepend: true` guards that `throw(:abort)`:
one if any task point has a non-nil value, one if the assignment deadline has
passed.

**Code.** [`check_no_points_entered`][c1-nopoints] ·
[`check_deadline_not_passed`][c1-nodeadline]

**Example.** A teacher creates task 3 by mistake, grades five students against
it, then tries to delete it.

- the destroy is aborted silently at the model level (`throw :abort`), so
  `destroy` returns `false` without an exception
- to remove it they must first clear all five point entries

**Why it matters.** It protects grading data, which is right — but `throw(:abort)`
adds no error to the record, so any caller that does not check the return value
sees nothing at all.

**Status:** settled.

---

## E-1.8 · Display status is derived, not stored

> **Should "not submitted" and "pending grading" be computed rather than being
> statuses of their own?**

**As built.** The enum has four values (`pending`, `reviewed`, `absent`,
`exempt`). `display_status` splits `pending` into `:not_submitted` or
`:pending_grading` depending on whether `submitted_at` is set.

**Code.** [`display_status`][c1-display]

**Example.** Two students both have `status: pending`:

- Frank has not handed in → `submitted_at` nil → shown as **not submitted**
- Grace handed in yesterday → `submitted_at` set → shown as **pending grading**

Both are the same row state; only the view distinguishes them.

**Why it matters.** It keeps the enum small and the state machine honest —
submission is a timestamp, not a status. The cost is that no query can filter on
the displayed state without replicating the condition.

**Status:** settled.

---

## E-1.9 · An assessment's lecture must equal its assessable's lecture

> **Is the duplicated `lecture_id` on Assessment worth the validation that keeps
> it honest?**

**As built.** `lecture_id` is stored on the assessment and a validation rejects
any value that disagrees with `assessable.lecture_id`.

**Code.** [`lecture_matches_assessable`][c1-lecmatch]

**Example.** Slice 2's computation service opens with
`Assessment::Assessment.where(lecture_id: lecture.id, assessable_type: "Assignment")`.
Without the denormalised column that query would have to join through a
polymorphic association to two different tables.

**Why it matters.** The column buys query simplicity for every later slice; the
validation is what stops the two from drifting. Note it only guards writes
through the model — it cannot catch a lecture being moved underneath.

**Status:** settled.

---

## E-1.10 · `requires_submission` freezes after the deadline

> **Should the submission requirement become immutable once an assignment's
> deadline has passed?**

**As built.** A validation rejects changing `requires_submission` when the
assessable is an `Assignment` and `past_deadline?`.

**Code.** [`requires_submission_locked_after_deadline`][c1-locksub]

**Example.** An assignment closes on Friday. On Saturday the teacher notices
they never required a submission and tries to switch it on, intending to mark
non-submitters absent.

- → rejected with `locked_after_deadline`

**Why it matters.** Changing the rule after the fact would retroactively make
students non-compliant with a requirement that did not exist while they could
still act on it. This is the one place in slice 1 where a deadline actually
constrains grading — and it is worth contrasting with
[E-1.3](#e-13--grading_open-is-always-true--the-lifecycle-guard-never-fires),
where the analogous guard is unreachable.

**Status:** settled.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-1.1 | Capabilities as concerns, not columns | settled |
| E-1.2 | One assessment per assessable, idempotent | settled |
| E-1.3 | Grading opens once deadline and grace period elapsed | settled *(was: open, in error)* |
| E-1.4 | Explicit `total_points` overrides the task sum | reconstructed |
| E-1.5 | Participation seeding bypasses validations | reconstructed |
| E-1.6 | Grade scale hardcoded in a validation | reconstructed |
| E-1.7 | Entered points block task deletion (silent abort) | settled |
| E-1.8 | Display status derived, not stored | settled |
| E-1.9 | Denormalised `lecture_id`, kept honest by validation | settled |
| E-1.10 | `requires_submission` frozen after the deadline | settled |

**E-1.4 is the one to look at first**: an explicit `total_points` overrides the
task sum and becomes the denominator for every percentage downstream, so a
student with all task points can score above 100 %. Nothing reconciles the two or
caps the result.

E-1.3 was previously listed here as an open item on the grounds that its
validation could never fire. That was a mistake on our side, corrected in the
entry itself — the guard is live.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 1b18286c, the tip of                -->
<!-- muesli-01-assessment-core. To re-pin, replace the SHA below.        -->
<!-- ------------------------------------------------------------------ -->

[c1-assessable]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessable.rb
[c1-pointable]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/pointable.rb
[c1-setgrade]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/gradable.rb#L16-L38
[c1-ensure]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessable.rb#L11-L18
[c1-open]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessable.rb#L20-L24
[c1-assignopen]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assignment.rb#L66-L69
[c1-lifecycle]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/participation.rb#L53-L68
[c1-effective]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessment.rb#L31-L33
[c1-seed]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessment.rb#L39-L65
[c1-grades]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/participation.rb#L27-L31
[c1-nopoints]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/task.rb#L35-L37
[c1-nodeadline]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/task.rb#L39-L43
[c1-display]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/participation.rb#L41-L49
[c1-lecmatch]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessment.rb#L69-L75
[c1-locksub]: https://github.com/MaMpf-HD/mampf/blob/1b18286c708e89d5982b00eaf6a216c54c2b0584/app/models/assessment/assessment.rb#L77-L81
