import { expect, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { LoginPage } from "./page-objects/login_page";

test("keeps the failure generic while an account runs into the lock",
  async ({ page, request }) => {
    const user = await callBackend(request, "user_creator_playwright",
      { role: "locked-account" }) as User;
    const loginPage = new LoginPage(page);
    const alert = page.getByRole("alert").first();

    await loginPage.goto();

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await loginPage.login(user.email, "wrong-password");
      await expect(alert).toBeVisible();
      await expect(alert).toContainText("Invalid email or password.");
    }

    await loginPage.login(user.email, "wrong-password");

    await expect(alert).toBeVisible();
    await expect(alert).toContainText("Invalid email or password.");
    await expect(alert).not.toContainText("locked");
  });

test("shows unlock guidance once the locked account's password is right",
  async ({ page, request }) => {
    const user = await callBackend(request, "user_creator_playwright",
      { role: "locked-account" }) as User;
    const loginPage = new LoginPage(page);
    const alert = page.getByRole("alert").first();

    await loginPage.goto();

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await loginPage.login(user.email, "wrong-password");
      await expect(alert).toBeVisible();
    }

    await loginPage.login(user.email, user.password);

    await expect(page).toHaveURL(/\/users\/sign_in/);
    await expect(alert).toBeVisible();
    await expect(alert).toContainText("Your account is locked.");
    await expect(alert).toContainText("We sent you an unlock email.");
    await expect(alert).toContainText(/(?:about )?30 minutes/);
    await expect(alert).toContainText("after it was locked.");
  });
