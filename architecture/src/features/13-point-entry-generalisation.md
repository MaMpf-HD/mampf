# Point Entry for Exams

Exams are the third assessable to need a marking interface. Assignments have one;
talks acquired a second one beside it. That second build was the right call — a third
value on the `mode:` flag would have been worse than a second table — but it means the
question is now open rather than settled: does an exam become a third build, or does it
reuse what exists?

This page argues for reuse, and says exactly how far the existing code already reaches.
[The extraction sequence](13a-point-entry-extraction-steps.md) turns that into steps.

## What already carries an exam

`Exam` includes `Assessment::Pointable` and `Assessment::Gradable`, so it is given an
assessment with tasks on create, exactly as an assignment is.

`Assessment::PointEntryService` only ever touches a participation and its assessment:

```ruby
def self.enter_points(participation, task_points, grader, submission = nil)
```

The submission is already optional, and `TaskPoint#submission_id` is nullable. The
schema anticipated points without a submission from the start.

On the reading side, `GradeTableComponent` is written against the assessment and is
explicitly prepared for exams.

```admonish warning title="One reading component is not ready"
`PointGridComponent` filters its main table with `.where.not(submitted_at: nil)`. An
exam participation that is `reviewed` with no `submitted_at` — which
[Assessments & Grading](04-assessments-and-grading.md) documents as valid — disappears
from it entirely. It also renders a tutorial column for everything that is not a talk,
including exams.
```

## What holds the writing half back

### The lifecycle question is answered in three places

The model asks `assessment.grading_open?`. `SubmissionGraderService` and both row
components ask `!assignment.active?`. Those are different moments — the plain deadline
against the friendly one — so inside a lecture's grace period the view enables fields
that `Participation` and `TaskPoint` then refuse.

For an exam the divergence stops being a nuisance. `Exam` has no `active?` at all, so
the service raises `NoMethodError` before `PointEntryService`, which would have worked,
is ever reached. Asking the model's own hook removes the obstacle instead of adding a
branch — and no assessable then needs an `active?` of its own, because
`Assessment::Assessable` supplies `grading_open? == true` by default and `Assignment`
overrides it with `totally_expired?`.

### The row components are tied to `Assignment` and `Tutorial`

`ParticipationRowComponent` reaches through `@assignment` three times, and each reach
has a generic equivalent:

| today | equivalent |
|---|---|
| `@assignment.assessment.persisted_tasks` | `assessment.persisted_tasks` |
| `@assignment.active?` | `assessment.grading_open?` |
| `@assignment.assessable?` | falls away — holding an assessment *is* the answer |

The grading scope can be a value too: `User#can_grade_in_scope?` already accepts a
`Lecture` **or** a `Tutorial` and raises on anything else.

The other half is the endpoint. The row builds its own route — `point_user_tutorial_path`,
`refresh_point_user_tutorial_path`. **A component that constructs its own route can only
ever serve one kind of assessable.** Handed the URL from outside, the same row serves any.

The `mode:` flag has to go at the same time, not later: the template branches on it to
render a tutorial column for teachers and a correction column for tutors. Neither shape
fits an exam, so a generic row that still carries the flag would force exams to choose
between two wrong answers.

### The controller is told its type by the client

`case params[:type] when "Tutorial"` has one branch and no `else`; handed any other type
the action does nothing at all — no exception, no flash, an empty 200. The routes feed
it a constant, `defaults: { type: "Tutorial" }`.

None of it is necessary. The assessable and the grading scope both follow from the
participation being scored:

```text
participation → assessment → assessable
                          → grading scope
```

The same assumption sits one level deeper, in the resource loader, which refuses a
participation that has no tutorial — which is what every exam participation looks like.

### The dashboard hands every `Pointable` to the assignment table

`build_tabs` adds the points tab for any pointable assessable, and that tab renders the
tutorial pointing table with the assessable passed as `assignment:`. For an exam that
means assignment-specific methods called on an `Exam`. The dispatch has to happen on the
assessable rather than being left to a component that cannot serve it.

## What an exam needs that no assignment does

Not everything is subtraction. The exam workflow is *seed the roster, mark the no-shows
`absent`, treat certificates as `exempt`, then grade the rest*.
`Assessment::AbsenceHandling` provides `mark_absent` and `mark_exempt(note:)`, both
specced, but nothing in the application calls them yet. Without those two actions an
exam table cannot express what a real examination day produces.

And exams have roster entries, not participations. Nothing in the application turns one
into the other today; only the demo seeder ever has. Without that projection an exam
point table has nothing to render at all, which is why it comes before the table rather
than after it.

## The axes

The useful cut is not tutor against teacher. Stated in full there are two axes:

| assessable | what is entered | what carries it | permission scope |
|---|---|---|---|
| Assignment | task points | submission (team) or participation (person) | tutorial or lecture |
| Exam | task points | participation | lecture |
| Talk | one final grade | participation | lecture |

Assignment and exam share the participation row and `PointEntryService`. The submission
fan-out stays in `SubmissionGraderService`. Talk keeps its own grade-entry path, because
entering one final grade is not the same act as entering task points.

`mode:` scales along *who is looking*. The axis that keeps arriving is *what is being
assessed*, and a flag carries only one axis. Talk grading meets the same wall from the
other side as soon as it needs a view for whoever supervises a talk, beside the teacher
view it has now.

```admonish note title="What deliberately stays"
`SubmissionGraderService` keeps its name and its submission-shaped API. It is the
assignment-specific wrapper around a generic core, and that is the right division — the
mistake would be to widen it into something that serves exams badly in order to avoid a
second, smaller caller.
```
