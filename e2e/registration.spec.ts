import { expect, test } from "./_support/fixtures";
import { confirmationLinkFor } from "./_support/mail";
import { SignUpPage } from "./page-objects/sign_up_page";

test("can sign up and confirm the account", async ({ page, request }) => {
  const signUpPage = new SignUpPage(page);
  await signUpPage.goto();

  const email = `testuser_${Date.now()}@example.com`;
  await signUpPage.fillForm(email);
  await signUpPage.submit();

  await expect(page.getByText("activate your account")).toBeVisible();

  const confirmationLink = await confirmationLinkFor(request, email);
  await page.goto(confirmationLink);

  await expect(page).toHaveURL(/\/profile\/edit/);
  await expect(page.getByRole("textbox", { name: "display name" })).toBeVisible();
});

test("shows an altcha error and blocks signup when auto verification fails", async ({ page }) => {
  const signUpPage = new SignUpPage(page);
  await signUpPage.goto();

  const email = `testuser_fail_${Date.now()}@example.com`;
  await signUpPage.fillForm(email);
  await signUpPage.forceCaptchaError();
  await signUpPage.submit();

  await expect(page).toHaveURL(/\/users\/sign_up/);
  await expect(page.getByRole("alert")).toHaveText(
    /verification failed\. try again later\./i,
  );
});

test("enforces password strength on sign up", async ({ page }) => {
  const signUpPage = new SignUpPage(page);
  await signUpPage.goto();

  const email = `testuser_weak_${Date.now()}@example.com`;
  await page.getByLabel("Email").fill(email);

  // Test short password
  await page.getByLabel("Password", { exact: true }).fill("short");
  await expect(page.getByText("Must be at least 15 characters")).toBeVisible();

  // Test weak password (denylist)
  await page.getByLabel("Password", { exact: true }).fill("password123456789");
  await expect(page.getByText("Very weak")).toBeVisible();

  // Test app-specific identifiers
  await page.getByLabel("Password", { exact: true }).fill("medienplattform");
  await expect(page.getByText("Very weak")).toBeVisible();

  // Test strong password
  await page.getByLabel("Password", { exact: true }).fill("correct-horse-battery-staple");
  await expect(page.getByText(/^Strong$/)).toBeVisible();

  // Attempt to submit with a weak password
  await page.getByLabel("Password", { exact: true }).fill("password123456789");
  await page.getByLabel("Password confirmation").fill("password123456789");
  await page.getByLabel(/I consent/).check();
  await signUpPage.solveCaptcha();
  await signUpPage.submit();

  // Backend should reject it
  await expect(page.getByText("is too weak")).toBeVisible();
});
