# Flows & Screens: Export

PDFs of handbooks and single modules. Public web pages: see [Public Pages](19-public-pages.md).

```admonish info "Confirmed: the output is PDF"
The old system has PDF buttons (Draft PDF, PDF, single module PDF). The deliverable is the **PDF**. LaTeX or Typst is only the way the PDF is made; see [Rendering engine](#rendering-engine).
```

Who may run which export: see [Roles & Permissions](00c-roles-and-permissions.md).

---

## Flows

**E1. Draft PDF of a handbook**
1. Handbook editor (or Handbooks list ⋯) → **Draft PDF**.
2. "Preparing PDF…" → download when ready.
- All `ModuleEdition`s, each with a status mark; watermark "Entwurf / Draft"; empty sections shown.

**E2. Official PDF**
1. Handbook editor → **Draft PDF ▾ → Official PDF** (any handbook status as a preview for users who may edit the handbook; otherwise only for `published` handbooks).
- Only `published` `ModuleEdition`s; empty sections omitted; no watermark.

**E3. Single module PDF**
- Descriptions list row ⋯ / edit page / editor row → **PDF**. The module page as printed.
- Labels in the `ModuleEdition`'s language (no handbook context).

**E4. Check all modules render**
1. Handbook editor → **Check render**.
2. Each module is rendered alone; result (S2): "39 ok, 1 failed: IPK (unclosed table in Literature)" → **Open** jumps to the description.
- Run before E1 / E2, especially after migration or big edits.

**E5. Download source (only if needed ⚑)**
- Handbook editor → **Draft PDF ▾ → Source**, draft or official filter. For manual fixes outside the system.
- Only built if staff confirm they edit the generated LaTeX by hand (old Output → Latex). Otherwise dropped. See [To Verify](pending-thing-need-to-verify.md#7-export--public-pages).

**E6. Export failed**
- PDF fails → message with the failing module(s) (same as E4) instead of a broken file.

---

## Screens

### S1. Export menu (Handbook editor toolbar)

```
[Draft PDF ▾]
  Draft PDF          all descriptions, watermark
  Official PDF       published descriptions only
  ────────────       only if E5 is kept ⚑
  Source (draft)
  Source (official)
```

### S2. Check render result

```
Check render · Informatik BSc 100% · WS 2026/27
✓ 38 ok
✕ 1 failed
   IPK  Programmierkurs   Literature: table not closed      [Open]
                                                     [Run again] [Close]
```

### S3. Preparing

```
Preparing Draft PDF … (Informatik BSc 100%, 39 modules)
[Cancel]
→ Ready: MHB_Informatik_BSc_100_WS2026-27_draft.pdf  [Download]
```

- File names: `MHB_<short_name>_<term>[_draft].pdf`.

---

## Small Decisions

1. Official PDF of a draft handbook is a preview for users who may edit the handbook; read‑only users only get it for published handbooks.
2. Single module PDF uses the module's own language for labels.
3. A failed export never returns a half PDF; it lists the failing modules.

---

## Rendering engine

Users see PDFs only. The engine is an internal choice, because the stored texts are Markdown (see [Handbooks](04-handbooks.md), [Module Editions](03-module-editions.md)), not raw LaTeX.

| | LaTeX (old way) | Typst |
|---|---|---|
| Install | large TeX distribution (GBs) on the server | one small binary |
| Speed | seconds per handbook, several runs for TOC | well under a second; fine for "Check render" and previews |
| Errors | hard to map to a module field | clear messages with position, easy to show in "Check render" |
| Markdown input | via a converter (e.g. Pandoc) | via a converter or a Typst Markdown package |
| Math in texts | native | own syntax; LaTeX math needs conversion |
| Old content reuse | old Header / Intro / Gruppierung LaTeX could be copied | old LaTeX must be rewritten (once, during migration) |
| Hand editing by staff | familiar to most | new for most |

**Recommendation: Typst**, unless one of these is true (see [To Verify](pending-thing-need-to-verify.md#7-export--public-pages)):
- staff need a `.tex` file to edit by hand (E5), or
- module texts contain a lot of LaTeX (formulas, tables) that must keep working without conversion.

Either way the engine stays behind one template per output (handbook, single module), so it can be swapped later. Extra formats (Word, HTML for print) are not in scope.

