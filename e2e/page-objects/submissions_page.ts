import { expect, Page } from "../_support/fixtures";
import { attachToUploadArea } from "../_support/uploads";

const SUBMISSION_FORM = "form[data-controller~='submission-upload']";

export class SubmissionsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/submissions`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  /**
   * Hands a file to the submission form and uploads it. The upload waits for
   * the assurance about third-party rights, so the box is ticked first.
   */
  async uploadSubmission(filePath = "e2e/files/manuscript.pdf") {
    // The form, whichever of the two it is - only the new one offers invitees.
    await expect(this.page.getByRole("button", { name: "Save" })).toBeVisible();

    await attachToUploadArea(this.page, SUBMISSION_FORM, filePath);
    await this.page.getByRole("checkbox", { name: "I assure that" }).check();
    await this.page.getByRole("button", { name: "Upload file" }).click();

    // Scoped to the form: a card elsewhere on the page may well already show a
    // file of the same name.
    const fileName = filePath.split("/").at(-1) ?? filePath;
    await expect(this.page.locator(SUBMISSION_FORM).getByText(fileName))
      .toBeVisible();
  }

  /** Opens the card's form, uploads and saves; the card comes back in place. */
  async createSubmission() {
    await this.page.getByRole("link", { name: "Hand in" }).click();
    await this.uploadSubmission();

    const saved = this.page.waitForResponse(
      response => response.request().method() === "POST",
    );
    await this.page.getByRole("button", { name: "Save" }).click();
    await saved;
    await expect(this.page.getByRole("link", { name: "Replace file" }))
      .toBeVisible();
  }
}
