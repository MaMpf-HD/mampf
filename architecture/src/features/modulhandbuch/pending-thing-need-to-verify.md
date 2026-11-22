# To Verify

Open points to recheck with the staff or in the old system. Each item links to where it comes from; when an item is answered, update that doc and tick it here.

## 1. Roles

All role assumptions live in [Roles & Permissions](00c-roles-and-permissions.md) (marked ⚑ there). To check:

- [ ] Who used the **Course**, **Output**, **Git** and **Abfragen** tabs? Can one user have several tabs?
- [ ] Who is the **handbook editor** (Modulhandbuch tab) in practice? The same person as the Studiendekan?
- [ ] **Dozent:** edits only own modules **and** only while not released? (The SoSe 2026 Dozent list IAML, IFML, MD1, MLC*, MLS*, MM*, SC* … fits "not released yet".) → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] **Dozent:** may a lecturer still create a new module (old `Neu`), or only edit?
- [ ] **Dozent:** may a lecturer delete (old list shows `delete` on some rows)?
- [ ] **Viewer** (new, no old tab): needed at all? Drafts or published only?
- [ ] Who **publishes a handbook** (new action)? Assumed: handbook editor.
- [ ] Who creates `Term`s in MaMpf? The target term must exist before "Prepare a term". → [Base Data](02-base-data.md#term-mampf-reused)
- [ ] Course Source "03 / 04 durch Dozent": set automatically when a Dozent saves? → [Old Handbook System](00b-old-handbook-overview.md)
- [x] ~~Who releases?~~ → The Studiendekan (StudDekanin Info: "Module freigegeben"; Output Html: "vom Studiendekan freigegeben").

## 2. Status & release

- [ ] Where is the status (`created` / `checked` / `published`, Freigabe) set in the old system? No button or field is visible in the PDFs, not even in the Modul edit form.
- [x] ~~**Who releases?**~~ → The Studiendekan (Output_Html: "vom Studiendekan freigegeben"). Editors set `created` / `checked` only. → [Old system: all screens](20-old-handbook-system-all-screens.md), [Old Handbook System](00b-old-handbook-overview.md)
- [ ] What does `checked` change in export and views (e.g., a "checked + published" draft export)? → [Review & Publish](14-review-and-publish.md), [Module Editions](03-module-editions.md#status-lifecycle)

## 3. Base data & lookups

- [ ] Lookup values move from the UI into code (`subject_area` enum). Has a Fachgebiet / Course Cycle / Course Source value ever been added or renamed? Is it OK that this now needs a developer? → [Base Data](02-base-data.md#not-migrated)
- [ ] Code `Kurz` vs `Name`: mostly equal, but sometimes `MB01` / `MB1`. Which one is the real code to keep (printed, used in URLs)?
- [ ] Codes without Fachgebiet (ITA, SCAP, SCMa, SCS), placeholder codes without Info (MG*, MH*, …) and `TEST`: migrate, or clean up first?
- [ ] LSF‑Sortierung and LSF fields: still needed? (LSF replaced by heiCO since SoSe 2024.) Do not implement until answered. → [Domain Model](01-domain-model.md#old-system--new), [Module Editions](03-module-editions.md)

## 4. Module editions

- [ ] Is **one language per module description** enough (old: DE + EN box per field, usually only one filled)? → [Module Editions](03-module-editions.md)

## 5. Handbooks & LaTeX

- [ ] `heading_level` on `Section` (chapter / section) vs. chapter headings written inside an intro (old way)? → [Handbooks](04-handbooks.md), [Domain Model](01-domain-model.md#old-system--new)
- [ ] LatexLayoutListe: the same data as LatexElementeListe, or a different element type that is empty in the PDFs? → [Old system: all screens](20-old-handbook-system-all-screens.md)
- [ ] How exactly is the whole handbook PDF assembled (Header + Intro + Gruppierungen + Footer)? → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 6. Cloning

- [ ] Must "Prepare a term" be **idempotent** (safe to run twice)? → [New Handbook](00a-new-handbook-overview.md#design-tenets)

## 7. Export & public pages

- [ ] Which external websites use Output_Html (html / JSON), and which scripts / parameters do they call? They must keep working or be switched to the new public pages. Links use database ids (`id_modulhandbuch=13`), so we need an old‑id → new‑page mapping or redirects. → [Old system: all screens](20-old-handbook-system-all-screens.md)

## 8. History

- [ ] Full history (old → new per change) or only "created / updated by"? Decides whether History flows Hi3 / Hi4 are possible. Is the old `History` field (old / new per field) actually used? → [History](18-history.md), [Domain Model](01-domain-model.md#cloning-export-access)
