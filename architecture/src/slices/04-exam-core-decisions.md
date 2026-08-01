# Slice 4 — Decisions

```admonish question "How to read this page"
Five choices this slice makes where the code shows *what* happens but not why
that option was picked or what it costs elsewhere. Each entry leads with a
**question for the reviewer** and then answers it the way the branch currently
does — they aim your reading rather than replace it.

**Status** is one of **settled** (rationale and test exist), **reconstructed**
(intent inferred; the author should confirm) or **open** (needs a decision).
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`cb300a0c`](https://github.com/MaMpf-HD/mampf/commit/cb300a0c1721249a879590bb00d2c92f3855d944),
the tip of `muesli-04-exam-core`. All URLs live in one block at the end of the
file.
```

---

## Defects to fix before review

Found by running this slice's suite on its own during the cascade. Each was
checked against the branch and is unrelated to the assessment work merged in.

~~~admonish danger "The component calls a method that does not exist"
`ExamRegistrationTabComponent` calls `localized_rejection_reason_label` on a
`Registration::UserRegistration`, which has no such method — the render raises
`NoMethodError`, so the tab is broken wherever a rejected registration appears
after finalization.

Slice 5 does not call it at all, so this is confined to slice 4 and already
resolved upstream. Either the method never landed with the component, or it was
dropped and this call site was missed.

Seen in `exam_registration_tab_component_spec:94`.
~~~

~~~admonish danger "The exam statistics partial uses translations this slice does not have"
`app/frontend/exams/_statistics.html.erb` references
`assessment.statistics_analysis` and `assessment.statistics_description`. Neither
key exists anywhere in this slice's locale files — they arrive only in slice 5.
In the test environment that raises; in production the page shows
"translation missing".

Slice 4 is therefore not self-contained: a page it ships cannot be rendered until
the next slice lands.
~~~

~~~admonish warning "`roster.participants` has no German translation"
English has it, German does not. This slice introduces the only call site,
`exams/_list.html.erb:30`, so `i18n_spec` is red on every run of this branch and
of slice 5 — while it is green on `next`, where nothing references the key.

A one-line addition to `config/locales/roster/de.yml` fixes it. Note that the
neighbouring `participants` keys in that file sit one level deeper and are
different keys.
~~~

~~~admonish warning "Two exam specs are flaky by construction"
The exam factory sets `date { Faker::Time.forward(days: 30) }` — a random point
within the next 30 days. Both failures come from that draw landing inside the
**three-day** window that the surrounding code assumes is available:

- `exam_registration_spec` passes a fixed `registration_deadline: 3.days.from_now`,
  which falls *after* an exam drawn less than three days out
- `exam_settings_component_spec` relies on the model default, [`date - 3.days`][c4-createcamp],
  which lands *in the past* for the same draw, so opening the campaign is refused

Measured: `Faker::Time.forward(days: 30)` returns a date under three days out in
**92 of 1000 draws**, so each affected example fails about one run in eleven, and
a full suite run shows a different subset each time. Demonstrated directly — with
the date forced to +10 days the record is valid, at +1 day it is not, with the
identical spec setup.

Giving the affected examples a fixed date fixes both. The factory's random date is
fine for specs that do not reason about the deadline.
~~~

---

## E-4.6 · An exam cannot be deleted once it has a roster or a live campaign

> **Are "roster not empty" and "campaign beyond draft" the right conditions for
> refusing deletion?**

**As built.** `non_destructible_reason` returns `:roster_not_empty` or
`:in_campaign`; a `before_destroy … prepend: true` hook destroys the campaign
only while it is still a draft.

**Code.** [`non_destructible_reason`][c4-nondestruct] ·
[`destroy_draft_campaign`][c4-destroydraft]

**Example.** A teacher creates an exam by mistake and deletes it the same
afternoon — the draft campaign goes with it, cleanly. A month later, after
registration opened, the same delete is refused with *"exam is already part of a
registration campaign"*.

**Why it matters.** It prevents orphaning registrations students have made. The
`prepend: true` matters: without it the campaign cleanup would run after other
`before_destroy` callbacks and could leave a campaign behind.

**Status:** settled.

---

## E-4.7 · Exams are exclusive per campaign but not across siblings

> **Should being on one exam's roster have no bearing on registering for
> another exam in the same lecture?**

**As built.** `Exam#exclusive_assignment?` is defined as an **instance** method
returning `true`, and deliberately **not** as a class method. The instance
method governs "one registration row per user per campaign"; the class method,
which `AllocationDashboard#calculate_conflicts` consults, governs "allocating
here overwrites a sibling assignment".

**Code.** [`exclusive_assignment?`][c4-exclusive]

**Example.** *Analysis I* has a main exam and a resit.

- Paula registers for the main exam. One row per campaign — she cannot register
  twice for the same exam.
- She also registers for the resit. **No conflict warning**, because the class
  method is absent and falls back to `false`.

Contrast `Tutorial`, which defines *both*: `tutorial_memberships` is unique on
`(user_id, lecture_id)`, so allocating a second tutorial genuinely overwrites the
first and the warning is correct there.

**Why it matters.** Sitting a main and a resit exam is legitimate, so the
sibling-conflict warning would be noise. The distinction between the two methods
is real but undocumented — a reader is likely to "fix" the asymmetry by adding
the class method and thereby switch on bogus warnings.

**Status:** reconstructed · worth an ADR, since the same trap applies to `Talk`.

---

## E-4.8 · The exam lifecycle is derived, not stored

> **Should the exam's phase be computed from campaign status and date rather
> than being a column?**

**As built.** `status_phase` returns `:draft`, `:registration_open`,
`:registration_closed`, `:finalized`, `:conducted`, `:grading` or `:graded`,
computed from the campaign's status and the exam date.

**Code.** [`status_phase`][c4-phase]

**Example.** An exam whose campaign is `completed` and whose date is yesterday
reports `:conducted` — without anything having been written to the exam row when
the clock passed midnight.

**Why it matters.** Nothing can drift out of sync, and no migration is needed
when a phase is added. The cost is that the phase cannot be queried in SQL: any
"show me all exams awaiting grading" list has to load and ask each one.

**Status:** reconstructed.

---

## E-4.9 · Exam campaigns are always first-come-first-served

> **Should an exam campaign never use preference-based allocation?**

**As built.** `create_registration_campaign` hardcodes
`allocation_mode: :first_come_first_served`.

**Code.** [`create_registration_campaign`][c4-createcamp]

**Example.** This is what routes an exam through the branch of
`FinalizationGuard#check` that actually runs the `ScreeningService` — and hence
the eligibility policy from slice 3. A preference-based campaign returns success
before screening.

So the hardcoded mode is not cosmetic: **it is what makes exam eligibility
enforced at all.**

**Why it matters.** The coupling is invisible from either side. Anyone making
exam campaigns configurable would silently disable eligibility checks for
preference-based ones.

**Status:** reconstructed · **this deserves a comment at the assignment.**

---

## E-4.10 · Exams carry the full assessment stack from day one

> **Should an exam be `Pointable` and `Gradable` already in this slice, although
> grading only arrives in slice 5?**

**As built.** `Exam` includes `Registration::Registerable`,
`Rosters::Rosterable`, `Assessment::Pointable` and `Assessment::Gradable`, and
an `after_create` calls `setup_assessment` behind the `assessment_grading` flag.

**Code.** [the concern stack and hooks][c4-concerns]

**Example.** Creating an exam immediately produces an `Assessment` with
`requires_points: true`, ready for tasks — even though no UI in slice 4 grades
anything. Slice 5 then only adds the grade scheme on top, without touching
`Exam`.

**Why it matters.** It keeps slice 5's diff small and means an exam is never in
a state where it has a roster but no gradebook. The cost is that slice 4 creates
rows for a feature it does not yet expose, which makes the slice boundary softer
than the PR title suggests.

**Status:** settled.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-4.6 | Exam undeletable once roster or live campaign exists | settled |
| E-4.7 | Exclusive per campaign, not across sibling exams | reconstructed |
| E-4.8 | Lifecycle derived, not stored | reconstructed |
| E-4.9 | Exam campaigns hardcoded to first-come-first-served | reconstructed |
| E-4.10 | Full assessment stack included from the start | settled |

**E-4.9 is the one to read first.** The hardcoded allocation mode is what causes
slice 3's eligibility policy to be enforced at all, and nothing at either end
says so. **E-4.7** is next: the class/instance split is deliberate and correct
but reads like an oversight.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 77565064, the tip of                -->
<!-- muesli-04-exam-core. To re-pin, replace the SHA below.              -->
<!-- ------------------------------------------------------------------ -->

[c4-createcamp]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L177-L191
[c4-nondestruct]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L40-L47
[c4-destroydraft]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L217-L222
[c4-exclusive]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L102-L104
[c4-phase]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L106-L123
[c4-concerns]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L19-L38
