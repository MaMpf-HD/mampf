# Dashboard registration-state demo data

Creates a demo student account with one lecture for each registration
transition state the dashboard now distinguishes, so the states can be
seen in the UI without waiting for real registration campaigns to reach
them. Written down here so this can later be folded into `db/seeds.rb`.

Run with:

```
RAILS_ENV=development bundle exec rails runner path/to/script.rb
```

(needs FactoryBot, which is already a development/test dependency; the
script falls back to loading factory definitions if they are not loaded
yet, which is the case outside of the test environment).

## The demo user

```ruby
require "factory_bot"
FactoryBot.find_definitions unless FactoryBot::Internal.factories.any?

demo = User.find_by(email: "dashboard.demo@mampf.test") ||
       FactoryBot.create(:confirmed_user,
                         email: "dashboard.demo@mampf.test",
                         name: "Dana Demo",
                         password: "dashboard-demo-password-2026")
```

Sign in directly, or use the "Switch user (dev only)" dropdown in the
navbar (visible in development) to impersonate `Dana Demo` from an admin
account.

## The lectures

```ruby
term = Term.active

def lecture_for(title, term)
  FactoryBot.create(:lecture, :released_for_all, term: term,
                    course: FactoryBot.create(:course, title: title,
                                              short_title: title.first(12)))
end

# a) Plain roster membership, no registration campaign at all.
# Shows in "You are registered for these" with no status badge.
enrolled_plain = lecture_for("Analysis III", term)
FactoryBot.create(:lecture_membership, user: demo, lecture: enrolled_plain)

# b) Pending registration, no roster seat yet.
# Shows in "You are registered for these" with the hourglass "Pending"
# badge. Still bookmarkable/unbookmarkable.
#
# The campaign must be :preference_based, not the default
# first-come-first-served: FCFS decides synchronously (confirmed or
# rejected right away), so a *pending* FCFS row is not a state the app's
# own UI ever produces or has anything to show for - clicking into such a
# lecture would display nothing, which looks like a bug but is really just
# an unrealistic combination. A preference-based campaign is what actually
# stays pending until the teacher finalizes it, and the lecture's own home
# tab then shows the student's submitted preference ranking.
pending_lecture = lecture_for("Einfuehrung in die Numerik", term)
pending_campaign = FactoryBot.create(:registration_campaign, :open,
                                     :preference_based,
                                     campaignable: pending_lecture)
FactoryBot.create(:registration_user_registration, :pending,
                  user: demo,
                  registration_campaign: pending_campaign,
                  registration_item: pending_campaign.registration_items.first,
                  preference_rank: 1)

# c) Confirmed registration, not yet rostered.
# `Registration::UserRegistration` confirming an applicant does not by
# itself create a `LectureMembership` - rostering is a separate step. This
# is the gap the dashboard used to fall into: without this fix, a
# confirmed-but-not-yet-rostered lecture was invisible on the dashboard.
# Shows the check-mark "Confirmed" badge; no longer bookmarkable/
# unbookmarkable.
#
# Known limitation, not fixed here: because no roster/tutorial-membership
# row exists for this made-up case, the lecture's own home tab shows
# nothing about the confirmation either (RosterizedEntriesComponent reads
# actual roster entries, not Registration::UserRegistration directly). In
# the real app this window is normally short - confirmation is followed by
# rostering - so this is a demo-data artifact, not a new bug.
confirmed_lecture = lecture_for("Masstheorie und Wahrscheinlichkeit", term)
confirmed_campaign = FactoryBot.create(:registration_campaign, :open,
                                       campaignable: confirmed_lecture)
FactoryBot.create(:registration_user_registration, :confirmed,
                  user: demo,
                  registration_campaign: confirmed_campaign,
                  registration_item: confirmed_campaign.registration_items.first)

# d) Rejected registration, not dismissed.
#
# The campaign must be :completed, not just :closed:
# - Lecture#registration_status_for only reports :rejected once the
#   campaign is no longer open for registrations (see the "open beats
#   rejected" precedence there) - :closed alone is enough for that.
# - But the lecture's own home tab only explains *why* via
#   RosterizedEntriesComponent#policy_rejected_campaigns, which
#   specifically requires status: :completed. A :closed campaign leaves
#   the dashboard badge correct but the lecture page blank - looks like a
#   bug, but is really just an unrealistic combination again (in the real
#   app a campaign is closed only briefly, on its way to :completed).
# - Use the :policy_rejected trait (not :capacity_rejected): the
#   lecture-page notice for a *capacity* rejection only exists for
#   preference_based campaigns; a first-come-first-served capacity
#   rejection (this campaign's default allocation mode) has no notice
#   anywhere on the lecture page at all - a genuine gap in the app, out of
#   scope here. :policy_rejected renders regardless of allocation mode.
rejected_lecture = lecture_for("Algebraische Topologie", term)
rejected_campaign = FactoryBot.create(:registration_campaign, :completed,
                                      campaignable: rejected_lecture)
FactoryBot.create(:registration_user_registration, :policy_rejected,
                  user: demo,
                  registration_campaign: rejected_campaign,
                  registration_item: rejected_campaign.registration_items.first)

# e) Rejected registration, but the user separately bookmarked the lecture
# too. Still shown once, in "You are registered for these" (registration
# status takes precedence over a plain bookmark) - not duplicated into
# "You bookmarked these".
rejected_bookmarked_lecture = lecture_for("Funktionalanalysis", term)
rejected_bookmarked_campaign = FactoryBot.create(:registration_campaign, :completed,
                                                 campaignable: rejected_bookmarked_lecture)
FactoryBot.create(:registration_user_registration, :policy_rejected,
                  user: demo,
                  registration_campaign: rejected_bookmarked_campaign,
                  registration_item: rejected_bookmarked_campaign.registration_items.first)
demo.subscribe_lecture!(rejected_bookmarked_lecture)

# f) Plain bookmark, no registration campaign at all.
# Shows in "You bookmarked these" with the plain bookmark "x".
bookmarked_lecture = lecture_for("Diskrete Mathematik", term)
demo.subscribe_lecture!(bookmarked_lecture)

# g) Registration open, user has not applied yet.
# Does not show on the dashboard at all today (neither roster nor
# bookmark nor an application exists yet) - it is only discoverable via
# lecture search, where it would carry the "Registration open" badge.
open_lecture = lecture_for("Partielle Differentialgleichungen", term)
FactoryBot.create(:registration_campaign, :open, campaignable: open_lecture)
```

## Resulting dashboard state

| Lecture | Band | Badge | Bookmark toggle | "x" removal |
|---|---|---|---|---|
| Analysis III | Registered | — | n/a (roster member) | no |
| Einfuehrung in die Numerik | Registered | Pending (hourglass) | yes | no |
| Masstheorie und Wahrscheinlichkeit | Registered | Confirmed (check) | no | no |
| Algebraische Topologie | Registered | Rejected (x-circle) | yes | yes - "keep bookmarked" / "remove entirely" |
| Funktionalanalysis | Registered | Rejected (x-circle) | yes | yes - "keep bookmarked" / "remove entirely" |
| Diskrete Mathematik | Bookmarked | — | yes | yes - plain unbookmark |
| Partielle Differentialgleichungen | not shown | (would show "Registration open" if surfaced) | — | — |

The lecture search results (below the dashboard bands) now show the same
four-state icon/label instead of a single generic green checkmark for
"registered" - see `Registration::StatusPresenter` and
`Registration::StatusQuery`, shared between the dashboard card and the
search result card. A pending or rejected search result still offers the
bookmark toggle, matching the dashboard's rule; only a confirmed
registration (or an actual self-enrolled group seat) removes it.

Verified against the running dev server on 2026-09-11 with Playwright:
signing in as `dashboard.demo@mampf.test` renders exactly this layout;
clicking into "Einfuehrung in die Numerik" (pending) shows the student's
submitted preference ranking, and clicking into "Algebraische Topologie" /
"Funktionalanalysis" (rejected) shows the actual rejection notice on the
lecture's home tab. Dismissing "Funktionalanalysis" via "Keep in
bookmarked lectures" moves it from "Registered" to "Bookmarked" with its
rejection notice gone, as designed.
