# Future Extensions

Extensions that the core design accommodates without restructuring. Each lists what it adds and what it touches.


## Export Snapshots

**What:** keep the exact official PDF per handbook, so later edits to editions or catalog names do not change documents already published.

**Design:**

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `handbook_id` | DB column | The exported handbook |
| `format` | DB column | `pdf`, `latex`, … |
| `file` | Attachment | The generated document |
| `created_by_id` | DB column | Admin who exported |
| `created_at` | DB column | Export time |

**Touches:** new `Handbook::ExportSnapshot` model; `ExportsController` stores a snapshot on official exports; handbook page lists past exports.

```admonish note
Only needed if old PDFs must stay exact. Open question for the admin.
```

## Lecturer Role

**What:** lecturers edit the content of their own editions; the admin keeps control of status and structure.

**Touches:** `responsible` → `responsible_user_id` (references `users`); `HandbookAbility` gains a lecturer branch; edits by lecturers always reset status (already guaranteed by I7).

## Link Editions to MaMpf Lectures

**What:** connect `Handbook::ModuleEdition` to the MaMpf `Lecture` that teaches it in that term.

**Touches:** optional `lecture_id` on editions. Enables prefilling `responsible` from the lecture's teacher and linking from the lecture page to its handbook entry. The handbook stays the verified source; the link is informational.

## Export to Another Page

**What:** publish the handbook on an external Angular page.

**Touches:** a read‑only JSON endpoint (`GET /handbooks/:id.json`, published only). See [Export](06-export.md#export-to-another-page) for why plain `[innerHTML]` is limited.

## Per‑Program Credits

**What:** the same edition with different ECTS in different programs (e.g., 8 for Mathematics, 5 for Physics).

**Design:** 
Idk

## Multi‑Program Handbooks

#TODO: this actually should be enforced now

**What:** one handbook covering several programs (e.g., 100% and 50%).

**Touches:** `study_program_id` → join table `handbook_handbook_study_programs`; uniqueness moves to a validation. Everything below the handbook is unchanged.
