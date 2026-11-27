import { tokenize } from "./matching/normalize";
import type { PaletteResult, ResultGroup } from "./types";

const OPTION_ID_PREFIX = "command-palette-option-";

/**
 * Renders the palette's results into its listbox, grouped under headings.
 *
 * Rows are cloned from the <template>s of CommandPaletteComponent and filled
 * via textContent.
 */
export class ResultList {
  private results: PaletteResult[] = [];
  private activeIndex = -1;

  constructor(
    private readonly listbox: HTMLElement,
    private readonly input: HTMLInputElement,
    private readonly groupTemplate: HTMLTemplateElement,
    private readonly optionTemplate: HTMLTemplateElement,
    private readonly groupLabels: Record<ResultGroup, string>,
  ) {}

  render(results: PaletteResult[], query: string): void {
    this.results = results;
    this.listbox.replaceChildren();
    const tokens = tokenize(query);

    let groupElement: HTMLElement | null = null;
    let currentGroup: ResultGroup | null = null;
    results.forEach((result, index) => {
      if (result.group !== currentGroup || !groupElement) {
        currentGroup = result.group;
        groupElement = this.groupElement(result.group);
        this.listbox.append(groupElement);
      }
      groupElement.append(this.optionElement(result, index, tokens));
    });

    this.activate(results.length > 0 ? 0 : -1);
  }

  get active(): PaletteResult | undefined {
    return this.results[this.activeIndex];
  }

  get isEmpty(): boolean {
    return this.results.length === 0;
  }

  /** Moves the active option up (-1) or down (+1), wrapping around. */
  move(step: number): void {
    if (this.results.length === 0) {
      return;
    }
    const count = this.results.length;
    this.activate((this.activeIndex + step + count) % count);
  }

  /** The result an option element (or something inside it) stands for. */
  resultFor(element: Element): PaletteResult | undefined {
    const option = element.closest<HTMLElement>("[role=option]");
    if (!option) {
      return undefined;
    }
    return this.results[Number(option.dataset.index)];
  }

  activateElement(element: Element): void {
    const option = element.closest<HTMLElement>("[role=option]");
    const index = Number(option?.dataset.index);
    if (option && index !== this.activeIndex) {
      this.activate(index);
    }
  }

  private activate(index: number): void {
    this.activeIndex = index;
    for (const option of this.listbox.querySelectorAll<HTMLElement>("[role=option]")) {
      option.setAttribute("aria-selected", String(Number(option.dataset.index) === index));
    }

    if (index < 0) {
      this.input.removeAttribute("aria-activedescendant");
      return;
    }
    const option = document.getElementById(OPTION_ID_PREFIX + String(index));
    this.input.setAttribute("aria-activedescendant", OPTION_ID_PREFIX + String(index));
    option?.scrollIntoView({ block: "nearest" });
  }

  private groupElement(group: ResultGroup): HTMLElement {
    const fragment = this.groupTemplate.content.cloneNode(true) as DocumentFragment;
    const element = fragment.firstElementChild as HTMLElement;
    const heading = element.querySelector<HTMLElement>("[data-slot=heading]");
    const headingId = `command-palette-group-${group}`;
    if (heading) {
      heading.textContent = this.groupLabels[group];
      heading.id = headingId;
    }
    element.setAttribute("aria-labelledby", headingId);
    return element;
  }

  private optionElement(result: PaletteResult, index: number, tokens: string[]): HTMLElement {
    const fragment = this.optionTemplate.content.cloneNode(true) as DocumentFragment;
    const element = fragment.firstElementChild as HTMLElement;
    element.id = OPTION_ID_PREFIX + String(index);
    element.dataset.index = String(index);

    element.querySelector("[data-slot=icon]")?.classList.add(result.icon);
    const label = element.querySelector<HTMLElement>("[data-slot=label]");
    if (label) {
      appendHighlighted(label, result.label, tokens);
    }
    const detail = element.querySelector<HTMLElement>("[data-slot=detail]");
    if (detail) {
      appendHighlighted(detail, result.detail, tokens);
    }
    return element;
  }
}

/**
 * Wraps the first occurrence of each query word in <mark> to highlight it.
 */
function appendHighlighted(element: HTMLElement, text: string, tokens: string[]): void {
  const ranges = highlightRanges(text, tokens);
  let position = 0;
  for (const [start, end] of ranges) {
    element.append(text.slice(position, start));
    const mark = document.createElement("mark");
    mark.textContent = text.slice(start, end);
    element.append(mark);
    position = end;
  }
  element.append(text.slice(position));
}

/** Sorted, non-overlapping [start, end) ranges of the words in the text. */
function highlightRanges(text: string, tokens: string[]): [number, number][] {
  const lowercase = text.toLowerCase();
  const ranges: [number, number][] = [];
  for (const token of tokens) {
    const start = lowercase.indexOf(token);
    if (start !== -1) {
      ranges.push([start, start + token.length]);
    }
  }
  ranges.sort((a, b) => a[0] - b[0]);

  const merged: [number, number][] = [];
  for (const range of ranges) {
    const last = merged.at(-1);
    if (last && range[0] <= last[1]) {
      last[1] = Math.max(last[1], range[1]);
    }
    else {
      merged.push(range);
    }
  }
  return merged;
}
