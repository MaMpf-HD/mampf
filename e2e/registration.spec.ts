import { expect, test } from "./_support/fixtures";
import { confirmationLinkFor } from "./_support/mail";
import { LoginPage } from "./page-objects/login_page";
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

  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(page.getByRole("alert")).toContainText(
    "Your email address has been confirmed.",
  );

  await new LoginPage(page).login(email, "password");

  await expect(page).toHaveURL(/\/profile\/edit/);
  await expect(page.getByRole("alert")).toContainText(
    "Please take some time to edit your profile settings.",
  );
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
