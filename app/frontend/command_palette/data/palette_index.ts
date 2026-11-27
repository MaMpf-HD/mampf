import { itemText } from "../matching/normalize";
import {
  globalResult, lecturePageResult, lectureResult, parseResultId,
} from "../results";
import type {
  GlobalItem, IndexedDestination, IndexedGlobal, IndexedLecture, IndexedRecent,
  LectureEntry, PaletteIndex, PaletteResult,
} from "../types";
import type { PaletteData } from "./palette_data";

/**
 * Prepares everything the palette searches through: the user's lectures
 * first, then the rest of the catalog, each text normalized once instead of
 * on every keystroke.
 */
export function buildIndex(
  data: PaletteData, recentIds: string[], actions: GlobalItem[],
): PaletteIndex {
  const myIds = new Set(data.user.lectures.map(lecture => lecture.id));
  const catalogOnly = data.catalog.filter(lecture => !myIds.has(lecture.id));

  const index: PaletteIndex = {
    lectures: [
      ...data.user.lectures.map(lecture => indexLecture(lecture, true)),
      ...catalogOnly.map(lecture => indexLecture(lecture, false)),
    ],
    destinations: new Map(data.user.destinations.map((info) => {
      const indexed: IndexedDestination = {
        info: info,
        labelText: itemText(info.label),
        keywordTexts: info.keywords.map(itemText),
      };
      return [info.key, indexed];
    })),
    globals: data.user.globals.map(indexGlobal),
    actions: actions.map(indexGlobal),
    recent: [],
  };
  index.recent = resolveRecent(recentIds, index).map(indexRecent);
  return index;
}

/**
 * Looks up the remembered ids in the current data, so that their labels follow
 * the locale and results the user can no longer reach are left out.
 */
function resolveRecent(ids: string[], index: PaletteIndex): PaletteResult[] {
  const lectures = new Map(index.lectures.map(indexed => [indexed.lecture.id, indexed]));
  const results: PaletteResult[] = [];

  for (const id of ids) {
    const { kind, key, destinationKey } = parseResultId(id);
    if (kind === "global") {
      const global = index.globals.find(indexed => indexed.item.key === key);
      if (global && global.item.method === "get") {
        results.push(globalResult(global, "recent", 0));
      }
      continue;
    }

    const indexed = kind === "lecture" ? lectures.get(Number(key)) : undefined;
    if (!indexed) {
      continue;
    }
    if (destinationKey === undefined) {
      results.push(lectureResult(indexed.lecture, "recent", 0));
      continue;
    }
    const path = indexed.lecture.destinations?.[destinationKey];
    const destination = index.destinations.get(destinationKey);
    if (path && destination) {
      results.push(lecturePageResult(indexed.lecture, destination, path, "recent", 0));
    }
  }
  return results;
}

function indexLecture(lecture: LectureEntry, mine: boolean): IndexedLecture {
  const texts = [itemText(lecture.short), itemText(lecture.title)];
  if (lecture.term) {
    texts.push(itemText(lecture.term));
  }
  return { lecture, mine, texts };
}

function indexGlobal(item: GlobalItem): IndexedGlobal {
  return {
    item: item,
    labelText: itemText(item.label),
    keywordTexts: item.keywords.map(itemText),
  };
}

function indexRecent(result: PaletteResult): IndexedRecent {
  return { result, texts: [itemText(result.label), itemText(result.detail)] };
}
