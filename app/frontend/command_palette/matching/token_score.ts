import type { Findable, ItemText } from "../types";

/** How well one query word matches a text. */
export const ScoreTier = {
  EXACT: 1,
  PREFIX: 0.9,
  WORD_START: 0.8,
  ACRONYM: 0.7,
  SUBSTRING: 0.6,
  SUBSEQUENCE: 0.3,
  NONE: 0,
} as const;

/**
 * A subsequence match ("exrc" in "exercises") is only tried for words of
 * this length, as shorter ones match almost anything.
 */
const MIN_SUBSEQUENCE_LENGTH = 3;

/**
 * A page can be searched by a label (i.e. the visible name, e.g. "Orga")
 * or keywords (hidden synonyms, e.g. "General information", "exam data" etc.).
 * Labels are more important, so a match in the keywords is scaled down a bit.
 */
const KEYWORD_WEIGHT = 0.9;

/**
 * Scores one normalized query word against one text.
 *
 * Examples for the text "Lineare Algebra 2" (compact "linearealgebra2"):
 * "linearealgebra2" → EXACT, "line" → PREFIX, "alg" → WORD_START,
 * "la2" → ACRONYM, "neare" → SUBSTRING, "lnalg" → SUBSEQUENCE.
 *
 * A number only matches a whole word, so that "2" does not find every "24/25".
 */
function scoreToken(token: string, text: ItemText): number {
  if (token === text.compact || text.words.includes(token)) {
    return ScoreTier.EXACT;
  }
  if (/^\d+$/.test(token)) {
    return ScoreTier.NONE;
  }
  if (text.compact.startsWith(token)) {
    return ScoreTier.PREFIX;
  }
  if (text.words.some(word => word.startsWith(token))) {
    return ScoreTier.WORD_START;
  }
  if (token.length > 1 && acronym(text).startsWith(token)) {
    return ScoreTier.ACRONYM;
  }
  if (text.compact.includes(token)) {
    return ScoreTier.SUBSTRING;
  }
  if (token.length >= MIN_SUBSEQUENCE_LENGTH && isSubsequenceFromWordStart(token, text)) {
    return ScoreTier.SUBSEQUENCE;
  }
  return ScoreTier.NONE;
}

function bestScore(token: string, texts: ItemText[]): number {
  let best: number = ScoreTier.NONE;
  for (const text of texts) {
    best = Math.max(best, scoreToken(token, text));
  }
  return best;
}

/**
 * How well a query matches an item: every query word must match one of its
 * texts or keywords, e.g. for "la2 ws", "la2" a lecture's short title and
 * "ws" its term. The result is the average over the words.
 */
export function scoreQuery(queryWords: string[], item: Findable): number {
  if (queryWords.length === 0) {
    return ScoreTier.NONE;
  }

  let sum = 0;
  for (const word of queryWords) {
    const score = Math.max(bestScore(word, item.texts),
      bestScore(word, item.keywords ?? []) * KEYWORD_WEIGHT);
    if (score === ScoreTier.NONE) {
      return ScoreTier.NONE;
    }
    sum += score;
  }
  return sum / queryWords.length;
}

/**
 * The first letter of each word, e.g. "lineare algebra 2" → "la2".
 */
function acronym(text: ItemText): string {
  return text.words.map(word => (/^\d+$/.test(word) ? word : word[0])).join("");
}

/**
 * Whether all letters of the query word appear in the text in the same
 * order, starting at the beginning of one of its words: "exrc" matches
 * "exercises", but "xrc" does not, as no word starts with "x".
 */
function isSubsequenceFromWordStart(token: string, text: ItemText): boolean {
  let wordStart = 0;
  for (const word of text.words) {
    if (word.startsWith(token[0]) && isSubsequence(token, text.compact.slice(wordStart))) {
      return true;
    }
    wordStart += word.length;
  }
  return false;
}

function isSubsequence(token: string, text: string): boolean {
  let position = 0;
  for (const letter of token) {
    position = text.indexOf(letter, position);
    if (position === -1) {
      return false;
    }
    position += 1;
  }
  return true;
}
