import { Locator, Page } from "../_support/fixtures";

export class LecturePage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async gotoEdit() {
    await this.page.goto(`${this.link}/edit`);
  }

  async subscribe() {
    await this.page.getByRole("button", { name: "subscribe event series" }).click();
  }

  async toggleSectionCompletion(indexOfSection: number) {
    const buttons = this.page.getByTestId("toggle-completion-button");
    await buttons.nth(indexOfSection).click();
  }

  async getCompletionValue(): Promise<number> {
    const progressBar = this.page.getByRole("progressbar");
    const value = await progressBar.getAttribute("aria-valuenow");
    return parseInt(value ?? "0");
  }

  async getToggleCompletionButtions(): Promise<Locator[]> {
    return await this.page.getByTestId("toggle-completion-button").all();
  }

  async isNthSectionCompletionToggled(n: number): Promise<boolean> {
    const button = (await this.getToggleCompletionButtions())[n];
    const buttonClasses = await button.getAttribute("class") ?? "";
    return buttonClasses.includes("btn-success");
  }
}
