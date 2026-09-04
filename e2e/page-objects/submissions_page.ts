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

  async selectInviteeInTomSelect(page: Page, containerSelector: string, name: string) {
    const container = page.getByTestId(containerSelector);
    const input = container.locator("input:not([type='hidden'])").first();

    await input.click();
    await input.fill(name);

    await page.locator(".ts-dropdown .option", { hasText: name }).first().click();
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

  async createSubmission(inviteeName?: string) {
    await this.page.getByRole("button", { name: "create" }).click();

    if (inviteeName) {
      await this.selectInviteeInTomSelect(this.page, "submission-invites", inviteeName);
    }

    await this.uploadSubmission();

    const saveRequestPromise = this.page.waitForResponse("/submissions");
    await this.page.getByRole("button", { name: "save" }).click();
    await saveRequestPromise;

    await this.page.pause();
    await expect(this.page.getByTestId("submission-token").last()).toBeVisible();
    const token = (await this.page.getByTestId("submission-token").last().innerText()).trim();

    await expect(this.page.getByRole("button", { name: "edit" })).toBeVisible();

    return token;
  }

  async joinSubmission(token: string) {
    await this.page.pause();
    await this.page.getByRole("button", { name: "join" }).click(); // join submission button
    await this.page.getByRole("textbox").fill(token); // fill token input field
    await this.page.getByRole("button", { name: "join" }).click();
    await expect(this.page.getByRole("button", { name: "leave" })).toBeVisible(); // confirmation visible
  }

  async acceptSubmissionInvite(idx: number = 0) {
    await this.page.getByTestId(`accept-invite-${idx}`).click();
  }

  async acceptSubmissionInviteFrom(inviterName: string) {
    const inviteBlock = this.page.locator(".alert", { hasText: inviterName });
    await inviteBlock.getByRole("button", { name: "accept" }).click();
  }

  async acceptTextFrom(inviterName: string) {
    const inviteBlock = this.page.locator(".alert", { hasText: inviterName });
    // if it won't work we try something with this.page.getByTestID("accept-invite")
  }

  currentSubmissionTeam() {
    return this.page.getByTestId("current-submissions").getByTestId("submission-team");
  }


}
