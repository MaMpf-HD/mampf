import { expect, Page } from "../_support/fixtures";

export class TermsPage {
  readonly page: Page;
  readonly link = "/terms";

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async createTerm(termYear: number, season: "SS" | "WS", action = "save") {
    const form = this.page.locator("#new_term form");

    await this.page.getByRole("link", { name: "Create Term" }).click();
    // Waiting for the /terms/new response is not enough: Turbo still has to swap
    // the form into the frame afterwards.
    await expect(form).toBeVisible();

    await form.locator("#term_year").selectOption(termYear.toString());
    await form.locator("#term_season").selectOption(season);
    await form
      .getByRole("button", { name: action === "save" ? "Save" : "Cancel" })
      .click();

    await this.waitForFormToSettle();
  }

  async deleteTerm(termYear: number, season: "SS" | "WS") {
    this.page.on("dialog", dialog => dialog.accept());
    await this.getTermRow(termYear, season).getByRole("button", { name: "Delete" }).click();
  }

  getTermRow(termYear: number, season: "SS" | "WS") {
    return this.page.getByTestId(`term-row-${termYear}-${season}`);
  }

  /**
   * Saving and cancelling both empty the #new_term frame — the former through
   * `turbo_stream.update(Term.new, "")`, the latter by navigating the frame to
   * /terms. An invalid save re-renders the form with errors instead.
   *
   * Returning before either has landed lets the still-pending stream wipe the
   * frame of a *later* createTerm call, right after that call loaded its form
   * into it: no button is left to click, and the test hangs until it times out.
   */
  private async waitForFormToSettle() {
    await this.page.waitForFunction(() => {
      const frame = document.querySelector("#new_term");
      if (!frame) return false;

      const form = frame.querySelector("form");
      return form === null || form.querySelector(".is-invalid") !== null;
    });
  }
}
