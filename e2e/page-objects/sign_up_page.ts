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
    await this.page.getByRole("checkbox", { name: "robot" }).click();

    // Wait for verification to complete (wait for hidden input to be populated)
    await this.page.waitForFunction(() => {
      const input = document.querySelector('input[name="altcha"]');
      return input && (input as HTMLInputElement).value.length > 0;
    });
  }

  async disableCaptcha() {
    const checkbox = this.page.getByRole("checkbox", { name: "robot" });
    await checkbox.evaluate((el) => {
      el.removeAttribute("required");
    });
  }

  async submit() {
    await this.page.getByRole("button", { name: "Register" }).click();
  }
}
