import { expect, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { LoginPage } from "./page-objects/login_page";

test("shows a warning on the last failed login attempt before lockout", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "last-attempt-warning" }) as User;
  const loginPage = new LoginPage(page);
  const alert = page.getByRole("alert").first();

  await loginPage.goto();

  for (let attempt = 0; attempt < 3; attempt += 1) {
    await loginPage.login(user.email, "wrong-password");
    await expect(alert).toBeVisible();
    await expect(alert).toContainText(
      /Invalid email or password\.|E-Mail-Adresse oder Passwort ungültig\./,
    );
  }

  await loginPage.login(user.email, "wrong-password");

  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(
    /You have one more attempt before your account is locked\.|Du hast noch einen Versuch, bevor Dein Account gesperrt wird\./,
  );
});

test("shows unlock guidance for locked accounts", async ({ page, request }) => {
  const user = await callBackend(request, "user_creator_playwright",
    { role: "locked-account" }) as User;
  const loginPage = new LoginPage(page);
  const alert = page.getByRole("alert").first();

  await loginPage.goto();

  for (let attempt = 0; attempt < 4; attempt += 1) {
    await loginPage.login(user.email, "wrong-password");
    await expect(alert).toBeVisible();
  }

  await loginPage.login(user.email, "wrong-password");

  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(
    /Your account is locked\.|Dein Account ist gesperrt\./,
  );
  await expect(alert).toContainText(
    /We sent you an unlock email\.|Wir haben Dir eine Entsperr-E-Mail geschickt\./,
  );
  await expect(alert).toContainText(
    /(?:about )?30 minutes|30 Minuten/,
  );
  await expect(alert).toContainText(
    /after it was locked\.|nach der Sperrung/,
  );
});
