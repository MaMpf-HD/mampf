# Flows & Screens: History

Who changed what and when.

## Why History

The old system already has history (see [Old system: all screens](20-old-handbook-system-all-screens.md)):

- **Edit forms** show `tst_create` / `tst_change` (or `Erstellt` / `Geändert`): who created and who last changed the record.
- **Most edit forms** also have a read‑only `History` field with old / new value per field change (Code, Modulhandbuch, Gruppierung, Latex Elemente, Semester).
- **Exception: the Modul form** (the module description itself) has no `History` field, only `Erstellt` / `Geändert`. So for module texts the old system only knows who changed them last, not what changed.
- **Git → Export** writes all LaTeX records to files that are committed to Git: a second version history / backup.

The new system needs it as well:

1. **Keep what exists:** "who changed it last" on every record, and old / new values on master data and handbook structure. For module texts, full history would be new (the old Modul form has none).
2. **Course Source is derived from it:** "03 erstellt / 04 geändert durch Dozent" = who edited last (see [Domain Model](01-domain-model.md#old-system--new)).
3. **Descriptions are shared:** one `ModuleEdition` is used by several handbooks, so one edit changes all of them. History shows who changed it, when, and to what.

```admonish note "Scope still open"
- **Full history** (old → new per field): matches the old `History` field. MaMpf has no versioning gem yet → new dependency (e.g., `paper_trail`) and one `versions` table.
- **Only "last changed by / at"**: matches `tst_change`. Two columns, but no per‑field diff and no Hi3 / Hi4.

Suggestion: full history, since the old system already shows old / new per field. **TODO: ask the staff whether the old `History` field is actually used, and whether they miss it on module texts** (see [To Verify](pending-thing-need-to-verify.md#8-history)).
```

```admonish warning "⚑ Open"
These flows assume full history (old → new per change). With only "created/updated by", Hi1 shows one line and Hi3 / Hi4 are not possible.
```

---

## Flows

**Hi1. See the history of a record**
1. Any edit / detail page → **History ▸**.
2. Timeline, newest first: who, when, what (fields changed, status, structure).
3. Click an entry → old → new per field; long text as word diff.

**Hi2. See who changed it last**
- Lists show **Last changed** (date, name); "copied" if unchanged since cloning, "imported" after migration.

**Hi3. Who changed the status?**
1. Description → History.
2. Entry: "15.10. P.-Schmid · status published → created".

**Hi4. What happened to a handbook?**
1. Handbook editor → ⋯ → **History**.
2. Structure events: "IAD removed from Wahlmodule Informatik", "Section 'Anwendungsgebiet' added", "published".

**Hi5. Filter**
- History panel filter: all · content · status · structure.

---

## Screens

### S1. History panel

```
History                                     [all ▾]
● 15.10.2026 14:02  P.-Schmid
   Literature changed                                   ▸ show diff
   Status published → created
● 02.10.2026 09:11  P.-Schmid
   Status checked → published
● 01.10.2026 16:40  P.-Schmid
   Status created → checked
● 20.09.2026 10:05  system
   Copied from SoSe 2026 (Prepare a term)
```

### S2. Entry detail

```
15.10.2026 14:02 · P.-Schmid
Literature
- Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2008.
+ Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2011.
Status   published → created
```

### S3. Handbook history

```
History · Informatik BSc 100% · WS 2026/27      [structure ▾]
● 16.10.  P.-Schmid  published
● 15.10.  P.-Schmid  IITS3 added to Wahlmodule Informatik
● 15.10.  P.-Schmid  ILat removed from Wahlbereich Übergreifende Kompetenzen
● 20.09.  system     cloned from SoSe 2026
```

---

## Small Decisions

1. Cloning and migration write one entry per record ("copied from …", "imported"), not per field.
2. A drag that moves many rows is one entry ("reordered Wahlmodule Informatik").
3. Read‑only users do not see history (see [Roles & Permissions](00c-roles-and-permissions.md)).
