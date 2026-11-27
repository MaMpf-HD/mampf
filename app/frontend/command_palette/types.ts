export interface LectureEntry {
  id: number;
  path: string;
  title: string;
  short: string;
  term: string | null;
  /** Distance of the lecture's term to the current term. */
  term_distance: number | null;
  favorite?: boolean;
  participation?: Participation;
  destinations?: Record<string, string>;
}

/** How the user takes part in a lecture, as in the dashboard's sections. */
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

/**
 * What an item is found by.
 *
 * For example, exercises can be found by the page's label "Exercises" and
 * its keywords "exercise sheets", "übungsblätter" etc.
 */
export interface Findable {
  texts: ItemText[];
  keywords?: ItemText[];
}

export interface IndexedLecture extends Findable {
  lecture: LectureEntry;
  /** Whether the lecture is one of the user's own (not just in the catalog). */
  mine: boolean;
}

export interface IndexedDestination extends Findable {
  info: DestinationInfo;
}

export interface IndexedGlobal extends Findable {
  item: GlobalItem;
}

export interface IndexedRecent extends Findable {
  result: PaletteResult;
}

/**
 * Everything the palette searches through, rebuilt by buildIndex,
 * whenever the palette is reopened.
 * */
export interface PaletteIndex {
  lectures: IndexedLecture[];
  destinations: Map<string, IndexedDestination>;
  globals: IndexedGlobal[];
  actions: IndexedGlobal[];
  recent: IndexedRecent[];
}

export type ResultGroup = "favorites" | "recent" | "lectures" | "lecturePages"
  | "goTo" | "actions";

/** One option in the palette. */
export interface PaletteResult {
  /** Identifies the target, e.g. "lecture:5:exercises", to remove duplicates. */
  id: string;
  group: ResultGroup;
  icon: string;
  label: string;
  /** Secondary text that is shown in smaller font for a palette entry. */
  detail: string;
  path: string;
  method: string;
  score: number;
}
