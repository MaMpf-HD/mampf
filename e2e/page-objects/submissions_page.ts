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
    await expect(this.page.getByText("invitations to")).toBeVisible();

    await attachToUploadArea(this.page, SUBMISSION_FORM, filePath);
    await this.page.getByRole("checkbox", { name: "I assure that" }).check();
    await this.page.getByRole("button", { name: "Upload file" }).click();

    const fileName = filePath.split("/").at(-1) ?? filePath;
    await expect(this.page.getByText(fileName)).toBeVisible();
  }

  async createSubmission() {
    await this.page.getByRole("button", { name: "create" }).click();
    await this.uploadSubmission();

    const saveRequestPromise = this.page.waitForResponse("/submissions");
    await this.page.getByRole("button", { name: "save" }).click();
    await saveRequestPromise;

    await this.page.pause();
    await expect(this.page.getByTestId("submission-token").last()).toBeVisible();
    const  token = (await this.page.getByTestId("submission-token").last().innerText()).trim();
    
    await expect(this.page.getByRole("button", { name: "edit" })).toBeVisible();

    return token;
  }
  
  async joinSubmission(token: string) {
    await this.page.getByRole("button", { name: "join" }).click(); // join submission button
    await this.page.getByRole("textbox").fill(token); // fill token input field
    await this.page.getByRole("button", { name: "join" }).click();
    await expect(this.page.getByRole("button", { name: "leave" })).toBeVisible(); // confirmation visible
  }

  async acceptSubmissionInvite(idx: number = 0) {
    await this.page.getByTestId(`accept-invite-${idx}`).click(); // click accept invite button
  }
}
