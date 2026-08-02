# Slice 4 — Decisions

```admonish question "How to read this page"
Ten places where slice 4 makes a choice that cannot be read off the diff. Each
entry leads with a **question for the reviewer**.

**Status** is one of **settled** (rationale and test exist), **reconstructed**
(intent inferred; the author should confirm) or **open** (needs a decision).
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`77565064`](https://github.com/MaMpf-HD/mampf/commit/775650640aa77a849c3c01a279ec865c6f1ff2a3),
the tip of `muesli-04-exam-core`. All URLs live in one block at the end of the
file.
```

---

## E-4.1 · Creating an exam creates a registration campaign

> **Should every exam get a campaign automatically, with opting out as the
> exception?**

**As built.** An `after_create` hook builds a `Registration::Campaign` plus one
`Registration::Item` pointing at the exam, unless `skip_campaigns` is set. The
campaign is saved with `validate: false` and is always
`first_come_first_served`.

**Code.** [`create_registration_campaign`][c4-createcamp]

**Example.** A teacher fills in "Klausur Analysis I", date, capacity 200, and
saves.

- a draft campaign appears with a deadline of *exam date minus three days*
- the exam shows a Registrations tab
- ticking "manage participants manually" instead sets `skip_campaigns` and no
  campaign is created at all

**Why it matters.** It makes the common path one step, but the campaign is
created with validations disabled, so an exam can produce a campaign that would
not have passed its own model validations.

**Status:** reconstructed · the `validate: false` deserves a sentence of
justification in the code.

---

## E-4.2 · The registration deadline lives on the campaign, not the exam

> **Is it right that `Exam#registration_deadline` is a form field with no
> column behind it?**

**As built.** `attr_accessor :registration_deadline`. Writing it triggers an
`after_update` that pushes the value onto the campaign; reading it after a
reload gives nil unless `load_registration_deadline` was called.

**Code.** [the `attr_accessor`][c4-attrs] ·
[`update_campaign_deadline`][c4-updatedeadline] ·
[`registration_campaign` lookup][c4-camplookup]

**Example.** A teacher edits the exam and moves the deadline a week later.

- `exam.registration_deadline = …` → `after_update` → `campaign.update(...)`
- reopening the form calls `load_registration_deadline`, which reads it back
  *from the campaign*

If a future caller sets the attribute without saving, or reads it without
loading, it silently sees nil.

**Why it matters.** One value, two homes, and the exam's copy is transient. It
keeps the campaign authoritative, which is right, but the attribute looks like a
column at every call site.

**Status:** reconstructed.

---

## E-4.3 · Roster removal is soft after finalization and hard before

> **Should removing a participant destroy the row or only mark it excluded,
> depending on the campaign's state?**

**As built.** If the campaign is `completed`, the entry gets
`excluded_at = Time.current`; otherwise it is destroyed outright.

**Code.** [`remove_user_from_roster!`][c4-remove]

**Example.** Two removals of the same student from the same exam:

- **before finalization** — the row is deleted; nothing records that they were
  ever registered
- **after finalization** — the row survives with `excluded_at` set, appears
  under "not on the exam roster" with the reason *removed from the exam roster*,
  and can be added back

**Why it matters.** After finalization an audit trail matters, because a
removal reverses an allocation students have already seen. Before finalization
nothing has been promised. The asymmetry is defensible but invisible — the same
button does two different things.

**Status:** reconstructed.

---

## E-4.4 · Re-adding revives the excluded row and keeps its origin

> **Should adding someone back reuse the old entry rather than creating a fresh
> one?**

**As built.** `add_user_to_roster!` uses `find_or_initialize_by(user:)` on the
**unscoped** association, clears `excluded_at`, and only fills
`source_campaign` if it is still blank (`||=`).

**Code.** [`add_user_to_roster!`][c4-add]

**Example.** Nina is allocated through the campaign, removed by hand, then added
back manually.

- her original row is revived, `excluded_at` cleared
- `source_campaign` still points at the campaign that first admitted her, **not**
  at the manual re-add

So the roster remembers how she originally got in, which is what the campaign
statistics rely on. The flip side: there is no record that she was ever removed
once she is back.

**Why it matters.** `||=` is the whole decision, and it is one character wide.

**Status:** reconstructed.

---

## E-4.5 · Grading data makes a participant unremovable

> **Should the presence of grading data block removal by raising, rather than by
> a validation?**

**As built.** `ensure_participant_removable!` raises
`Exam::ParticipantRemovalNotAllowedError` when the user appears in
`participants_with_grading_data`.

**Code.** [`remove_user_from_roster!`][c4-remove] ·
[`participant_removable?`][c4-removable]

**Example.** Olaf sat the exam and has points entered on three tasks. An
assistant tries to remove him from the roster.

- the exception propagates out of the model; the controller must catch it and
  turn it into a flash message
- the UI pre-empts this by rendering the remove button disabled with a tooltip

**Why it matters.** An exception rather than a validation means every caller
must know about it. It is the right severity — silently discarding grading data
would be worse — but it puts the burden on the call sites.

**Status:** settled.

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
| E-4.1 | Exam auto-creates its campaign (`validate: false`) | reconstructed |
| E-4.2 | Registration deadline is transient on the exam | reconstructed |
| E-4.3 | Removal is soft after finalization, hard before | reconstructed |
| E-4.4 | Re-adding revives the row and keeps the original source | reconstructed |
| E-4.5 | Grading data blocks removal by raising | settled |
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

[c4-createcamp]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L177-L191
[c4-attrs]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L24
[c4-updatedeadline]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L170-L175
[c4-camplookup]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L88-L90
[c4-remove]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L65-L76
[c4-add]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L57-L63
[c4-removable]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L78-L86
[c4-nondestruct]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L40-L47
[c4-destroydraft]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L217-L222
[c4-exclusive]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L102-L104
[c4-phase]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L106-L123
[c4-concerns]: https://github.com/MaMpf-HD/mampf/blob/775650640aa77a849c3c01a279ec865c6f1ff2a3/app/models/exam.rb#L19-L38
