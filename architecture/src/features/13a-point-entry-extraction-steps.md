# The Extraction, Step by Step

The sequence that turns [Point Entry for Exams](13-point-entry-generalisation.md) into
code. Steps 1 and 2 are corrections worth having whether or not exams follow; from step 3
onward each step is a precondition for the next.

```admonish info title="Which state this applies to"
The assessment work does not live on `next`. The tutor grading view is based on the
Müsli integration branch, and the talk grading view on the tutor branch, so the combined
state is the head of the talk grading work. That is the baseline the steps below assume.
```

## 1 · One answer to "may this be graded now?"

`SubmissionGraderService` and both row components ask `!assignment.active?`; the model
asks `assessment.grading_open?`. Point all three at the model's hook. The submission row
keeps `valid_for_pointing?` on top — that is a real extra condition, not a duplicate.

The boundary moves from the plain deadline to the friendly one, so parts of the task
point request specs will move with it. Read each failure before adjusting it: some of
them may be pinning the old boundary deliberately.

## 2 · Refuse `reviewed` when no task carries points

`update_status_if_all_scored!` promotes a `pending` participation the moment no task is
missing points — and with no tasks at all that condition is vacuously true. An empty
save then yields `reviewed` with a total of `0.0`.

```admonish warning
[Slice 5](../slices/05-exam-grading.md) describes this fallback as a guard rather than a
feature and expects a nil total. The measured value is `0.0`; the guard has to cover
both.
```

Not reachable through the interface today — the row's save button never becomes enabled
without inputs to dirty — so this closes a latent gap rather than a live defect. It is
worth closing before exams arrive, because a premature `reviewed` enters
`StudentPerformance::ComputationService` as a final result of zero, and that record
carries exam eligibility.

## 3 · Extract the participation row

Move it out of the tutorials namespace; it stops being a tutorial thing. It takes the
participation, the assessment, the grading scope and its two URLs, and it takes **no
`mode`**. The columns that differ between callers become optional slots rather than
branches on a flag.

Two things are worth correcting while the file is open:

- The row loads its points with one query per row. A large exam roster makes that hurt
  immediately; take a preloaded association instead.
- The point input carries `max` from the task, and the Stimulus controller enforces it —
  but `TaskPoint` validates only that points are non-negative. Points above the maximum
  are deliberately allowed, which is how a bonus works. Reusing the row unchanged would
  carry an interface inconsistency into exams; decide it here rather than inherit it.

Nothing about assignments should change. If a spec has to move, something else moved
with it.

## 4 · Derive the assessable instead of being told it

Drop `params[:type]`. The assessable and the grading scope both follow from the
participation — for an assignment the scope is its tutorial or, failing that, the
lecture; for an exam it is the lecture.

This is more than the branch statements in the actions. The resource loader also
requires a tutorial and names the assessable `assignment`, so an exam participation
fails there before any branch is reached. An unknown assessable class should be answered
deliberately, with 400 or 404 — not with an uncaught exception, and not, as today, with
an empty 200.

The submission actions stay assignment-specific. They are about a team handing something
in, which exams do not do.

## 5 · Project the exam roster onto participations

`Assessment#seed_participations_from!` already exists, is idempotent through a unique
index, serves achievements and the assignment backfill, and writes `pending` with no
`submitted_at` — precisely what an exam needs.

```admonish danger title="A single callback at finalisation is not enough"
Participants can still be added and removed after a campaign is finalised. A one-shot
seeding hook lets the roster and the gradebook drift apart. What is needed is a
projection, idempotent throughout: finalisation seeds every active entry; a manual add
or a reactivation ensures a participation; a removal without grading data takes it away
again; a removal *with* grading data stays blocked, as it already is.
```

Do not widen `SubmissionGraderService.init_participation` to accept a missing tutorial.
That service stays assignment-specific, and going through it would contradict the
division the rest of this sequence rests on.

## 6 · The exam point table, and a dashboard that dispatches

The table takes an assessment and a grading scope and renders the header plus
participation rows from step 3. Exams need none of the non-submitter zone, the "mark as
participated" action, bulk download, bulk upload, or the team column.

The dashboard has to choose the table by assessable rather than handing every pointable
to the assignment one.

## 7 · Absence, and what `submitted_at` means for an exam

`mark_absent` and `mark_exempt(note:)` need a controller and a route. Excusing must go
through `mark_exempt`: it clears the grade along with the status, and setting the status
directly would leave a failing grade that re-applying a scheme will not remove either.

`PointGridComponent` needs to stop treating a missing `submitted_at` as absence from the
table, and to stop showing a tutorial column for assessables that have no tutorials.

## Afterwards, if it still grates

Small shared primitives between the talk and point interfaces — the person cell, the
status badge, the save and refresh buttons, the dirty-state behaviour. A shared *grading
row* across both would be premature: a talk carries one final grade, an assignment and an
exam carry task points.

## Leave alone

- `SubmissionGraderService` keeps its name and its submission-shaped API.
- `seed_participations_from!` is the seeding API. A second one is not needed.
- The `||=` on a participation's `tutorial_id` is deliberate. The pointer records *where
  this is graded*, decided once; it does not follow a roster move, and a spec pins that.
- A talk cannot carry a grade scheme — `GradeScheme` requires an assessable that is both
  pointable and gradable, and a talk is only gradable. Any reasoning about schemes
  applies to exams, never to talks or assignments.
