# To Verify

Open points to recheck with the staff or in the old system. Each item links to where it comes from; when an item is answered, update that doc and tick it here.

## 1. Roles

Decided: one role `dean_of_studies` (faculty‑wide) plus the per‑description assignment `responsible_user_id` for lecturers (not a role) → [Roles & Permissions](00c-roles-and-permissions.md). Remaining assumptions are marked ⚑ there. To check:

- [ ] **Lecturer edits which descriptions?** Assumed: only those assigned to them (`responsible_user_id`) **and** not `published`. (The SoSe 2026 Dozent list IAML, IFML, MD1, MLC*, MLS*, MM*, SC* … fits "not released yet".) → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] **How did a description reach the old Dozent list?** Assumed: created centrally (semester copy or StudDekanin), then shown to the lecturer. Was the old Dozent `Neu` / `copy` / `delete` actually used? The new system drops them for lecturers.
- [ ] **Lecturer and status:** may an assigned lecturer mark a text as done (e.g. set `checked`), or only edit? Assumed: only edit.
- [ ] Is a **read‑only role** (e.g. Prüfungsamt, Studienberatung reading drafts) needed? Assumed: no, published content via public pages is enough.
- [ ] Who creates `Term`s in the host system? The target term must exist before "Prepare a term". → [Base Data](02-base-data.md#term-mampf-reused)
- [ ] Course Source "03 / 04 durch Dozent": set automatically when a Dozent saves? → [Old Handbook System](00b-old-handbook-overview.md)
- [x] ~~Who used the Course, Modulhandbuch and Output tabs?~~ → The Dean of Studies; same job as StudDekanin (tab Info texts). Git and Abfragen are dropped.
- [x] ~~Who is the handbook editor?~~ → No separate role; the Dean of Studies.
- [x] ~~Who publishes a handbook?~~ → The Dean of Studies.
- [x] ~~Viewer role?~~ → Dropped (see read‑only question above).
- [x] ~~Who releases?~~ → The Dean of Studies (StudDekanin Info: "modules are released"; Output Html: "must be released by the Dean of Studies").

## 2. Status & release

- [ ] Where is the status (`created` / `checked` / `published`, Freigabe) set in the old system? No button or field is visible in the PDFs, not even in the Modul edit form.
- [x] ~~**Who releases?**~~ → The Dean of Studies (Output_Html: "vom Studiendekan freigegeben"); also sets `created` / `checked`. → [Old system: all screens](20-old-handbook-system-all-screens.md), [Old Handbook System](00b-old-handbook-overview.md)
- [ ] What does `checked` change in export and views (e.g., a "checked + published" draft export)? → [Review & Publish](14-review-and-publish.md), [Module Editions](03-module-editions.md#status-lifecycle)

## 3. Base data & lookups

- [ ] Lookup values move from the UI into code (`subject_area` enum). Has a Fachgebiet / Course Cycle / Course Source value ever been added or renamed? Is it OK that this now needs a developer? → [Base Data](02-base-data.md#not-migrated)
- [ ] Code `Kurz` vs `Name`: equal except `MB01` / `MB1`, `ME09` / `ME9`, `MG01` / `MG1`, … Which one is the real code to keep (printed, used in URLs)? The module title only exists in the free‑text Info field, so `CurriculumModule.title` must be filled from Info (or from the newest `ModuleEdition` name). → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] Codes without Fachgebiet (ITA, SCAP, SCMa, SCS), ~70 empty placeholder codes (MG*, MH*, …) and `TEST`: migrate, or clean up first? These become the flagged rows of the import report screen. → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] LSF‑Sortierung and LSF fields: still needed? (LSF replaced by heiCO since SoSe 2024.) Do not implement until answered. In the old data 12 of 21 LSF categories are unused, which supports dropping it. → [Domain Model](01-domain-model.md#old-system--new), [Module Editions](03-module-editions.md)

- [ ] Subject areas have DE/EN labels and a fixed order (`01 Mathematik / 01 Mathematics`, `02 Informatik / 02 Computer Science`, `03 Allgemeine Module / 03 General Modules`). Keep both labels and this order in the enum? → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] Study program expire date `2099-01-01` = "no end": import as empty `expires_on` and show "active"? The PO date only lives in the Info text; keep it there (`info`) or add a field? → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 4. Module editions

- [ ] Is **one language per module description** enough (old: DE + EN box per field, usually only one filled)? → [Module Editions](03-module-editions.md)

## 5. Handbooks & LaTeX

- [ ] `heading_level` on `Section` (chapter / section) vs. chapter headings written inside an intro (old way)? → [Handbooks](04-handbooks.md), [Domain Model](01-domain-model.md#old-system--new)
- [ ] LatexLayoutListe: the same data as LatexElementeListe, or a different element type that is empty in the PDFs? → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] How exactly is the whole handbook PDF assembled (Header + Intro + Gruppierungen + Footer)? → [Old system: all screens](20-old-handbook-system-all-screens.md)

- [ ] Section order: old Gruppierungen are ordered by a number prefix in their short name (01, 02, 03, 06, 07, gaps), module positions are sort keys with gaps (1, 2, 5, 6, 8, 12, …). Assumption: drag‑to‑reorder replaces both, and the import keeps only the **order**, not the numbers. Do the numbers mean anything else (e.g., printed chapter numbers)? → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 6. Cloning

- [ ] Must "Prepare a term" be **idempotent** (safe to run twice)? → [New Handbook](00a-new-handbook-overview.md#design-tenets)

- [ ] Code swap between terms: WS 2026/27 lists **MLat** where SoSe 2026 listed **ILat** (done by hand). Should "Prepare a term" handle this (e.g., a `replaced_by` link on `CurriculumModule`), or does it stay a manual remove + add? → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 7. Export & public pages

- [x] ~~Output format?~~ → **PDF** (old system has Draft PDF / PDF / single module PDF buttons). → [Export](17-export.md)
- [ ] Does anyone **edit the generated LaTeX by hand** before printing (old Output → Latex)? If no: no source download (E5), and the engine can be Typst. → [Export](17-export.md#rendering-engine)
- [ ] Do module texts contain **LaTeX markup** (formulas, tables, `\newpage`, …)? How much? Decides the Markdown conversion and the engine. → [Export](17-export.md#rendering-engine)
- [ ] **Studienverlaufspläne** in the old Intro: plain LaTeX tables or graphics? Can they become Markdown tables or an uploaded image/PDF? → [Handbooks](04-handbooks.md)
- [ ] **Old links:** which external websites use Output_Html (html / JSON), and which scripts / parameters do they call? They must keep working or be switched to the new public pages. Links use database ids (`id_modulhandbuch=13`), so we need an old‑id → new‑page mapping or redirects. → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 8. Dropped features

- [ ] **Abfragen** (raw SQL with Excel export) belongs to the generic "Portfolio" framework (`portfolio.iwr…`), not to the handbook. **Planned: drop it** (replaced by filters + CSV export). Confirm nobody uses stored queries (the list is empty in the PDFs). → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] **Git Export**: OK to replace by export snapshots ([Future Extensions](09-future-extensions.md))?

## 9. History

- [ ] Full history (old → new per change) or only "created / updated by"? Decides whether History flows Hi3 / Hi4 are possible. Is the old `History` field (old / new per field) actually used? → [History](18-history.md), [Domain Model](01-domain-model.md#cloning-export-access)
