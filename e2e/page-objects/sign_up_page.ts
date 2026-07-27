import { Page } from "@playwright/test";

export class SignUpPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/users/sign_up?locale=en");
  }

  async fillForm(email: string) {
    await this.page.getByLabel("Email").fill(email);
    await this.page.getByLabel("Password", { exact: true }).fill("password");
    await this.page.getByLabel("Password confirmation").fill("password");
    await this.page.getByLabel(/I consent/).check();
  }

  async forceCaptchaError() {
    await this.page.locator("altcha-widget").evaluate((widget) => {
      widget.setAttribute("configuration", JSON.stringify({ mockError: true }));
    });
  }

  async submit() {
    await this.page.getByRole("button", { name: "Register" }).click();
  }
}
