import { expect, Locator, Page } from "../_support/fixtures";

const DIALOG_NAME = "Quick navigation";

export class CommandPalette {
  readonly page: Page;
  readonly trigger: Locator;
  readonly dialog: Locator;
  readonly input: Locator;

  constructor(page: Page) {
    this.page = page;
    this.trigger = page.getByRole("button", { name: /Search or jump to/ });
    this.dialog = page.getByRole("dialog", { name: DIALOG_NAME });
    this.input = page.getByRole("combobox", { name: DIALOG_NAME });
  }

  /**
   * Opens the page and waits for /command_palette/me, which the palette
   * requests once the browser is idle (preloadWhenIdle).
   */
  async goto(path: string) {
    const dataLoaded = this.page.waitForResponse(/\/command_palette\/me/);
    await this.page.goto(path);
    await dataLoaded;
  }

  async open() {
    await this.trigger.click();
    await expect(this.dialog).toBeVisible();
  }

  /** Opens the palette unless it is open already, and types the query. */
  async search(query: string) {
    if (!(await this.dialog.isVisible())) {
      await this.open();
    }
    await this.input.fill(query);
  }

  async chooseActive() {
    await this.input.press("Enter");
  }

  get firstOption(): Locator {
    return this.dialog.getByRole("option").first();
  }

  option(name: string | RegExp): Locator {
    return this.dialog.getByRole("option", { name: name, exact: typeof name === "string" });
  }

  group(name: string): Locator {
    return this.dialog.getByRole("group", { name: name });
  }
}
