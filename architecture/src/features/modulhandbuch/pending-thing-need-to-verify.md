# To Verify

Open points to recheck with the staff or in the old system. Each item links to where it comes from; when an item is answered, update that doc and tick it here.

## 1. Roles & tab access (old system)

The old system grants access **per tab**. Who can open which tab is only assumed from the tab names; nothing in the PDFs shows it.

| Tab | admin (Course) | handbook editor | StudDekan | Dozent | public |
|---|---|---|---|---|---|
| Course | ✓ assumed | ? | ? | ? | ✗ |
| Modulhandbuch | ? | ✓ assumed | ? | ? | ✗ |
| StudDekanin | ? | ? | ✓ assumed | ? | ✗ |
| Dozent | ? | ? | ? | ✓ assumed | ✗ |
| Output (Latex) | ? | ? | ? | ? | ✗ |
| Output_Html (html / JSON) | ? | ? | ? | ? | ✓ (public scripts) |
| Git → Export | ? | ? | ? | ? | ✗ |
| Abfragen (raw SQL) | ? | ? | ? | ? | ✗ |

- [ ] Fill the table: which role can open which tab? Can one user have several tabs (e.g., the admin sees all)? → [Roles & Permissions](00c-roles-and-permissions.md)
- [ ] Are admin, handbook editor and StudDekan in practice **one person**? (The new design merges them into `admin`.) → [Roles & Permissions](00c-roles-and-permissions.md#how-the-old-roles-map)
- [ ] Who can use **Output / Git / Abfragen**? → [Roles & Permissions](00c-roles-and-permissions.md)
- [ ] Dozent `edit` only shows on some rows: own modules, unreleased ones, or something else? → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] Old Dozent could **create new Module**. Must a lecturer still be able to create / propose a module, or is "edit only" OK? → [Roles & Permissions](00c-roles-and-permissions.md#how-the-old-roles-map)
- [ ] Course Source "03 / 04 durch Dozent": set automatically when a Dozent saves? → [Old Handbook System](00b-old-handbook-overview.md)
- [ ] Which of the duplicated screens (Course / StudDekanin / Modulhandbuch tabs) can do what: elaborate per tab. → [Old Handbook System](00b-old-handbook-overview.md#roles)

## 2. Roles (new system)

- [ ] Is a separate **approver** needed, or does admin release? (mail question 2) → [Roles & Permissions](00c-roles-and-permissions.md)
- [ ] Should **viewers** (Prüfungsamt, Studienberatung) see drafts, or only official? → [Roles & Permissions](00c-roles-and-permissions.md)
- [ ] Who can create `Term`s in MaMpf? The target term must exist before "Prepare a term". → [Base Data](02-base-data.md#term-mampf-reused)

## 3. Status & release

- [ ] Where is the status (`created` / `checked` / `published`, Freigabe) set in the old system? No button or field is visible in the PDFs. → [Old system: all screens](20-old-handbook-system-all-screens.md), [Old Handbook System](00b-old-handbook-overview.md)
- [ ] What does `checked` change in export and views (e.g., a "checked + published" draft export)? → [Review & Publish](14-review-and-publish.md), [Module Editions](03-module-editions.md#status-lifecycle)

## 4. Base data & lookups

- [ ] Lookup values move from the UI into code (`subject_area` enum). Has a Fachgebiet / Course Cycle / Course Source value ever been added or renamed? Is it OK that this now needs a developer? → [Base Data](02-base-data.md#not-migrated)
- [ ] LSF‑Sortierung and LSF fields: still needed? (LSF replaced by heiCO since SoSe 2024.) Do not implement until answered. → [Domain Model](01-domain-model.md#old-system--new), [Module Editions](03-module-editions.md)

## 5. Module editions

- [ ] Is **one language per module description** enough (old: DE + EN box per field, usually only one filled)? → [Module Editions](03-module-editions.md)

## 6. Handbooks & LaTeX

- [ ] `heading_level` on `Section` (chapter / section) vs. chapter headings written inside an intro (old way)? → [Handbooks](04-handbooks.md), [Domain Model](01-domain-model.md#old-system--new)
- [ ] LatexLayoutListe: the same data as LatexElementeListe, or a different element type that is empty in the PDFs? → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] How exactly is the whole handbook PDF assembled (Header + Intro + Gruppierungen + Footer)? → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 7. Cloning

- [ ] Must "Prepare a term" be **idempotent** (safe to run twice)? → [New Handbook](00a-new-handbook-overview.md#design-tenets)

## 8. Export & public pages

- [ ] Which external websites use Output_Html (html / JSON), and which scripts / parameters do they call? They must keep working or be switched to the new public pages. → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 9. History

- [ ] Full history (old → new per change) or only "created / updated by"? Decides whether History flows Hi3 / Hi4 are possible. Is the old `History` field (old / new per field) actually used? → [History](18-history.md), [Domain Model](01-domain-model.md#cloning-export-access)
