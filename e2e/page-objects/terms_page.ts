import { Page } from "../_support/fixtures";

export class TermsPage {
  readonly page: Page;
  readonly link = "/terms";

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async createTerm(termName: number, season: "SS" | "WS") {
    const newTermsPromises = this.page.waitForResponse(response =>
      response.url().includes("terms/new"),
    );
    await this.page.getByRole("link", { name: "Create Term" }).click();
    await newTermsPromises;
    await this.page.selectOption("#term_year", termName.toString());
    await this.page.selectOption("#term_season", season);
    await this.page.locator("#new_term").getByRole("button", { name: "Save" }).click();
  }

  async deleteTerm(termName: number, season: "SS" | "WS") {
    this.page.on("dialog", dialog => dialog.accept());
    await this.getTermRow(termName, season).getByRole("button", { name: "Delete" }).click();
  }

  getTermRow(termName: number, season: "SS" | "WS") {
    return this.page.getByTestId(`term-row-${termName}-${season}`);
  }
}
