import { expect, test } from "./_support/fixtures";
import { SignUpPage } from "./page-objects/sign_up_page";

test("can sign up with valid captcha", async ({ page }) => {
  const signUpPage = new SignUpPage(page);
  await signUpPage.goto();

  const email = `testuser_${Date.now()}@example.com`;
  await signUpPage.fillForm(email);
  await signUpPage.solveCaptcha();
  await signUpPage.submit();

  await expect(page.getByText("activate your account")).toBeVisible();
});

test("cannot sign up without solving captcha", async ({ page }) => {
  const signUpPage = new SignUpPage(page);
  await signUpPage.goto();

  const email = `testuser_fail_${Date.now()}@example.com`;
  await signUpPage.fillForm(email);
  await signUpPage.disableCaptcha();
  await signUpPage.submit();

  await expect(page.getByText("The captcha test failed.")).toBeVisible();
});
