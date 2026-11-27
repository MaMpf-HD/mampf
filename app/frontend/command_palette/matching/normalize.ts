import type { ItemText } from "../types";

/**
 * Brings text into the form in which the palette compares it: lowercase,
 * without accents ("Übungen" → "ubungen"), "ß" as "ss" and any punctuation
 * as a space ("WS 24/25" → "ws 24 25").
 */
function normalize(text: string): string {
  const lowercase = text.toLowerCase().replaceAll("ß", "ss");
  const withoutAccents = lowercase.normalize("NFD").replace(/\p{Diacritic}/gu, "");
  return withoutAccents.replace(/[^\p{Letter}\p{Number}]+/gu, " ").trim();
}

export function tokenize(text: string): string[] {
  const normalized = normalize(text);
  if (normalized === "") {
    return [];
  }
  return normalized.split(" ");
}

/**
 * Prepares a text an item is found by for matching. The compact form lets
 * "la2" match "LA 2".
 */
export function itemText(text: string): ItemText {
  const words = tokenize(text);
  return { words: words, compact: words.join("") };
}
