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

  async createTerm(termYear: number, season: "SS" | "WS") {
    const form = await this.submitNewTermForm(termYear, season, "Save");
    await expect(form).toBeHidden();
    await expect(this.getTermRow(termYear, season)).toBeVisible();
  }

  async submitCreateTerm(termYear: number, season: "SS" | "WS") {
    await this.submitNewTermForm(termYear, season, "Save");
  }

  async cancelCreateTerm(termYear: number, season: "SS" | "WS") {
    const form = await this.submitNewTermForm(termYear, season, "Cancel");
    await expect(form).toBeHidden();
  }

  async deleteTerm(termYear: number, season: "SS" | "WS") {
    this.page.on("dialog", dialog => dialog.accept());
    await this.getTermRow(termYear, season).getByRole("button", { name: "Delete" }).click();
  }

  getTermRow(termYear: number, season: "SS" | "WS") {
    return this.page.getByTestId(`term-row-${termYear}-${season}`);
  }

  private async submitNewTermForm(
    termYear: number,
    season: "SS" | "WS",
    action: "Save" | "Cancel",
  ) {
    const form = this.page.locator("#new_term form");

    await this.page.getByRole("link", { name: "Create Term" }).click();
    await expect(form).toBeVisible();

    await this.page.selectOption("#term_year", termYear.toString());
    await this.page.selectOption("#term_season", season);
    await form.getByRole("button", { name: action }).click();

    return form;
  }
}
