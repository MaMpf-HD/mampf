import { Page } from "@playwright/test";

export class LoginPage {
  public readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/users/sign_in?locale=en");
  }

  async login(email: string, password?: string) {
    await this.page.getByLabel("Email").fill(email);
    if (password) {
      await this.page.getByLabel("Password", { exact: true }).fill(password);
    }
    // Without this wait, the next attempt fills the form while the answer to
    // this one is still on its way, and the click submits the wrong values.
    const submitted = this.page.waitForResponse(response =>
      response.request().method() === "POST"
      && response.url().includes("/users/sign_in"));
    await this.page.getByRole("button", { name: "Login", exact: true }).click();
    await submitted;
  }
}
