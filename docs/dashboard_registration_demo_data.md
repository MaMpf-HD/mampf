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
pending_lecture = lecture_for("Einfuehrung in die Numerik", term)
pending_campaign = FactoryBot.create(:registration_campaign, :open,
                                     campaignable: pending_lecture)
FactoryBot.create(:registration_user_registration, :pending,
                  user: demo,
                  registration_campaign: pending_campaign,
                  registration_item: pending_campaign.registration_items.first)

# c) Confirmed registration, not yet rostered.
# `Registration::UserRegistration` confirming an applicant does not by
# itself create a `LectureMembership` - rostering is a separate step. This
# is the gap the dashboard used to fall into: without this fix, a
# confirmed-but-not-yet-rostered lecture was invisible on the dashboard.
# Shows the check-mark "Confirmed" badge; no longer bookmarkable/
# unbookmarkable.
confirmed_lecture = lecture_for("Masstheorie und Wahrscheinlichkeit", term)
confirmed_campaign = FactoryBot.create(:registration_campaign, :open,
                                       campaignable: confirmed_lecture)
FactoryBot.create(:registration_user_registration, :confirmed,
                  user: demo,
                  registration_campaign: confirmed_campaign,
                  registration_item: confirmed_campaign.registration_items.first)

# d) Rejected registration, not dismissed.
# The campaign must be *closed* (not open for registrations): while a
# campaign is still open, a rejected applicant could simply reapply, so
# `Lecture#registration_status_for` reports `:open` rather than
# `:rejected` in that case (see the "open beats rejected" precedence
# there). Shows the x-circle "Rejected" badge plus the small "x" removal
# corner (see below).
rejected_lecture = lecture_for("Algebraische Topologie", term)
rejected_campaign = FactoryBot.create(:registration_campaign, :closed,
                                      campaignable: rejected_lecture)
FactoryBot.create(:registration_user_registration, :rejected,
                  user: demo,
                  registration_campaign: rejected_campaign,
                  registration_item: rejected_campaign.registration_items.first)

# e) Rejected registration, but the user separately bookmarked the lecture
# too. Still shown once, in "You are registered for these" (registration
# status takes precedence over a plain bookmark) - not duplicated into
# "You bookmarked these".
rejected_bookmarked_lecture = lecture_for("Funktionalanalysis", term)
rejected_bookmarked_campaign = FactoryBot.create(:registration_campaign, :closed,
                                                 campaignable: rejected_bookmarked_lecture)
FactoryBot.create(:registration_user_registration, :rejected,
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

Verified against the running dev server on 2026-09-11 with Playwright:
signing in as `dashboard.demo@mampf.test` renders exactly this layout,
and dismissing "Funktionalanalysis" via "Keep in bookmarked lectures"
moves it from "Registered" to "Bookmarked" with its rejection notice
gone, as designed.
