#import "@preview/codly:1.3.0": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

// ---------- Style ----------
#let accent = rgb("#2f5d8a")
#let soft = rgb("#eef3f8")
#let muted = luma(115)
#let rule = luma(215)

#set document(title: "Notifications in MaMpf", author: "Claude Code")
#set page(
  paper: "a4",
  margin: (x: 1.9cm, top: 2cm, bottom: 1.8cm),
  header: context {
    if counter(page).get().first() > 1 {
      set text(7.5pt, fill: muted)
      [Notifications in MaMpf #h(1fr) Review & proposal]
      v(-0.6em)
      line(length: 100%, stroke: 0.4pt + rule)
    }
  },
  footer: context {
    set text(7.5pt, fill: muted)
    h(1fr)
    counter(page).display("1 / 1", both: true)
  },
)
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 9.8pt, lang: "en")
#set par(justify: true, leading: 0.58em, spacing: 0.85em)
#set list(indent: 0.3em, body-indent: 0.5em, spacing: 0.55em)
#set enum(indent: 0.3em, body-indent: 0.5em, spacing: 0.55em)

#show heading.where(level: 1): it => {
  v(0.4em)
  block(below: 0.7em)[
    #text(15pt, weight: "bold", fill: accent, it.body)
    #v(-0.55em)
    #line(length: 100%, stroke: 0.6pt + accent)
  ]
}
#show heading.where(level: 2): it => block(above: 1em, below: 0.5em,
  text(10.8pt, weight: "bold", fill: accent.darken(15%), it.body))

#show raw.where(block: false): it => box(
  fill: luma(244), inset: (x: 2.5pt), outset: (y: 2.5pt), radius: 2pt,
  text(size: 1.02em, it),
)
#show raw.where(block: true): set text(size: 7.6pt)

#show: codly-init.with()
#codly(
  languages: (ruby: (name: "Ruby", color: rgb("#b3261e"))),
  number-format: none,
  zebra-fill: none,
  fill: luma(250),
  stroke: 0.5pt + rule,
  radius: 4pt,
)

#let note(title: none, body) = block(
  width: 100%, fill: soft, inset: (x: 9pt, y: 7pt), radius: 3pt,
  stroke: (left: 2.2pt + accent),
)[
  #set text(9.2pt)
  #if title != none [#text(weight: "bold", fill: accent, title) #h(0.4em)]
  #body
]

#let small-table(..args) = {
  set text(8pt)
  set par(justify: false, leading: 0.45em)
  table(
    stroke: none,
    inset: (x: 4pt, y: 2.7pt),
    fill: (_, y) => if y == 0 { soft } else if calc.even(y) { luma(250) },
    ..args,
  )
}

// ---------- Title ----------
#block(below: 1.2em)[
  #text(8pt, fill: muted, tracking: 0.08em)[MAMPF · ARCHITECTURE NOTE · 24 NOV 2026]
  #v(-0.2em)
  #text(21pt, weight: "bold")[Notifications in MaMpf]
  #v(-0.6em)
  #text(11pt, fill: muted)[How the bell, the comment bubble and the mails work today — and where to take them]
]

= Part I — How it works today

MaMpf has no single notification system. "Something new for you" is spread over three
mechanisms that grew independently and do not know of each other, plus about ten mailers:
the *bell* (our `Notification` model), the *comment bubble* (`users.unread_comments` and
`Reader` watermarks around the Commontator gem) and *forum counts* (Thredded's read state).

#figure(
  {
    set text(7.6pt)
    diagram(
      spacing: (8mm, 1.2mm),
      node-corner-radius: 3pt,
      node-inset: 3.6pt,
      edge-stroke: 0.55pt + luma(140),
      node((0, 0), [`AnnouncementsController#create`], fill: white, stroke: 0.5pt + rule),
      node((0, 1), [`LecturesController#publish`], fill: white, stroke: 0.5pt + rule),
      node((0, 2), [`MediumPublisher#publish!` #text(fill: muted)[(action or cron)]],
        fill: white, stroke: 0.5pt + rule),
      node((0, 3), [`Voucher::Redeemer`], fill: white, stroke: 0.5pt + rule),
      node((0, 4), [`Commontator::CommentsController#create`], fill: white, stroke: 0.5pt + rule),
      node((0, 5), [`ReadersController` #text(fill: muted)[(× on /comments)]],
        fill: white, stroke: 0.5pt + rule),
      node((0, 6), [Thredded #text(fill: muted)[(opening a topic)]], fill: white, stroke: 0.5pt + rule),
      node((1, 1.5), [table `notifications` \ #text(fill: muted)[row = unread]], fill: soft,
        stroke: 0.6pt + accent),
      node((1, 4.5), [`users.unread_comments` \ + table `readers`], fill: soft, stroke: 0.6pt + accent),
      node((1, 6), [Thredded read states], fill: soft, stroke: 0.6pt + accent),
      node((2, 0.5), [Navbar bell, `/notifications`], fill: white, stroke: 0.5pt + rule),
      node((2, 2.5), [Dashboard badges, lecture home \
        #text(fill: muted)[comments & forum via `Dashboard::LectureActivity`]],
        fill: white, stroke: 0.5pt + rule),
      node((2, 4.5), [Navbar bubble, `/comments`], fill: white, stroke: 0.5pt + rule),
      ..range(0, 4).map(y => edge((0, y), (1, 1.5), "-|>")),
      edge((0, 4), (1, 4.5), "-|>"),
      edge((0, 5), (1, 4.5), "-|>"),
      edge((0, 6), (1, 6), "-|>"),
      edge((1, 1.5), (2, 0.5), "-|>"),
      edge((1, 1.5), (2, 2.5), "-|>"),
      edge((1, 4.5), (2, 4.5), "-|>"),
      edge((1, 4.5), (2, 2.5), "-|>"),
      edge((1, 6), (2, 2.5), "-|>"),
    )
  },
  caption: text(8pt, fill: muted)[Writers → state → readers. Mails branch off the writers (see table below).],
)

== The bell: `Notification`

`notifications(recipient_id, notifiable_type, notifiable_id, action)`, polymorphic. A row
means "unread"; reading it means *deleting* it — there is no `read_at` and no history.
Rows are written for four notifiable types:

- *Announcement* — `AnnouncementsController#create`, to `lecture.audience` (`LectureAudience`:
  bookmarks, rosters, running registrations, …) or to *every user* for MaMpf news.
- *Medium* — `MediumPublisher#publish!`, called by `MediaController#publish` or, for scheduled
  releases, by the `MediaPublisher` cron worker; to `media_scope.audience`.
- *Lecture* — `LecturesController#publish`, to *every user* ("new lecture").
- *Redemption* — `Voucher::Redeemer`, to the lecture's editors and teacher.

The first three fan-outs are near-identical copies (simplified), run inline in the request:

```ruby
users.touch_all                                   # keep HTTP caches fresh (see below)
Notification.import(users.map { |u|               # activerecord-import, one INSERT
  Notification.new(recipient: u, notifiable: record, action: "create") })
I18n.available_locales.each do |l|                # one bcc mail per locale
  ids = users.where(email_for_x: true, locale: l).pluck(:id)
  NotificationMailer.with(recipients: ids, locale: l, ...).x_email.deliver_later if ids.any?
end
```

*Read side.* The navbar partial `shared/_dropdown_notifications` loads all of the user's
notifications on every page (count + five newest). `NotificationsHelper` picks header, text,
link and color via `if/elsif` chains over the type; `Notification#path` does the same for the
URL. `User#active_notifications`, `#active_media_notifications` and `#active_news` feed the
dashboard badges, the lecture home and `/news`. Rows disappear via `NotificationsController`
(one, all, per lecture, per lecture's media, news), in `MediaController#show` and by
`dependent: :destroy`. In the browser, rails-ujs `data-remote` links and `notifications.coffee`
patch counters and `document.title` by hand. Writes also touch the user (`touch: true`,
`touch_all`, `current_user.touch`) because the lecture outline's HTTP cache uses
`current_user.updated_at` as stand-in for "notifications changed".

== The comment bubble: Commontator + `Reader`

Commontator 7 gives each `Medium` a thread. We vendored `Commontator::CommentsController`;
after a comment is saved it (1) calls the gem's `Subscription.comment_created`, which mails
all *thread subscribers*, and (2) sets `unread_comments = true` for the whole
`media_scope.audience` except the author (`update_unread_status`, one `UPDATE` per user).

- *Two watermarks for one thing.* `Reader(user, thread, updated_at)` is written *only* by
  `ReadersController` (× and "mark all" on `/comments`); opening the medium does not move it.
  Opening the medium does touch Commontator's own `Subscription` (`mark_as_read_for`), which
  only drives the "3/12" count on the thread's button.
- The flag is cleared when `ReadersController#anything_left?` finds nothing unread — a Ruby
  loop over all subscribed media with one `Reader.find_by` each.
- "Unread comments" is computed three ways: the eager flag (audience), `/comments` (Ruby,
  `User#media_with_latest_comments_not_by_creator`) and the dashboard
  (`Dashboard::LectureActivity`, one SQL query, also counts lectures you teach). They can
  disagree: a teacher outside the audience sees dashboard counts but never the bubble.
- Subscriptions are manual (`thread_subscription = :m`). The gem's mail is one bcc mail in the
  *commenter's* locale (`deliver_later` keeps the request's locale) and ignores `email_for_*`.

== Thredded

One messageboard per lecture (`lecture.forum_id`). `Thredded.notifiers = []`: the forum
sends no mail and creates no `Notification`. Only its read state is used, for unread-topic
counts on dashboard cards, lecture home and lecture sidebar.

== When mails are sent

`NM` = `NotificationMailer`, the `_email` suffix of methods is omitted; opt-outs are
`users.email_for_*` columns.

#small-table(
  columns: (1.45fr, 2.05fr, 1.1fr, 1.3fr),
  table.header([*Trigger*], [*Mailer / method*], [*To*], [*Opt-out* (`email_for_…`)]),
  table.hline(stroke: 0.5pt + accent),
  [Announcement posted], [`NM#announcement`], [audience / all], [`announcement` / `news`],
  [Medium published], [`NM#medium`], [audience], [`medium`],
  [Lecture published], [`NM#new_lecture`], [all users], [`teachable`],
  [Team invite], [`NM#submission_invitation`], [invitee], [—],
  [Hand-in uploaded / removed], [`NM#submission_upload`, `#submission_upload_removal`], [team],
  [`submission_upload`, `submission_removal`],
  [Team join / leave], [`NM#submission_join`, `_leave`, `_added`, `_removed`],
  [team, affected], [`submission_join`, `_leave`; affected: —],
  [Correction uploaded], [`NM#correction_upload`], [team], [`correction_upload`],
  [Hand-in accepted / rejected], [`NM#submission_acceptance`, `_rejection`], [team],
  [`submission_decision`],
  [Hand-in deletion (cron)], [`NM#submission_deletion…`, `_destruction…`], [students, editors],
  [—],
  [Became editor/tutor/teacher], [`LectureNotificationMailer` (`LectureNotifier`)],
  [person, old teacher], [—],
  [Roster changes, exam date], [`RosterNotificationMailer`], [student; tutors on moves],
  [tutors: `tutorial_change`],
  [Results published], [`Assessment::ResultsMailer`], [participants], [—],
  [Message to groups], [`StudentMessageMailer`], [chosen groups], [none, deliberately],
  [New comment], [`Commontator::SubscriptionsMailer`], [subscribers], [unsubscribe only],
)

Three delivery styles coexist (bcc per locale, one mail per recipient, Commontator's single
bcc mail), `deliver_now` sits next to `deliver_later`, and only a few places
(`SubmissionsController`, `AllocationMaterializer`) wait for the commit.

== Good to know

- *Dead code:* `users.no_notifications` (only in the data export), `notifications.action`
  (always `"create"`), the `Course` notification type (handled in model and helper, never
  created), the unused argument of `Notification#path(_user)`.
- *Scale:* a new lecture or a MaMpf news item inserts one row *per user in the database*,
  synchronously in the request. The navbar query and its N+1 on `notifiable` run on every page;
  `User#active_news` filters all announcement notifications in Ruby.
- `LectureNotifier` (staff-change mails) lives in `app/controllers/` but is no controller.
- `Extensions::Commontator::CommentPatch#tables_present?` checks for `thredded_topics`
  instead of a Commontator table (copy-paste slip).

#pagebreak()

= Part II — Proposal

#note(title: "Decision.")[Separate three concepts that are mixed today, adopt the
#link("https://github.com/excid3/noticed")[`noticed`] gem (v2) for the first one, and derive
the second one instead of fanning it out.]

+ *Notifications* — an event addressed to a person: announcement, new medium, hand-in and
  roster changes, results, voucher redeemed, reply in a thread you subscribed to.
+ *Read state* — "what's new since I last looked" in places you follow: comments, forum
  topics, MaMpf news, new lectures. Computed from watermarks, never one row per user.
+ *Delivery & preferences* — in-app, email, later digest. Decided per notification kind,
  in one place.

== Backend

*Why `noticed`.* Its v2 schema is exactly the split we need: `noticed_events` (one row per
event, `record` polymorphic, `params` jsonb) and `noticed_notifications` (one per recipient,
with `read_at` / `seen_at`). Each kind becomes a notifier class with its delivery methods and
per-recipient conditions; delivery runs through ActiveJob/Sidekiq. It is a small, maintained
Rails gem — less code than our own and no new infrastructure. The `if/elsif` chains in
`Notification` and `NotificationsHelper` move into the notifier of each kind:

```ruby
class NewMediumNotifier < ApplicationNotifier       # ApplicationNotifier < Noticed::Event
  deliver_by :email do |config|
    config.mailer = "MediumMailer"
    config.method = :published
    config.if = -> { recipient.notification_setting(:new_medium, :email) }
  end

  notification_methods do
    def message = I18n.t("notifications.new_medium", title: record.title_for_viewers)
    def url = Rails.application.routes.url_helpers.medium_path(record)
  end
end

# MediumPublisher#publish! — replaces create_notifications! and send_notification_email!
NewMediumNotifier.with(record: @medium).deliver(@medium.teachable.media_scope.audience)
```

- *All mails go through notifiers*, including submission, roster, staff-change and results
  mails. Transactional ones (deletion warnings, roster, results) are simply notifiers without
  an opt-out. This gives us one list of "what can reach a user", an in-app entry for each mail,
  one mail per recipient in *their* locale, and delivery after commit everywhere. Check the
  SMTP rate limit: an audience of 800 becomes 800 mails instead of two bcc mails; throttle the
  `mailers` queue if needed.
- *Preferences:* replace the 11 `email_for_*` booleans and the dead `no_notifications` by one
  `notification_settings` jsonb on `users` (`{"new_medium": {"email": true}}`), defaults in the
  notifier class. The profile page renders its toggles from the list of notifiers, so a new
  kind shows up there automatically. Migrate the current booleans once.
- *Broadcasts without fan-out:* MaMpf news and new lectures get no per-user rows. Store the
  announcement / lecture once and compare its timestamp with a watermark on the user
  (`news_seen_at`, `lectures_seen_at`). The "new lecture" bell entry goes away; the dashboard's
  lecture search highlights lectures newer than the watermark. Opt-in mails for both remain,
  sent from a job in batches.
- *Comments:* drop `users.unread_comments` and the code that sets it. One query object
  (extracted from `Dashboard::LectureActivity#unread_comments_scope`) answers "unread comments"
  for the bubble, `/comments` and the dashboard, so they cannot disagree any more.
  `MediaController#show` touches the `Reader`, i.e. reading marks as read; `Reader` becomes the
  only watermark (it also covers non-subscribers, Commontator's does not). In our
  vendored controller, replace `Commontator::Subscription.comment_created` by a
  `NewCommentNotifier` for the thread's subscribers — it then respects preferences and locale.
- *Thredded* stays as is (read state only). Should we want forum mails later, Thredded accepts
  custom notifiers (`Thredded.notifiers = [...]`) that can hand over to our notifiers.
- *Housekeeping:* a cron job deletes read notifications older than six months; notifiables
  declare `has_many :noticed_events, as: :record, dependent: :destroy,
  class_name: "Noticed::Event"`. Replace
  `current_user.updated_at` in the lecture outline's `stale?` by the newest
  `notifications.updated_at` of the user and remove all user `touch` calls.

== Frontend and the user's view

Today a student checks a bell (some things, cleared by ×), a bubble (cleared only on
`/comments`, even after reading the thread), dashboard badges, the megaphone and emails in
mixed languages with partial opt-outs. Afterwards:

- *Bell = inbox "for you".* The navbar renders only `unread.count`; the dropdown is a lazy
  `turbo_frame_tag "notifications", src: notifications_path, loading: :lazy`. Clicking an
  entry goes through `/notifications/:id/open`, which marks it read and redirects. "Mark all as
  read" is a `button_to` answered by a Turbo Stream that replaces the badge. This removes
  `notifications.coffee` and the rails-ujs links here.
- *Looking at something marks it read:* a small `mark_notifications_read_for(record)` in the
  controllers of announcements, media and submissions, the generalized version of what
  `MediaController#show` already does.
- *Bubble = activity,* computed by the same query as the dashboard badge and cleared by reading.
- *Profile:* one table "kind × channel" instead of scattered checkboxes.
- *Later, if wanted:* live badge via `turbo_stream_from [current_user, :notifications]` (needs
  Action Cable, which we do not run yet) and a daily digest channel for media and comments.

== Rollout

Each step ships on its own and keeps the old behavior working until it is replaced.

+ Add `noticed`, port the medium, announcement and redemption notifications; copy unread rows
  in a data migration; new bell UI. Rename the old association (`has_many :notifications`
  clashes), then drop the old table, the `Course`/`Lecture` types and the helper chains.
+ Broadcast watermarks for news and new lectures.
+ Move submission, roster, staff and results mails into notifiers; `notification_settings`.
+ Comments: shared unread query, mark-as-read on view, `NewCommentNotifier`; drop
  `unread_comments`.

*Not now:* replacing Commontator or Thredded (separate project; this plan keeps them as data
sources only), push notifications, our own event bus.
