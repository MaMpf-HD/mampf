import { Locator, Page } from "../_support/fixtures";

/** `animation` in assessment/sortable.controller.js */
const SORTABLE_ANIMATION_MS = 150;

/**
 * Page object for the assessment area of a lecture: the overview of all
 * assignments and the dashboard of a single one. The dashboard has no page of
 * its own — it is streamed into the overview — so it is always reached by
 * opening an assignment from there.
 */
export class AssessmentDashboardPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/edit?tab=assessments`;
  }

  async gotoOverview() {
    await this.page.goto(this.link);
  }

  async open(assignmentTitle: string) {
    await this.gotoOverview();
    await this.page.getByRole("link", { name: assignmentTitle, exact: true }).click();
  }

  /** The lecture's own tabs wrap the dashboard's, so scope to the inner set. */
  get dashboard(): Locator {
    return this.page.locator("[data-cy='assessment-dashboard']");
  }

  tab(name: string): Locator {
    return this.dashboard.getByRole("tab", { name, exact: true });
  }

  /** Bootstrap keeps every pane in the DOM, so scope to the one on screen. */
  get pane(): Locator {
    return this.dashboard.getByRole("tabpanel").filter({ visible: true });
  }

  get saveButton(): Locator {
    return this.pane.getByRole("button", { name: "Save", exact: true });
  }

  get cancelButton(): Locator {
    return this.pane.getByRole("button", { name: "Cancel", exact: true });
  }

  get unsavedChangesWarning(): Locator {
    return this.pane.getByText("Attention, there are unsaved changes!");
  }

  get tasks(): Locator {
    return this.pane.locator("[data-sortable-item]");
  }

  taskCard(description: string): Locator {
    return this.tasks.filter({ hasText: description });
  }

  /** The running numbers next to the task cards, top to bottom. */
  get taskPositions(): Locator {
    return this.pane.locator("[data-sortable-index]");
  }

  get submissionSettingsForm(): Locator {
    return this.page.locator("#lecture-assignments-form");
  }

  /**
   * Drags one task above another. Sortable.js starts a drag from raw mouse
   * events and only once the pointer has travelled, which is more than
   * `dragTo` produces; where the task lands depends on which half of the
   * target it is dropped on, so aim at the upper edge.
   */
  async dragTaskAbove(dragged: string, target: string) {
    const handle = this.taskCard(dragged).locator("[data-sortable-handle]");
    const source = await handle.boundingBox();

    if (!source) {
      throw new Error(`cannot drag "${dragged}": not on screen`);
    }

    const x = source.x + 20;
    await this.page.mouse.move(x, source.y + (source.height / 2));
    await this.page.mouse.down();
    await this.page.mouse.move(x, source.y - 10, { steps: 5 });
    await this.settle();

    // measured only now: starting the drag inserts a placeholder and moves
    // every card below it
    const destination = await this.taskCard(target).boundingBox();

    if (!destination) {
      throw new Error(`cannot drop above "${target}": not on screen`);
    }

    await this.page.mouse.move(x, destination.y + 5, { steps: 15 });
    await this.settle();
    await this.page.mouse.move(x, destination.y + 2, { steps: 3 });
    await this.settle();
    await this.page.mouse.up();
  }

  /** Sortable animates each swap and ignores pointer moves while it runs. */
  private async settle() {
    await this.page.waitForTimeout(SORTABLE_ANIMATION_MS * 2);
  }
}
