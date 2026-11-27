import type {
  IndexedDestination, IndexedGlobal, LectureEntry, PaletteResult, ResultGroup,
} from "./types";

/** The parts of a PaletteResult#id, e.g. "lecture:5:exercises". */
export interface ResultId {
  kind: string;
  key: string;
  destinationKey?: string;
}

export function parseResultId(id: string): ResultId {
  const [kind, key, destinationKey] = id.split(":");
  return { kind, key, destinationKey };
}

/** The name under which a lecture is shown, e.g. "LA 2 WS 24/25". */
function lectureName(lecture: LectureEntry): string {
  return lecture.term ? `${lecture.short} ${lecture.term}` : lecture.short;
}

export function lectureResult(
  lecture: LectureEntry, group: ResultGroup, score: number,
): PaletteResult {
  return {
    id: `lecture:${lecture.id}`,
    group: group,
    icon: "bi-journal-bookmark",
    label: lectureName(lecture),
    detail: lecture.title,
    path: lecture.path,
    method: "get",
    score: score,
  };
}

export function lecturePageResult(
  lecture: LectureEntry, destination: IndexedDestination, path: string,
  group: ResultGroup, score: number,
): PaletteResult {
  return {
    id: `lecture:${lecture.id}:${destination.info.key}`,
    group: group,
    icon: destination.info.icon,
    label: destination.info.label,
    detail: lectureName(lecture),
    path: path,
    method: "get",
    score: score,
  };
}

export function globalResult(
  indexed: IndexedGlobal, group: ResultGroup, score: number,
): PaletteResult {
  return {
    id: `global:${indexed.item.key}`,
    group: group,
    icon: indexed.item.icon,
    label: indexed.item.label,
    detail: "",
    path: indexed.item.path,
    method: indexed.item.method,
    score: score,
  };
}
