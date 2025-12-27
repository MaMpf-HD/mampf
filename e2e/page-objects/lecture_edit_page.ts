import { Page } from "../_support/fixtures";

/**
 * Page Object for the Lecture Edit page.
 */
export class LectureEditPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/edit`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  get campaignsTab() {
    // The tabs are buttons with role="tab"
    return this.page.getByRole("tab", { name: "Registrations" });
  }
}
