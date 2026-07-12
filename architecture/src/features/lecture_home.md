# Lecture Home Page

## Problem Overview

Every lecture exposes two front-facing pages:

- the **content page** — `GET /lectures/:id` (`LecturesController#show`), the media/outline catalog (chapters → sections → media); and
- the **lecture home page** — `GET /lectures/:id/home` (`Lectures::HomeController#show`), the newer per-lecture "front door" that hosts news and the registration workflow.

Which one a user first lands on is decided by a single subscription check in `LecturesController#check_for_subscribe`:

```ruby
# filepath: app/controllers/lectures_controller.rb
def check_for_subscribe
  return if @lecture.in?(current_user.lectures)   # subscribed  → content page
  return if current_user.can_edit?(@lecture)      # staff       → content page
  redirect_to lecture_home_path(@lecture)         # everyone else → lecture home
end
```

This uses *"are you subscribed?"* as a proxy for two unrelated questions — **do you have content access?** and **which page should be your home base?** Conflating them produces three concrete problems:

1. **Freshly subscribed → empty content page.** The moment a `LectureUserJoin` exists, the user is routed to the content page unconditionally, even when the lecture has no released media yet. New subscribers can land on a blank catalog.
2. **Subscribers stop seeing registration updates.** Subscription permanently routes past the home page, but the registration campaign block lives *only* on the home page. A subscriber never revisits it, so time-sensitive changes there — e.g. a spot freeing up in an open first-come campaign, or a self-materialization slot opening after finalization — go unnoticed.
3. **The home page is thin.** It renders only a header, a news card (announcements/forum, and only when non-empty), a subscribe hint, and the registration block. It carries **no teacher-authored content**, so outside an open campaign or a fresh announcement it is nearly empty — even though it is the very page prospective students see *before* deciding to subscribe or register.

```admonish note "Root cause"
The home page isn't rich enough to be worth returning to, and the routing
treats "subscribed" as "always skip home." The three symptoms above are two
sides of the same gap.
```

## Current State (as implemented)

The lecture home page (`app/frontend/lectures/home/lecture_home.html.erb`, rendered by `Lectures::HomeController`) is composed of:

| Section | Shown when | Source |
|---|---|---|
| Lecture header (title/term, teacher, edit pencil) | always | `@lecture`, staff for the pencil |
| News card (announcements + unread forum) | there is news | `lectures/show/_news_card` |
| Subscribe hint (+ passphrase field) | non-subscriber, non-staff | `@passphrase_required` |
| Registration workflow block (campaigns) | `@show_workflow_content` | `user_registrations/_user_registration` → `CampaignCardComponent` |
| "Start here" fallback card | nothing else to show | locale `lecture.home.empty_*` |

Access to the page is governed by `RegistrationUserRegistrationAbility` (`can :index, Lecture` for published lectures, plus staff/admin), and registration is deliberately **decoupled** from content access (subscription).

The only existing teacher-editable rich text on a lecture, `Lecture#organizational_concept` (a Trix field), is surfaced on a *separate* organizational page (`lecture_organizational_path`), **not** on the home page.

## Solution: A Richer Front Door

Give teachers a dedicated place to author a short welcome / organizational note and attach a program (e.g. a seminar schedule as a PDF), rendered at the **top of the lecture home page, above the registration block**, and only when filled in.

Concretely, for a seminar a teacher could write a few introductory words, explain that a registration is running, and attach the seminar program — with the live campaign shown directly below.

### Data model

```admonish info "New fields on Lecture"
- `home_intro` — a Trix **rich-text** column (`t.text "home_intro"`) for a short
  welcome / organizational note.
- `home_attachment` — an **optional PDF** managed by a Shrine uploader
  (`t.text "home_attachment_data"`), for a course/seminar program.
```

The PDF reuses the established Shrine pattern — the most recent, self-contained example is `StudentMessageUploader` (the campaign-mail attachment):

```ruby
# filepath: app/uploaders/lecture_home_attachment_uploader.rb  (mirror of StudentMessageUploader)
class LectureHomeAttachmentUploader < Shrine
  MAX_SIZE = 10 * 1024 * 1024
  plugin :determine_mime_type, analyzer: :marcel
  plugin :validation_helpers
  Attacher.validate do
    validate_min_size 1
    validate_max_size MAX_SIZE
    validate_mime_type_inclusion(["application/pdf"])
  end
end

# filepath: app/models/lecture.rb
include LectureHomeAttachmentUploader[:home_attachment]
```

```admonish tip "Why a dedicated field, not organizational_concept?"
`organizational_concept` already owns the organizational page and tends to hold
long, formal content. A separate `home_intro` keeps the two purposes distinct: a
short front-door welcome vs. a full organizational write-up. It avoids
double-booking one field across two pages and lets each evolve independently.
```

### Rendering

- A new block at the top of `lecture_home.html.erb`, above the registration workflow, rendering `sanitize(lecture.home_intro)` and, if attached, a download link/preview for `home_attachment`.
- The block renders **only when at least one of the two is present**, so an unused feature never adds an empty card (consistent with how the news card and campaign block already gate themselves).
- Editing happens in the existing lecture edit UI (a Trix editor for `home_intro` and a `file_field ..., accept: "application/pdf"` for the attachment), mirroring `app/frontend/lectures/edit/_organizational_concept.html.erb` and `_student_mail.html.erb`.

```admonish note "Implemented approach"
- **Authoring** lives in a dedicated **"Home" tab** on the lecture edit page
  (`app/frontend/lectures/edit/_home.html.erb`), kept distinct from the "Orga"
  tab so `home_intro` and `organizational_concept` don't get confused.
- **Feedback / nudge** is the *cheaper* variant: the home page renders the
  intro (or a staff-only empty-state placeholder — stronger when a campaign is
  live) with an edit pencil that **jumps to the Home tab**, rather than full
  inline WYSIWYG editing on the page itself. WYSIWYG stays a later upgrade if
  this proves insufficient.
- The PDF is streamed by an authorized `Lectures::HomeController#attachment`
  action (`send_data`), gated exactly like the home page.
```

This also improves the page for the audience that currently sees the thinnest version of it — **prospective students**, for whom the home page is the "shop window" that informs the decision to subscribe or register.

## Page composition — who sees what

The page composes differently for students and staff, because the registration
block is *personal* to each student:

| Block | Student | Staff |
|---|---|---|
| Intro (`home_intro` + PDF) | yes, when authored | yes, plus an edit pencil |
| "Your home page is empty" nudge | no | when no intro is authored |
| Registration block (campaigns + **their own** status: open registrations, assigned group) | yes | **no** — it is per-student |
| "What students see here" note (live campaigns + link to manage them) | no | when the lecture has campaigns |
| "Start here" fallback | when the page is genuinely empty | never (the two above cover staff) |

The staff note exists because staff would otherwise see *nothing* where students
see the whole registration block — and conclude the page is empty, which is
especially misleading since the editor's Home tab links them here.

```admonish warning "`@show_workflow_content` is a permission flag, not a has-content flag"
`@show_workflow_content = can?(:create, lecture) || rosterized.any? || self_rosterables.any?`,
and `student_registration_participant?` is simply *"published lecture and not staff"*. So it is:

- **true for every student**, even when the lecture has no campaign at all, and
- **false for all staff**, who may never register.

Keying UI off it produced two bugs: the "start here" fallback was unreachable
for students (and, absurdly, only ever rendered for staff — with
student-oriented copy), and staff saw nothing where students get the entire
registration block.

Gate on **actual content** instead — `@campaigns_details.any? || @rosterized_entries.any? || @self_rosterables.any?`.
Note `@campaigns_details` *is* populated for staff: `UserRegistrations::LectureCampaignsService`
returns every non-draft campaign and does not filter by user.
```

## Landing Logic — the home page as the front door

### Why subscription alone is a broken criterion

The original rule was *"subscribed → content, otherwise → home"*. It looks like a
lifecycle proxy, but it breaks exactly where it matters most:

- A student lands on home, where we offer **both** "subscribe" and "register".
  They subscribe — and from that moment we route them to the content page, away
  from the very page where their registration status appears: *"you were assigned
  to group X"*, *"to be finalized you still need to satisfy …"*, *"your
  registration was rejected"*. **Deadline-bound, consequential information on a
  page they no longer visit** — reached via a button we ourselves offered.
- The same holds for anyone who subscribed **before** a campaign opened: they
  never see it at all.

And there is no safety net: the sidebar's home badge counts
`active_notifications + unread_forum_topics` only — **campaign events create no
notifications whatsoever**, so a subscriber gets *zero* signal about registration
state. A passive badge would in any case be too weak for information that can
cost a student their seat.

### The implemented rule

For **opted-in terms**, the home page is the front door for *everyone* —
subscribers included. Staff still go straight to content (they reach home from
the editor's Home tab).

```ruby
# filepath: app/controllers/lectures_controller.rb
def home_is_landing_page?
  @lecture.term.present? &&
    Flipper.enabled?(:lecture_home_landing, @lecture.term)
end
```

Terms are opted in as **data**, not code — `Term` responds to `#flipper_id` out
of the box, so it works directly as a Flipper actor:

```ruby
Flipper.enable_actor(:lecture_home_landing, Term.find_by(year: 2026, season: "WS"))
Flipper.disable(:lecture_home_landing)   # kill switch — clears all gates, incl. actors
```

```admonish warning "Do NOT express this relative to `Term.active`"
The obvious-looking rules (*"the active term"*, *"the active or next term"*) are
all wrong, because **the cut is a one-off event (the MÜSLI rollout), not a
seasonal pattern**:

- **Today** (`Term.active` = SS 2026): WS 2026/27 is the *next* term and must land
  on home — while SS 2026, the *active* one, must **not** (nothing MÜSLI-related
  happens there; its content page stays the entry point).
- **From 1 Oct 2026**: WS 2026/27 becomes the *active* term and must **still**
  land on home (lectures only start on 15 Oct, registrations are still running,
  and the home page stays the hub during the term).

So the rule must say *"next, not active"* today and *"active"* later — no
criterion relative to `Term.active` can do both. Naming the terms explicitly is
not a hack; it is the only formulation that expresses the actual intent.
```

```admonish danger "`lecture_path` does double duty — keep the `outline` bypass"
`lecture_path` is used for **two different intentions**:

- the generic **entry** link ("the lecture") — start page cards, search results;
- the link to the **outline** — the sidebar's *Overview* item and the "start here"
  button on the home page itself.

Only the first may be redirected. Without a bypass the sidebar's outline link
bounces straight back to home and **the content page becomes unreachable for
every student in an opted-in term** — the media catalogue, of all things. (The
other sidebar entries — script, exercises, quizzes … — have their own routes and
are unaffected, since `check_for_subscribe` only hooks `:show`.)

Hence the outline links pass `outline: true`, and `#home_is_landing_page?` returns
false when that param is present. The sidebar's active-class still works, because
`get_class_for_path` compares `request.path` — the query string is not part of it.
```

Nothing is thereby decided about later terms (SS 2027 registrations open in
Feb 2027). By then the [Student Dashboard](student_dashboard.md) is expected to
have superseded the question — which is precisely why no general rule is baked
into the code.

```admonish note "Why a feature flag, and why the landing subsumes the alternatives"
The flag makes the change **revertible in seconds, without a deploy** — the
platform is in flux and this is an interim measure.

It also makes the cheaper fixes unnecessary *for now*: if students land on home
anyway, **the landing is the signal**. That single change covers the missed
campaign, the missed allocation status *and* the missed eligibility deadline —
which otherwise would have required campaign notifications, state-based routing
and a banner. Those become necessary again only once home stops being the
default entry (i.e. with the dashboard).

Still open, deliberately: **deep links** to sub-pages (`/lectures/:id/script`, …)
bypass the redirect. Once deadlines live on the home page, a banner on the
lecture sub-pages will be worth adding.
```

## Relationship to the Student Dashboard

This feature is intentionally **interim**: it improves the per-lecture experience *before* the [Student Dashboard](student_dashboard.md) exists, and it remains useful *after* the dashboard ships. The two occupy different levels of the information architecture:

| | **Student Dashboard** (future) | **Lecture Home Page** (this) |
|---|---|---|
| Scope | **Cross-lecture** — the global landing that replaces `main/start` | **Per-lecture** — one lecture's front door |
| Role | Aggregates *"where is activity?"* across all courses (the "What's Next?" widget lists open `Registration::Campaign`s and deadlines) | Hosts the *actual* per-lecture intro, program, and campaign UI |
| Direction | Points **into** lectures (deep-links to a campaign / lecture home) | Is a **destination** those links resolve to |

```admonish info "Division of responsibility"
The dashboard answers *"which of my lectures need my attention right now?"* and
links inward. The lecture home page answers *"what is this lecture about, and
what do I do here?"* — the welcome text, the program PDF, and the live campaign
live here, not on the dashboard.
```

Consequences for sequencing:

- **Durable now, safe to build:** the `home_intro` + PDF content is purely per-lecture and is **not** obsoleted by the dashboard — it is exactly the destination the dashboard's "What's Next?" links will resolve to.
- **Keep light:** the "registration activity" nudge (companion improvement #2) is genuinely centralized by the dashboard later. Build only a per-lecture banner now; do **not** invest in cross-lecture registration-status machinery — that is the dashboard's job (see the dashboard's [phased plan](student_dashboard.md#6-phased-implementation-strategy), Phase B "Open Registrations" widget).
- **Superseded later:** any manual "front page" toggle would be superseded by the dashboard + lifecycle routing, which is a further reason to omit it.

```admonish tip "One-line summary"
Make the lecture home page a genuine front door (teacher intro + program +
campaign), and stop treating "subscribed" as "always skip home." The dashboard
will later own the cross-lecture overview; the lecture home page stays the
per-lecture destination it links to.
```

## Layout sketch

```mermaid
graph TD
    subgraph "Lecture Home Page (proposed)"
        direction TB
        H["Lecture header (title / term / teacher)"]
        I["<b>Home intro</b> (teacher rich text)<br/>+ program PDF — NEW, top of page"]
        N["News card (announcements / forum)"]
        R["Registration campaign block<br/>(CampaignCardComponent)"]
        H --> I --> N --> R
    end
```

## Key references

- Routing gate: `app/controllers/lectures_controller.rb` (`check_for_subscribe`)
- Home page: `app/controllers/lectures/home_controller.rb`, `app/frontend/lectures/home/lecture_home.html.erb`
- Home page access gate: `app/abilities/registration_user_registration_ability.rb` (`can :index, Lecture`)
- Existing teacher rich text (separate page): `app/frontend/lectures/edit/_organizational_concept.html.erb`, `app/frontend/lectures/organizational/_organizational.html.erb`
- PDF-attachment pattern to mirror: `app/uploaders/student_message_uploader.rb`, `app/frontend/lectures/edit/_student_mail.html.erb`
- Front-door copy: `config/locales/registration/en.yml` (`lecture.home.*`)
- Future landing: [Student Dashboard](student_dashboard.md)
