import { expect, test } from "./_support/fixtures";
import { SignUpPage } from "./page-objects/sign_up_page";

test.describe("User Registration", () => {
  test("can sign up with valid captcha", async ({ page }) => {
    const signUpPage = new SignUpPage(page);
    await signUpPage.goto();

    const email = `testuser_${Date.now()}@example.com`;

    await signUpPage.fillForm(email);
    await signUpPage.solveCaptcha();
    await signUpPage.submit();

    // Expect successful registration (redirect to root or dashboard)
    // Or check for success message
    await expect(page.getByText("Welcome! You have signed up successfully.")).toBeVisible();
  });

  test("cannot sign up without solving captcha", async ({ page }) => {
    const signUpPage = new SignUpPage(page);
    await signUpPage.goto();

    const email = `testuser_fail_${Date.now()}@example.com`;

    await signUpPage.fillForm(email);

    // Hack: Remove required attribute from the internal checkbox to test backend validation
    // properly, as otherwise the browser would prevent the form submission.
    await page.evaluate(() => {
      const widget = document.querySelector("altcha-widget");
      const checkbox = widget?.shadowRoot?.querySelector('input[type="checkbox"]');
      checkbox?.removeAttribute("required");
    });

    // Skip captcha solving
    await signUpPage.submit();

    // Expect error message
    await expect(page.getByText("The captcha test failed.")).toBeVisible();
  });
});
