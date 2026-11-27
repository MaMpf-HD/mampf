import type { LectureEntry, UserPayload } from "../types";

export interface PaletteDataUrls {
  me: string;
  catalog: string;
}

export interface PaletteData {
  user: UserPayload;
  catalog: LectureEntry[];
}

/**
 * Module-level, so the data outlives the navbar, which Turbo replaces on every
 * visit. Keyed by URL: the me URL carries the user, locale and their last
 * change (CommandPaletteComponent#me_version).
 */
const requests = new Map<string, Promise<unknown>>();

/** Loads the palette's data once per URL and hands out the same promise afterwards. */
export function loadPaletteData(urls: PaletteDataUrls): Promise<PaletteData> {
  for (const url of requests.keys()) {
    if (url !== urls.me && url !== urls.catalog) {
      requests.delete(url);
    }
  }

  return Promise.all([
    cachedFetch<UserPayload>(urls.me),
    cachedFetch<LectureEntry[]>(urls.catalog),
  ]).then(([user, catalog]) => ({ user, catalog }));
}

/** Makes the next load fetch this URL again, e.g. the user's data after pinning. */
export function forgetData(url: string): void {
  requests.delete(url);
}

function cachedFetch<T>(url: string): Promise<T> {
  let request = requests.get(url) as Promise<T> | undefined;
  if (!request) {
    request = fetchJson<T>(url).catch((error: unknown) => {
      requests.delete(url);
      throw error;
    });
    requests.set(url, request);
  }
  return request;
}

async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    credentials: "same-origin",
  });
  if (!response.ok) {
    throw new Error(`Command palette: ${url} answered ${response.status}`);
  }
  return await response.json() as T;
}
