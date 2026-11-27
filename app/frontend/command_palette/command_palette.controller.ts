import { Controller } from "@hotwired/stimulus";
import { forgetData, loadPaletteData } from "./data/palette_data";
import { buildIndex } from "./data/palette_index";
import { loadRecentIds, rememberRecentId } from "./data/recent_results";
import { rank } from "./matching/ranking";
import { ResultList } from "./result_list";
import type { GlobalItem, PaletteIndex, PaletteResult, ResultGroup } from "./types";

declare global {
  interface Window {
    Turbo?: { visit(location: string): void };
  }
}

/** Elements in which Ctrl+K already means something (Trix: insert a link). */
const OWN_CTRL_K_SELECTOR = "trix-editor, .CodeMirror, .cm-editor";

/** On a Mac, ⌘+K opens the palette instead of Ctrl+K. */
const IS_MAC = /Mac|iPhone|iPad/.test(navigator.userAgent);

export default class extends Controller {
  static targets = [
    "dialog", "input", "listbox", "groupTemplate", "optionTemplate",
    "loading", "empty", "error", "shortcut", "modifier",
  ];

  static values = {
    meUrl: String,
    catalogUrl: String,
    userId: Number,
    lectureId: Number,
    pinned: Boolean,
    pinAction: Object,
    unpinAction: Object,
    groupLabels: Object,
  };

  declare readonly dialogTarget: HTMLDialogElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly listboxTarget: HTMLElement;
  declare readonly groupTemplateTarget: HTMLTemplateElement;
  declare readonly optionTemplateTarget: HTMLTemplateElement;
  declare readonly loadingTarget: HTMLElement;
  declare readonly emptyTarget: HTMLElement;
  declare readonly errorTarget: HTMLElement;
  declare readonly shortcutTargets: HTMLElement[];
  declare readonly modifierTargets: HTMLElement[];

  declare readonly meUrlValue: string;
  declare readonly catalogUrlValue: string;
  declare readonly userIdValue: number;
  declare readonly lectureIdValue: number;
  declare readonly hasLectureIdValue: boolean;
  declare pinnedValue: boolean;
  declare readonly pinActionValue: GlobalItem;
  declare readonly unpinActionValue: GlobalItem;
  declare readonly hasPinActionValue: boolean;
  declare readonly groupLabelsValue: Record<ResultGroup, string>;

  private index: PaletteIndex | null = null;
  private resultList!: ResultList;
  private pointerDownOnBackdrop = false;
  private readonly onShortcut = (event: KeyboardEvent): void => {
    this.handleShortcut(event);
  };

  private readonly onBeforeCache = (): void => {
    this.close();
  };

  connect(): void {
    this.resultList = new ResultList(this.listboxTarget, this.inputTarget,
      this.groupTemplateTarget, this.optionTemplateTarget, this.groupLabelsValue);
    document.addEventListener("keydown", this.onShortcut);
    document.addEventListener("turbo:before-cache", this.onBeforeCache);
    this.showPlatformShortcut();
    if (this.hasLectureIdValue) {
      rememberRecentId(this.userIdValue, `lecture:${this.lectureIdValue}`);
    }
    this.preloadWhenIdle();
  }

  disconnect(): void {
    document.removeEventListener("keydown", this.onShortcut);
    document.removeEventListener("turbo:before-cache", this.onBeforeCache);
  }

  open(): void {
    if (this.dialogTarget.open) {
      return;
    }
    this.inputTarget.value = "";
    this.dialogTarget.showModal();
    this.inputTarget.focus();
    void this.refresh();
  }

  close(): void {
    if (this.dialogTarget.open) {
      this.dialogTarget.close();
    }
  }

  search(): void {
    this.render();
  }

  navigate(event: KeyboardEvent): void {
    if (event.isComposing) {
      return;
    }
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      this.resultList.move(event.key === "ArrowDown" ? 1 : -1);
    }
    else if (event.key === "Enter") {
      event.preventDefault();
      const result = this.resultList.active;
      if (result) {
        this.choose(result, event.ctrlKey || event.metaKey);
      }
    }
  }

  pick(event: MouseEvent): void {
    const result = this.resultList.resultFor(event.target as Element);
    if (result) {
      event.preventDefault();
      this.choose(result, event.ctrlKey || event.metaKey);
    }
  }

  hover(event: MouseEvent): void {
    this.resultList.activateElement(event.target as Element);
  }

  /** A click on a heading or between the options would take the focus off the input. */
  keepFocus(event: MouseEvent): void {
    event.preventDefault();
  }

  notePointerDown(event: PointerEvent): void {
    this.pointerDownOnBackdrop = event.target === this.dialogTarget;
  }

  /**
   * Closes the dialog on a click on its backdrop (but not after a drag from
   * the input to the backdrop).
   */
  closeOnBackdrop(event: MouseEvent): void {
    if (event.target === this.dialogTarget && this.pointerDownOnBackdrop) {
      this.close();
    }
  }

  /**
   * <dialog> closes on Escape natively, but some embedded browsers (e.g. the
   * one in VS Code) only send the keydown to the page.
   */
  private handleShortcut(event: KeyboardEvent): void {
    if (event.isComposing || event.repeat) {
      return;
    }
    if (event.key === "Escape" && this.dialogTarget.open) {
      event.preventDefault();
      this.close();
      return;
    }

    const modifier = IS_MAC ? event.metaKey : event.ctrlKey;
    if (!modifier || event.altKey || event.shiftKey) {
      return;
    }
    const isK = event.key.toLowerCase() === "k" || event.code === "KeyK";
    const isJ = event.key.toLowerCase() === "j" || event.code === "KeyJ";
    if (!isK && !isJ) {
      return;
    }
    const target = event.target as Element | null;
    if (isK && target?.closest(OWN_CTRL_K_SELECTOR)) {
      return;
    }

    event.preventDefault();
    if (this.dialogTarget.open) {
      this.close();
    }
    else {
      this.open();
    }
  }

  /**
   * Rebuilds the index when the palette opens. The underlying data is cached,
   * but some things like "recently visited" and "pinned" change over time.
   */
  private async refresh(): Promise<void> {
    this.errorTarget.hidden = true;
    if (!this.index) {
      this.loadingTarget.hidden = false;
    }
    try {
      const data = await loadPaletteData(this.urls);
      this.index = buildIndex(data, loadRecentIds(this.userIdValue), this.actions);
    }
    catch (error) {
      console.error(error);
      this.errorTarget.hidden = false;
    }
    finally {
      this.loadingTarget.hidden = true;
    }
    this.render();
  }

  private render(): void {
    if (!this.index) {
      return;
    }
    const query = this.inputTarget.value;
    this.resultList.render(rank(query, this.index), query);
    this.emptyTarget.hidden = !this.resultList.isEmpty || query.trim() === "";
  }

  private choose(result: PaletteResult, inNewTab: boolean): void {
    if (result.method !== "get") {
      this.close();
      this.submit(result);
      return;
    }

    rememberRecentId(this.userIdValue, result.id);
    if (inNewTab) {
      window.open(result.path, "_blank", "noopener");
      return;
    }
    this.close();
    if (window.Turbo) {
      window.Turbo.visit(result.path);
    }
    else {
      window.location.assign(result.path);
    }
  }

  /**
   * Sends a non-GET result (pinning, unpinning) as a form, so that Turbo
   * handles the response like any other form submission.
   */
  private submit(result: PaletteResult): void {
    const form = document.createElement("form");
    form.method = "post";
    form.action = result.path;
    form.hidden = true;
    form.append(hiddenInput("_method", result.method));
    const token = document.querySelector<HTMLMetaElement>("meta[name=csrf-token]")?.content;
    if (token) {
      form.append(hiddenInput("authenticity_token", token));
    }

    const isPinToggle = result.id === `global:${this.pinActionValue.key}`
      || result.id === `global:${this.unpinActionValue.key}`;
    form.addEventListener("turbo:submit-end", (event) => {
      const detail = (event as CustomEvent<{ success: boolean }>).detail;
      if (isPinToggle && detail.success) {
        this.pinnedValue = !this.pinnedValue;
        forgetData(this.meUrlValue);
      }
      form.remove();
    });

    document.body.append(form);
    form.requestSubmit();
  }

  /** Commands that depend on the current page: (un)pinning its lecture. */
  private get actions(): GlobalItem[] {
    if (!this.hasPinActionValue) {
      return [];
    }
    return [this.pinnedValue ? this.unpinActionValue : this.pinActionValue];
  }

  private get urls(): { me: string; catalog: string } {
    return { me: this.meUrlValue, catalog: this.catalogUrlValue };
  }

  /** Fetches the data in the background, so that the first open is instant. */
  private preloadWhenIdle(): void {
    const preload = (): void => {
      loadPaletteData(this.urls).catch(() => {
        console.warn("Failed to preload command palette data. Will retry on next open.");
      });
    };
    if ("requestIdleCallback" in window) {
      window.requestIdleCallback(preload);
    }
    else {
      setTimeout(preload, 1000);
    }
  }

  private showPlatformShortcut(): void {
    if (!IS_MAC) {
      return;
    }
    for (const shortcut of this.shortcutTargets) {
      shortcut.textContent = "⌘ K";
    }
    for (const modifier of this.modifierTargets) {
      modifier.textContent = "⌘";
    }
  }
}

function hiddenInput(name: string, value: string): HTMLInputElement {
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = name;
  input.value = value;
  return input;
}
