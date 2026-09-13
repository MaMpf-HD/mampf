# Seed data files

The content core of the development seed data, written out of a seeded
database by `rails seeds:extract` (see `db/seeds/support/seeds/extract_support.rb`) and from
here on maintained by hand. This is the first half of moving the seed from an
SQL dump to a script: what the app is filled with lives in the repository,
where it can be reviewed and diffed, instead of in a binary artifact that each
build inherits from the last one.

Loaded by `db/seeds/010_content.rb` via `Seeds::LoadSupport`
(`db/seeds/support/seeds/load_support.rb`), the write side of this pair.

## Format

One file per group of records. A group other records point at is a mapping of
label to attributes:

```yaml
ss_2026:
  year: 2026
  season: SS
```

A group nothing points at -- join rows, mostly -- is a plain sequence:

```yaml
- tag: tags/scalar_product
  related_tag: tags/unitary_space
```

- **Labels** name a record after what it is (`la_2_lecture_ss2026`), never
  after its primary key. A name two records share is counted out (`_2`, `_3`).
- **References** read `<file>/<label>`, so a polymorphic one says what kind of
  record it points at without a second column.
- **Timestamps and the primary key** are left out; the loader sets them.
- **`attachments`** names the file a record was uploaded with. The file itself
  is not here -- the uploads are published beside the dump, and giving the seed
  a small set of fixture files of its own is a step of its own.
- **`translations`** carries what Mobility keeps in a table of its own.
- **`serialized`** marks a column the app stores as serialized Ruby (a quiz
  graph, a solution). There is no readable form of those, so what the database
  held is carried over verbatim.

## How the loader reads this

- **Dates** are the ones the dump carried, and only mean anything against the
  term the data was in on the day of extraction; `_meta.yml` records both.
  The loader shifts every date/datetime column (Term included) by the same
  number of whole semesters that separate `_meta.yml`'s `active_term` from
  today's calendar term, so the seed never goes stale.
- **The `serialized` blobs** (quiz graphs, question solutions) are opaque:
  the loader writes them back to the column unchanged, bypassing its coder,
  rather than decoding and re-encoding a value nothing here reads.
- **What is not here** belongs to the demo scenarios in
  `db/seeds/support/scenarios/`, which
  generate it on every run: the students they make up, tutorials, rosters,
  submissions, campaigns, forum posts, notifications. `_meta.yml` counts the
  rows that were dropped for pointing at one of them -- ten talks assigned to
  seminar students the scenarios create.
