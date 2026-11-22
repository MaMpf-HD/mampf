# Flows & Screens: Handbook Building

Create a `Handbook`, edit its front matter, sections and module list.

---

## Flows

### Handbook

**H1. Create a handbook (empty)**
1. Handbooks list → **New handbook**.
2. Pick program (active only) and term. A handbook for that pair exists → shown before submit, with a link.
3. **Start empty** → `Handbook` in `draft`, language from the program, title "Modulhandbuch <program>"; the editor opens.

**H2. Create a handbook by cloning**
- New handbook → **Clone from** <earlier term>, or Prepare a term. See [Cloning](16-cloning.md).

**H3. Delete a handbook**
- Handbooks list → ⋯ → **Delete**. Only `draft`. Asks: "Deletes 5 sections and 39 entries. Module descriptions stay."
- `published` → disabled: "Unpublish first."

### Front Matter

**H4. Edit front matter**
1. Editor → **Front matter**.
2. Edit `title`, `subtitle`, `issue_date`, `intro` (Präambel, Studienverlaufspläne), `outro`.
3. **Preview** shows the text as printed. Save.
- Cloned handbook: everything is prefilled from the source; `issue_date` is empty and marked "set before publishing".

### Sections

**H5. Add a section**
1. Editor → **+ Section** (at the end, or "insert below" on a section).
2. Enter `title`, `heading_level` (chapter / section), optional `intro`, `outro`.
- A chapter usually has no modules: it is a heading for the sections below it ("Wahlbereich").

**H6. Edit / reorder a section**
- Click the section title → edit inline (title, heading level, intro, outro).
- Drag the section handle to reorder.

**H7. Delete a section**
- Empty → deleted directly.
- With entries → "Removes 14 entries from this handbook. The descriptions stay." → confirm.

### Entries

**H8. Add a module**
1. In a section → **+ Add module** → search code or title (active `CurriculumModule`s).
2. Each result shows its state in the handbook's term:

| State in the handbook's term | Shown | Action |
|------------------------------|-------|--------|
| `ModuleEdition` exists | "exists · used in BSc 50%" | **Add** → entry links it |
| Missing, earlier term has one | "last: SoSe 2026" | **Copy from SoSe 2026** / **Empty** → created (status `created`), then the entry |
| Missing, never had one | "new" | **Add empty** |
| Already in this handbook | "in Wahlmodule Informatik" | disabled |
| No such module | — | **Create module "XYZ"** (see [Base Data](11-base-data.md) F1b) |

3. The entry appears at the end of the section, highlighted.

**H9. Reorder / move a module**
- Drag within a section, or to another section.
- Or row menu ⋯ → **Move to…** (section list), for long handbooks.

**H10. Remove a module**
- Row ⋯ → **Remove** → "Removes IAD from BSc 100% only. BSc 50% keeps it." (or: "IAD WS 2026/27 is then in no handbook; it stays in the descriptions list.")

**H11. Open a description**
- Click the row → side panel with the description (see [Description Editing](13-description-editing.md)).

### Check

**H12. Check before export**
- Toolbar → **Check all modules render** → result list (see [Export](17-export.md)).
- Toolbar → **Draft PDF**.

---

## Screens

### S1. Handbooks list

```
Handbooks                                   [Prepare a term…]  [+ New handbook]

Program [All ▾]  Term [WS 2026/27 ▾]  Status [All ▾]   [✓] Hide expired programs

Program                     Term        Status     Modules  created/checked/published
Informatik BSc 100%         WS 2026/27  draft      39       12 / 3 / 24        ⋯
Informatik BSc 50%          WS 2026/27  draft      21        4 / 0 / 17        ⋯
Mathematik BSc 100%         WS 2026/27  published  52        0 / 0 / 52        ⋯
…
```

- Row click → S2. ⋯ menu: Open, Clone to another term, Draft PDF, Official PDF, Delete.
- Default term: newest term with handbooks.

### S2. Handbook editor

```
Informatik BSc 100% · WS 2026/27 · draft · de          [Front matter] [Check render]
39 modules: 12 created · 3 checked · 24 published      [Draft PDF ▾]  [Publish]

▾ 1  Pflichtbereich                         (chapter)                    ✎ ⋯
▾ 1.1 Pflichtmodule Informatik              (section)                    ✎ ⋯
     "Nachfolgend sind die Pflichtmodule …"
     ⠿ IPI   Einführung in die Praktische Informatik  de  ● published  🔗3   PDF ⋯
     ⠿ IPK   Programmierkurs                          de  ○ created    🔗2   PDF ⋯
     ⠿ IAD   Algorithmen und Datenstrukturen          de  ◐ checked    🔗3   PDF ⋯
     [+ Add module]
▾ 1.2 Pflichtmodule Mathematik              (section)                    ✎ ⋯
     …
[+ Section]
```

- ⠿ = drag handle. Status: ○ created, ◐ checked, ● published. 🔗N = used in N handbooks.
- ✎ = edit section inline (S4). Row click → description side panel.
- Collapse / expand all sections for long handbooks.

### S3. Add module dialog

```
Add module to "Wahlmodule Informatik"
Search [itS_____________]

IITS1  IT-Sicherheit 1   exists · used in BSc 50%                [Add]
IITS2  IT-Sicherheit 2   last: SoSe 2026               [Copy from SoSe 2026] [Empty]
IITS3  IT-Sicherheit 3   new                                     [Add empty]
IITS   IT-Sicherheit     inactive                                 (hidden unless "show inactive")
```

### S4. Section edit (inline)

```
Title          [Wahlmodule Informatik            ]
Heading level  ( ) chapter  (•) section
Intro          [Hier steht die Einleitung …                     ]
Outro          [                                                ]
                                                  [Cancel] [Save]
```

### S5. Front matter

```
Front matter · Informatik BSc 100% · WS 2026/27            [Edit] [Preview]

Title       [Modulhandbuch Bachelorstudiengang „Informatik"  ]
Subtitle    [Fassung … zur Prüfungsordnung vom 26.03.2015 …   ]
Issue date  [__________]   ⚠ set before publishing
Intro       [1 Qualifikationsziele …                              ]
            [## Studienverlaufsplan                               ]
            [| Semester | Module | LP |                           ]
Outro       [                                                     ]
                                                  [Cancel] [Save]
```

### Read-only view
For users without edit rights (who: see [Roles & Permissions](00c-roles-and-permissions.md)).

S1, S2, S5 read‑only: no drag handles, no buttons except PDF.

---

## Small Decisions

1. Sections are edited inline in the editor, not on a separate page (old: separate Gruppierung Edit).
2. Published handbooks stay editable with a banner "changes are visible immediately"; only delete is blocked.
3. "Move to…" menu in addition to drag, because handbooks have 40–50 entries.
