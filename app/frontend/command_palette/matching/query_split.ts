/**
 * One way to read a query like "la2 exercises": the words naming the
 * lecture ("la2") and those naming the page inside it ("exercises").
 */
export interface QuerySplit {
  lectureTokens: string[];
  destinationTokens: string[];
}

/**
 * All ways to split the words into different parts: the first or last part
 * might be the lecture name, the other part the page name.
 *
 * For example, the query "la2 exercises" can be split into:
 * - lectureTokens: ["la2"], destinationTokens: ["exercises"]
 * - lectureTokens: ["exercises"], destinationTokens: ["la2"]
 */
export function splitQuery(tokens: string[]): QuerySplit[] {
  const splits: QuerySplit[] = [];
  for (let index = 1; index < tokens.length; index++) {
    const head = tokens.slice(0, index);
    const tail = tokens.slice(index);
    splits.push({ lectureTokens: head, destinationTokens: tail });
    splits.push({ lectureTokens: tail, destinationTokens: head });
  }
  return splits;
}
