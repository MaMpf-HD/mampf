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
    await this.page.getByRole("button", { name: "Login" }).click();
  }
}
