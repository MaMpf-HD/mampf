import { globalResult, lecturePageResult, lectureResult } from "../results";
import type {
  IndexedDestination, IndexedGlobal, IndexedLecture, PaletteIndex, PaletteResult,
  Participation, ResultGroup,
} from "../types";
import { tokenize } from "./normalize";
import { splitQuery } from "./query_split";
import { scoreAllTokens, scoreLabelAndKeywords, ScoreTier } from "./token_score";

/**
 * Boost factors for a lecture's score, e.g. when a user is registered for a lecture
 * they want to see those lectures first.
 */
const Boost = {
  /** Participation "staff", "tutor" or "enrolled". */
  PARTICIPATING: 1.2,
  /** Participation "bookmarked". */
  BOOKMARKED: 1.1,
  CATALOG: 1,
  /** Pinned lectures. */
  FAVORITE: 1.05,
  RECENT: 0.95,
  /** A lecture page found by the action only, e.g. "exercises", see bareDestinationResults. */
  IMPLIED_LECTURE: 0.85,
} as const;

/**
 * Each term of term_distance lowers a lecture's weight by this much, down
 * to MIN_TERM_FACTOR.
 */
const TERM_DISTANCE_PENALTY = 0.08;
const MIN_TERM_FACTOR = 0.6;

/**
 * How many of the best-matching lectures have their pages searched,
 * in the sense that lecture-specific pages like "exercises" are offered for them.
 * */
const MAX_LECTURES_WITH_PAGES = 5;

/**
 * A user might just type "exercises" without a lecture name. This number limits
 * how many of the user's lectures that have an "exercises" page are offered.
 */
const LECTURES_FOR_BARE_DESTINATION = 3;

const GROUP_LIMITS: Record<ResultGroup, number> = {
  favorites: 8,
  recent: 5,
  lectures: 6,
  lecturePages: 8,
  goTo: 6,
  actions: 3,
};

/**
 * Lectures, lecture pages ("la2 exercises", "übungen la 2", "skript"), globals,
 * actions and recent results for the query, grouped and best first; an empty
 * query gets suggestions().
 */
export function rank(query: string, index: PaletteIndex): PaletteResult[] {
  const tokens = tokenize(query);
  if (tokens.length === 0) {
    return suggestions(index);
  }

  return groupResults([
    ...lectureResults(tokens, index.lectures),
    ...lecturePageResults(tokens, index),
    ...bareDestinationResults(tokens, index),
    ...globalResults(tokens, index.globals, "goTo"),
    ...globalResults(tokens, index.actions, "actions"),
    ...recentResults(tokens, index),
  ]);
}

/** What the palette shows before anything is typed. */
function suggestions(index: PaletteIndex): PaletteResult[] {
  const favorites = index.lectures
    .filter(indexed => indexed.lecture.favorite === true)
    .map(indexed => lectureResult(indexed.lecture, "favorites", ScoreTier.EXACT))
    .slice(0, GROUP_LIMITS.favorites);
  const favoriteIds = new Set(favorites.map(result => result.id));
  const recent = index.recent
    .map(indexed => indexed.result)
    .filter(result => !favoriteIds.has(result.id))
    .slice(0, GROUP_LIMITS.recent);
  const actions = index.actions.map(indexed => globalResult(indexed, "actions", ScoreTier.EXACT));

  return [...favorites, ...recent, ...actions];
}

function lectureResults(tokens: string[], lectures: IndexedLecture[]): PaletteResult[] {
  const results: PaletteResult[] = [];
  for (const indexed of lectures) {
    const score = scoreAllTokens(tokens, indexed.texts);
    if (score > ScoreTier.NONE) {
      results.push(lectureResult(indexed.lecture, "lectures", score * lectureWeight(indexed)));
    }
  }
  return results;
}

/**
 * Pages in the user's lectures for queries that name both, in either order:
 * "la2 exercises" or "exercises la2". The score weighs both parts by their
 * number of words.
 */
function lecturePageResults(tokens: string[], index: PaletteIndex): PaletteResult[] {
  const myLectures = index.lectures.filter(indexed => indexed.mine);
  const results: PaletteResult[] = [];

  for (const split of splitQuery(tokens)) {
    const lectureMatches = bestLectures(split.lectureTokens, myLectures);
    for (const { indexed, score: lectureScore } of lectureMatches) {
      for (const [key, path] of Object.entries(indexed.lecture.destinations ?? {})) {
        const destination = index.destinations.get(key);
        if (!destination) {
          continue;
        }
        const destinationScore = scoreDestination(split.destinationTokens, destination);
        if (destinationScore === ScoreTier.NONE) {
          continue;
        }

        const score = weightedAverage(
          lectureScore, split.lectureTokens.length,
          destinationScore, split.destinationTokens.length,
        );
        results.push(lecturePageResult(indexed.lecture, destination, path, "lecturePages",
          score * lectureWeight(indexed)));
      }
    }
  }
  return results;
}

/**
 * Constructs results for a query that names a lecture page without its lecture,
 * e.g. only "exercises" or "skript".
 */
function bareDestinationResults(tokens: string[], index: PaletteIndex): PaletteResult[] {
  const myLectures = index.lectures
    .filter(indexed => indexed.mine)
    .sort((a, b) => lectureWeight(b) - lectureWeight(a));
  const results: PaletteResult[] = [];

  for (const destination of index.destinations.values()) {
    const destinationScore = scoreDestination(tokens, destination);
    if (destinationScore === ScoreTier.NONE) {
      continue;
    }

    const offering = myLectures.filter(
      indexed => indexed.lecture.destinations?.[destination.info.key] !== undefined,
    );
    for (const indexed of offering.slice(0, LECTURES_FOR_BARE_DESTINATION)) {
      const path = indexed.lecture.destinations?.[destination.info.key] ?? "";
      const score = destinationScore * Boost.IMPLIED_LECTURE * lectureWeight(indexed);
      results.push(lecturePageResult(indexed.lecture, destination, path, "lecturePages", score));
    }
  }
  return results;
}

function globalResults(
  tokens: string[], items: IndexedGlobal[], group: ResultGroup,
): PaletteResult[] {
  const results: PaletteResult[] = [];
  for (const indexed of items) {
    const score = scoreLabelAndKeywords(tokens, indexed.labelText, indexed.keywordTexts);
    if (score > ScoreTier.NONE) {
      results.push(globalResult(indexed, group, score));
    }
  }
  return results;
}

function recentResults(tokens: string[], index: PaletteIndex): PaletteResult[] {
  const results: PaletteResult[] = [];
  for (const indexed of index.recent) {
    const score = scoreAllTokens(tokens, indexed.texts);
    if (score > ScoreTier.NONE) {
      results.push({ ...indexed.result, score: score * Boost.RECENT });
    }
  }
  return results;
}

/**
 * The lectures matching the words best, at most MAX_LECTURES_WITH_PAGES of them.
 * Among equal matches (e.g. "la2" for LA 2 of several years), the weightiest
 * lectures win.
 */
function bestLectures(
  tokens: string[], lectures: IndexedLecture[],
): { indexed: IndexedLecture; score: number }[] {
  const matches: { indexed: IndexedLecture; score: number }[] = [];
  for (const indexed of lectures) {
    const score = scoreAllTokens(tokens, indexed.texts);
    if (score > ScoreTier.NONE) {
      matches.push({ indexed, score });
    }
  }
  matches.sort((a, b) =>
    b.score * lectureWeight(b.indexed) - a.score * lectureWeight(a.indexed));
  return matches.slice(0, MAX_LECTURES_WITH_PAGES);
}

function scoreDestination(tokens: string[], destination: IndexedDestination): number {
  return scoreLabelAndKeywords(tokens, destination.labelText, destination.keywordTexts);
}

/** See Boost and TERM_DISTANCE_PENALTY. */
function lectureWeight(indexed: IndexedLecture): number {
  return roleBoost(indexed) * termFactor(indexed.lecture.term_distance);
}

function roleBoost(indexed: IndexedLecture): number {
  const boost = indexed.mine ? participationBoost(indexed.lecture.participation) : Boost.CATALOG;
  return indexed.lecture.favorite === true ? boost * Boost.FAVORITE : boost;
}

function participationBoost(participation: Participation | undefined): number {
  return participation === "bookmarked" || participation === undefined
    ? Boost.BOOKMARKED
    : Boost.PARTICIPATING;
}

function termFactor(termDistance: number | null): number {
  if (termDistance === null) {
    return 1;
  }
  return Math.max(MIN_TERM_FACTOR, 1 - TERM_DISTANCE_PENALTY * termDistance);
}

function weightedAverage(
  first: number, firstWeight: number, second: number, secondWeight: number,
): number {
  return (first * firstWeight + second * secondWeight) / (firstWeight + secondWeight);
}

/**
 * Removes duplicates (keeping the best score), sorts each group by score,
 * cuts it to its limit and orders the groups by their best result.
 */
function groupResults(results: PaletteResult[]): PaletteResult[] {
  const bestById = new Map<string, PaletteResult>();
  for (const result of results) {
    const existing = bestById.get(result.id);
    if (!existing || existing.score < result.score) {
      bestById.set(result.id, result);
    }
  }

  const groups = new Map<ResultGroup, PaletteResult[]>();
  for (const result of bestById.values()) {
    const group = groups.get(result.group) ?? [];
    group.push(result);
    groups.set(result.group, group);
  }

  const sortedGroups: PaletteResult[][] = [];
  for (const [group, members] of groups) {
    members.sort((a, b) => b.score - a.score);
    sortedGroups.push(members.slice(0, GROUP_LIMITS[group]));
  }
  sortedGroups.sort((a, b) => b[0].score - a[0].score);
  return sortedGroups.flat();
}
