/** How many results the palette remembers. */
const MAX_RECENT = 6;

/**
 * The ids of the results visited last (see PaletteResult#id), newest first.
 * localStorage may be unavailable (private windows, blocked site data); the
 * palette then has no recent results.
 */
export function loadRecentIds(userId: number): string[] {
  try {
    const stored = localStorage.getItem(storageKey(userId));
    const parsed: unknown = stored ? JSON.parse(stored) : [];
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed.filter((id): id is string => typeof id === "string");
  }
  catch {
    return [];
  }
}

export function rememberRecentId(userId: number, id: string): void {
  const others = loadRecentIds(userId).filter(recent => recent !== id);
  const updated = [id, ...others].slice(0, MAX_RECENT);
  try {
    localStorage.setItem(storageKey(userId), JSON.stringify(updated));
  }
  catch {
    // Nothing to do: see loadRecentIds.
  }
}

function storageKey(userId: number): string {
  return `mampf:command-palette:recent:${userId}`;
}
