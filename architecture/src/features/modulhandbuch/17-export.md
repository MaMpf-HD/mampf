# Flows & Screens: Export

PDFs and LaTeX of handbooks and single modules. Public web pages: see [Public Pages](19-public-pages.md).

| Action | admin | viewer |
|--------|-------|--------|
| Draft PDF, Official PDF, single module PDF | ✓ | ✓ |
| Check render, Download LaTeX | ✓ | |

---

## Flows

**E1. Draft PDF of a handbook**
1. Handbook editor (or Handbooks list ⋯) → **Draft PDF**.
2. "Preparing PDF…" → download when ready.
- All `ModuleEdition`s, each with a status mark; watermark "Entwurf / Draft"; empty sections shown.

**E2. Official PDF**
1. Handbook editor → **Draft PDF ▾ → Official PDF** (admin, any handbook status: preview); viewer only for `published` handbooks.
- Only `published` `ModuleEdition`s; empty sections omitted; no watermark.

**E3. Single module PDF**
- Descriptions list row ⋯ / edit page / editor row → **PDF**. The module page as printed.
- Labels in the `ModuleEdition`'s language (no handbook context).

**E4. Check all modules render**
1. Handbook editor → **Check render**.
2. Each module is rendered alone; result (S2): "39 ok, 1 failed: IPK (unclosed table in Literature)" → **Open** jumps to the description.
- Run before E1 / E2, especially after migration or big edits.

**E5. Download LaTeX**
- Handbook editor → **Draft PDF ▾ → LaTeX (.tex)**, draft or official filter. For manual fixes outside the system.

**E6. Export failed**
- PDF fails → message with the failing module(s) (same as E4) instead of a broken file.

---

## Screens

### S1. Export menu (Handbook editor toolbar)

```
[Draft PDF ▾]
  Draft PDF          all descriptions, watermark
  Official PDF       published descriptions only
  ────────────
  LaTeX (draft)      .tex
  LaTeX (official)   .tex
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

1. Official PDF of a draft handbook is allowed for admin as a preview; viewers only get it for published handbooks.
2. Single module PDF uses the module's own language for labels.
3. A failed export never returns a half PDF; it lists the failing modules.
