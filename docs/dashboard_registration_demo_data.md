# Dashboard registration-state demo data

Gives four of the five seeded students (`student1@mampf.edu` ..
`student5@mampf.edu`) one lecture each in a different registration
transition state the dashboard distinguishes, so the states can be seen in
the UI without waiting for real registration campaigns to reach them. A
fifth lecture stays open with nobody applied, to show the "Registration
open" badge in search.

Implemented in `Demo::DashboardRegistrationSupport`
(`lib/demo/dashboard_registration_support.rb`), and wired into
`rails seeds:build` (`Seeds::BuildSupport.build!`), so every shipped edition
of the seed data carries it. Sign in as any of the five students (see
`rails seeds:package`/README for the shared demo password) or use the
"Switch user (dev only)" dropdown in the navbar (visible in development) to
impersonate one from an admin account.

## The lectures

- **student1 — pending, no roster seat yet.** Lecture "Einführung in die
  Numerik", campaign `:preference_based`, `:open`. Shows the hourglass
  "Pending" badge on the dashboard, still bookmarkable/unbookmarkable.
  The campaign must be `:preference_based`, not the default
  first-come-first-served: FCFS decides synchronously (confirmed or
  rejected right away), so a *pending* FCFS row is not a state the app's
  own UI ever produces. A preference-based campaign stays pending until
  the teacher finalizes it, and the lecture's own home tab then shows the
  student's submitted preference ranking.

- **student2 — confirmed, not yet rostered.** Lecture "Maßtheorie und
  Wahrscheinlichkeit", campaign `:first_come_first_served`, `:open`.
  `Registration::UserRegistration` confirming an applicant does not by
  itself create a `LectureMembership` - rostering is a separate step. This
  is the gap the dashboard used to fall into: without this fix, a
  confirmed-but-not-yet-rostered lecture was invisible on the dashboard.
  Shows the check-mark "Confirmed" badge; no longer bookmarkable/
  unbookmarkable.
  Known limitation, not fixed here: because no roster/tutorial-membership
  row exists for this made-up case, the lecture's own home tab shows
  nothing about the confirmation either (RosterizedEntriesComponent reads
  actual roster entries, not `Registration::UserRegistration` directly). In
  the real app this window is normally short - confirmation is followed by
  rostering - so this is a demo-data artifact, not a new bug.

- **student3 — rejected, not dismissed.** Lecture "Algebraische Topologie",
  campaign `:first_come_first_served`, `:completed`, registration trait
  `:policy_rejected`.
  The campaign must be `:completed`, not just `:closed`:
  `Lecture#registration_status_for` only reports `:rejected` once the
  campaign is no longer open for registrations (see the "open beats
  rejected" precedence there) - `:closed` alone is enough for that, but the
  lecture's own home tab only explains *why* via
  `RosterizedEntriesComponent#policy_rejected_campaigns`, which specifically
  requires `status: :completed`. Use `:policy_rejected`, not
  `:capacity_rejected`: the lecture-page notice for a *capacity* rejection
  only exists for preference_based campaigns; a first-come-first-served
  capacity rejection (this campaign's default allocation mode) has no
  notice anywhere on the lecture page at all - a genuine gap in the app,
  out of scope here. `:policy_rejected` renders regardless of allocation
  mode.

- **student4 — rejected, but also bookmarked.** Lecture "Funktionalanalysis",
  same setup as student3, plus `student.subscribe_lecture!(lecture)`.
  Still shown once, in "You are registered for these" (registration status
  takes precedence over a plain bookmark) - not duplicated into "You
  bookmarked these".

- **student5 — plain bookmark, no registration campaign at all.** Lecture
  "Diskrete Mathematik", just `student.subscribe_lecture!(lecture)`. Shows
  in "You bookmarked these" with the plain bookmark "x".

- **Registration open, nobody has applied.** Lecture "Partielle
  Differentialgleichungen", campaign `:first_come_first_served`, `:open`,
  no registrations. Does not show on any dashboard today (neither roster
  nor bookmark nor an application exists for anyone) - it is only
  discoverable via lecture search, where it carries the "Registration open"
  badge.

- **student2 — pending in a later campaign overrides an older rejection.**
  A second lecture, "Algebra und Zahlentheorie", with *two* campaigns:
  an older `:first_come_first_served`/`:completed` one the student was
  `:policy_rejected` from (like student3's scenario), and a later
  `:preference_based`/`:closed` reapplication where the student is still
  `:pending` a decision. Placed in the *next* term, like the
  pending/confirmed/open-unapplied lectures below: `:closed` alone does
  not survive `settle_current_term_campaigns!` in the current term, unlike
  `:completed`. `Registration::StatusQuery` pools registrations across all
  of a lecture's campaigns and applies one precedence order
  (confirmed > pending > open > rejected), so the dashboard shows "Pending"
  for this lecture, not "Rejected" - see `status_query_spec.rb` and
  `e2e/dashboard.spec.ts` ("registration status with multiple campaigns for
  one lecture") for the underlying precedence rules this demonstrates.

The pending/confirmed/open-unapplied/multi-campaign lectures are placed in
the *next* term (`Demo::TermSupport.next_term`), not the one the seed plays
in: `Seeds::BuildSupport#settle_current_term_campaigns!` discards any
non-`:completed` campaign (open, closed, processing, ...) on a lecture in
the current term on every rebuild, on the assumption that registration in a
term that has started is over. The two rejected lectures use `:completed`
campaigns, which survive that step, so they stay in the current term like a
real rejection by now would.

## Resulting dashboard state

| Student | Lecture | Band | Badge | Bookmark toggle | "x" removal |
|---|---|---|---|---|---|
| student1 | Einführung in die Numerik | Registered | Pending (hourglass) | yes | no |
| student2 | Maßtheorie und Wahrscheinlichkeit | Registered | Confirmed (check) | no | no |
| student3 | Algebraische Topologie | Registered | Rejected (x-circle) | yes | yes - "keep bookmarked" / "remove entirely" |
| student4 | Funktionalanalysis | Registered | Rejected (x-circle) | yes | yes - "keep bookmarked" / "remove entirely" |
| student5 | Diskrete Mathematik | Bookmarked | — | yes | yes - plain unbookmark |
| (search only) | Partielle Differentialgleichungen | not shown | (would show "Registration open" if surfaced) | — | — |
| student2 | Algebra und Zahlentheorie | Registered | Pending (hourglass) | yes | no |

The lecture search results (below the dashboard bands) show the same
four-state icon/label instead of a single generic green checkmark for
"registered" - see `Registration::StatusPresenter` and
`Registration::StatusQuery`, shared between the dashboard card and the
search result card. A pending or rejected search result still offers the
bookmark toggle, matching the dashboard's rule; only a confirmed
registration (or an actual self-enrolled group seat) removes it.

Each of the five students also keeps their existing plain roster
memberships from the shipped dump (e.g. "Lineare Algebra 2"), which cover
the plain "Registered" band with no badge - so that state did not need a
dedicated scenario here.

Verified against `rails seeds:build` on 2026-09-11: running the task twice
in a row leaves the same five registration rows in place (the module
resets each campaign from scratch, so re-running it is safe), and the
pending/confirmed/open-unapplied lectures survive
`settle_current_term_campaigns!` because they sit in the next term.
