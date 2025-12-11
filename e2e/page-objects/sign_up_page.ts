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

  async solveCaptcha() {
    // Wait for the widget to be ready
    await this.page.waitForSelector("altcha-widget");

    // Use Playwright's locator which pierces Shadow DOM automatically
    const checkbox = this.page.locator("altcha-widget input[type='checkbox']");

    await checkbox.waitFor({ state: "visible" });
    await checkbox.click();

    // Wait for verification to complete
    // The widget usually shows a "Verified" state or similar
    // We can check if the hidden input has a value
    await this.page.waitForFunction(() => {
      const input = document.querySelector('input[name="altcha"]');
      return input && (input as HTMLInputElement).value.length > 0;
    });
  }

  async submit() {
    await this.page.getByRole("button", { name: "Register" }).click();
  }
}
