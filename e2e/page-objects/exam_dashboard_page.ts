import { Locator, Page } from "../_support/fixtures";

/**
 * Page object for the exams of a lecture: the list on the lecture's exam tab
 * and the dashboard of a single exam. Like the assignment dashboard, an exam
 * dashboard has no page of its own — it is streamed into the list's container,
 * so it is always reached by opening an exam from there.
 */
export class ExamDashboardPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/edit?tab=exams`;
  }

  async gotoList() {
    await this.page.goto(this.link);
  }

  async open(examTitle: string) {
    await this.gotoList();
    await this.page.getByRole("link", { name: examTitle, exact: true }).click();
  }

  /** Everything the exam tab streams into, list or dashboard. */
  get container(): Locator {
    return this.page.locator("#exams_container");
  }

  tab(name: string): Locator {
    return this.container.getByRole("tab", { name });
  }

  /** Bootstrap keeps every pane in the DOM, so only the shown one counts. */
  get pane(): Locator {
    return this.container.getByRole("tabpanel").filter({ visible: true });
  }
}
