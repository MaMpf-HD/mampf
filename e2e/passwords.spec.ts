import { expect, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { resetPasswordLinkFor } from "./_support/mail";
import { LoginPage } from "./page-objects/login_page";

test("can reset the password via the mailed reset link", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "password-reset" }) as User;
  const newPassword = "super-secure-horse-battery-staple";

  await page.goto("/users/password/new?locale=en");
  await page.getByLabel("Email").fill(user.email);
  await page.getByRole("button", { name: "Reset password" }).click();

  await expect(page).toHaveURL(/\/users\/sign_in/);

  const resetLink = await resetPasswordLinkFor(request, user.email);
  await page.goto(resetLink);

  await page.getByLabel("New password", { exact: true }).fill(newPassword);
  await page.getByLabel("Confirm new password", { exact: true }).fill(newPassword);
  await page.getByRole("button", { name: "Change password" }).click();

  await expect(page).toHaveURL(/\/main\/start/);

  await page.getByTitle("Logout").click();
  await expect(page).not.toHaveURL(/\/main\/start/);

  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(page.getByRole("alert")).toBeVisible();

  await loginPage.goto();
  await loginPage.login(user.email, newPassword);
  await expect(page).toHaveURL(/\/main\/start/);
});
