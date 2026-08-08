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

test("clears stale validation errors after correcting a rejected password", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "password-reset" }) as User;
  const newPassword = "super-secure-horse-battery-staple";

  await page.goto("/users/password/new?locale=en");
  await page.getByLabel("Email").fill(user.email);
  await page.getByRole("button", { name: "Reset password" }).click();

  const resetLink = await resetPasswordLinkFor(request, user.email);
  await page.goto(resetLink);

  await page.getByLabel("New password", { exact: true }).fill("short-password");
  await page.getByLabel("Confirm new password", { exact: true }).fill("short-password");
  await expect(page.getByText("Weak - Must be at least 15 characters", { exact: true }))
    .toBeVisible();
  await page.getByRole("button", { name: "Change password" }).click();

  await expect(page).toHaveURL(/\/users\/password/);
  await expect(page.locator("#user_password")).toHaveClass(/is-invalid/);
  await expect(page.locator("#user_password + .invalid-feedback")).toContainText("is too short");
  await expect(page.locator("#user_password_confirmation")).not.toHaveClass(/is-invalid/);
  await expect(page.locator("#user_password_confirmation + .invalid-feedback")).toHaveCount(0);

  await page.getByLabel("New password", { exact: true }).fill(newPassword);
  await page.getByLabel("Confirm new password", { exact: true }).fill(newPassword);

  await expect(page.locator("#user_password")).not.toHaveClass(/is-invalid/);
  await expect(page.locator("#user_password_confirmation")).not.toHaveClass(/is-invalid/);
  await expect(page.locator("#user_password + .invalid-feedback")).toHaveCount(0);
  await expect(page.locator("#user_password_confirmation + .invalid-feedback")).toHaveCount(0);
  const feedback = page.locator('[data-password-strength-target="feedback"]');
  await expect(feedback).toHaveClass(/text-success/);
  await expect(feedback).toHaveText(/Good|Strong/);
  await expect(feedback).not.toContainText("Must be at least 15 characters");
});

test("keeps helpdesk popovers working after a rejected account password change", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "password-change" }) as User;

  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  await expect(page).toHaveURL(/\/main\/start/);

  await page.goto("/users/edit?locale=en");

  const currentPasswordHelpdesk = page.locator('[data-bs-toggle="popover"]').first();
  await currentPasswordHelpdesk.click();
  await expect(page.locator(".popover")).toContainText("current password");

  await page.locator("body").click({ position: { x: 0, y: 0 } });

  await page.getByLabel("Current password").fill("wrong-password");
  await page.getByLabel("New password", { exact: true }).fill("super-secure-horse-battery-staple");
  await page.getByLabel("Confirm new password", { exact: true }).fill("super-secure-horse-battery-staple");
  await page.getByRole("button", { name: "Update" }).click();

  await expect(page).toHaveURL(/\/users/);

  await currentPasswordHelpdesk.click();
  await expect(page.locator(".popover")).toContainText("current password");
});

test("clears stale current password errors after correcting an account password change", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "password-change" }) as User;
  const newPassword = "super-secure-horse-battery-staple";

  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  await expect(page).toHaveURL(/\/main\/start/);

  await page.goto("/users/edit?locale=en");
  await page.getByLabel("Current password").fill("wrong-password");
  await page.getByLabel("New password", { exact: true }).fill(newPassword);
  await page.getByLabel("Confirm new password", { exact: true }).fill(newPassword);
  await page.getByRole("button", { name: "Update" }).click();

  await expect(page).toHaveURL(/\/users/);
  await expect(page.locator("#user_current_password")).toHaveClass(/is-invalid/);
  await expect(page.locator("#user_current_password + .invalid-feedback")).toHaveCount(1);

  await page.getByLabel("Current password").fill(user.password);

  await expect(page.locator("#user_current_password")).not.toHaveClass(/is-invalid/);
  await expect(page.locator("#user_current_password + .invalid-feedback")).toHaveCount(0);
});
