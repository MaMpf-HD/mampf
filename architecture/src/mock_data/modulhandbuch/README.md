# Mock data: Modulhandbuch base data

For mockups only. Codes and titles come from the old system; people are fictitious.

| File | Model | Count |
|---|---|---|
| `enums.json` | `subject_area`, `language`, `edition_status`; `edition_source` (derived, not stored) | – |
| `terms.json` | `Term` (reused) | 4: SoSe 2025 … WS 2026/27 |
| `users.json` | `User` | 6: 2 with role `dean_of_studies`, 4 lecturers (no role) |
| `study_programs.json` | `Handbook::StudyProgram` | 4, one expired |
| `curriculum_modules.json` | `Handbook::CurriculumModule` | 20 |
| `module_editions.json` | `Handbook::ModuleEdition` | 20 |

Old lookups without a file: Course Cycle (dropped, `cycle` is free text), Course Source (→ `edition_source`, derived).

## Scenarios covered

| Case | Records |
|---|---|
| Clone chain over 4 terms, last one just cloned (`created`, not edited) | IAD editions 1 → 2 → 3 → 4 |
| Winter‑only module, clone `checked` | IACO 5 → 6 |
| Module leaves the handbook (`active: false`) | IAML, MD1, IFML |
| New module in SoSe 2026 | IARCA, IRL |
| Language change between terms (de → en) | MA4 10 → 11 |
| Rename via new code, text copied | ILat 15 → MLat 16 |
| No lecturer assigned yet | IITS3 17, SCMT 20 |
| Module never used ("not used yet") | IPK, IFML, MA1, MB1, ME9, SCFA, MG10 |
| Placeholder code without title / notes | MG10 |
| Each status | `created`, `checked`, `published` |
| Each subject area | math, cs, general |
