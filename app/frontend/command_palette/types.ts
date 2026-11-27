/**
 * LectureEntry to UserPayload mirror the JSON of CommandPaletteCatalog and
 * CommandPaletteUserData; the other types are built here.
 */

/** A lecture as the catalog sends it; the user's own ones carry more. */
export interface LectureEntry {
  id: number;
  path: string;
  title: string;
  short: string;
  term: string | null;
  /**
   * Terms between the lecture's term and Term.active in Term.chronological;
   * null without either.
   */
  term_distance: number | null;
  favorite?: boolean;
  /** How the user takes part in it, for the user's own lectures only. */
  participation?: Participation;
  /** Maps a destination key to its path, for the user's own lectures only. */
  destinations?: Record<string, string>;
}

/**
 * How the user takes part in a lecture, as in the dashboard's sections.
 * "enrolled" means holding a place in it (or having applied for one),
 * "bookmarked" only having bookmarked or pinned it.
 */
export type Participation = "staff" | "tutor" | "enrolled" | "bookmarked";

/** A page inside a lecture, e.g. "Exercises". */
export interface DestinationInfo {
  key: string;
  icon: string;
  label: string;
  keywords: string[];
}

/** A page outside of lectures, e.g. "Profile", or an action like "Pin LA 2". */
export interface GlobalItem {
  key: string;
  icon: string;
  label: string;
  keywords: string[];
  path: string;
  method: string;
}

export interface UserPayload {
  globals: GlobalItem[];
  destinations: DestinationInfo[];
  lectures: LectureEntry[];
}

/**
 * A text an item is found by (a lecture's title, a page's label, a keyword),
 * prepared for matching by itemText in normalize.ts.
 */
export interface ItemText {
  /** Normalized words, e.g. ["lineare", "algebra", "2"]. */
  words: string[];
  /** The words joined without spaces, e.g. "linearealgebra2". */
  compact: string;
}

export interface IndexedLecture {
  lecture: LectureEntry;
  /** Whether the lecture is one of the user's own (not just in the catalog). */
  mine: boolean;
  texts: ItemText[];
}

export interface IndexedDestination {
  info: DestinationInfo;
  labelText: ItemText;
  keywordTexts: ItemText[];
}

export interface IndexedGlobal {
  item: GlobalItem;
  labelText: ItemText;
  keywordTexts: ItemText[];
}

export interface IndexedRecent {
  result: PaletteResult;
  texts: ItemText[];
}

/** Everything the palette searches through, rebuilt by buildIndex on every open. */
export interface PaletteIndex {
  lectures: IndexedLecture[];
  destinations: Map<string, IndexedDestination>;
  globals: IndexedGlobal[];
  actions: IndexedGlobal[];
  recent: IndexedRecent[];
}

export type ResultGroup = "favorites" | "recent" | "lectures" | "lecturePages"
  | "goTo" | "actions";

/** One option in the palette's listbox. */
export interface PaletteResult {
  /** Identifies the target, e.g. "lecture:5:exercises", to remove duplicates. */
  id: string;
  group: ResultGroup;
  icon: string;
  label: string;
  /** Secondary text, e.g. the lecture of a lecture page. */
  detail: string;
  path: string;
  method: string;
  score: number;
}
