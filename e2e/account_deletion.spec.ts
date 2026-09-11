import { expect, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { LoginPage } from "./page-objects/login_page";

test("deletes an account that has redeemed a voucher", async ({ page, request, factory }) => {
  const teacher = await callBackend(request, "user_creator_playwright",
    { role: "teacher" }) as User;
  const user = await callBackend(request, "user_creator_playwright",
    { role: "generic" }) as User;
  const lecture = await factory.create("lecture", [], { teacher_id: teacher.id });
  const voucher = await factory.create("voucher", [],
    { lecture_id: lecture.id, role: "tutor" });

  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  // the fixture user has never signed in, so this is their first sign-in
  await expect(page).toHaveURL(/\/profile\/edit/);

  await page.locator('[data-cy="secure-hash-input"]').fill(voucher.secure_hash as string);
  await page.locator('[data-cy="verify-voucher-submit"]').click();
  await page.locator('[data-cy="redeem-voucher-btn"]').click();
  await expect(page.locator('[data-cy="flash-notice"]')).toBeVisible();

  await page.goto("/profile/edit?locale=en");
  await page.locator('[data-cy="delete-account-btn"]').click();
  await page.locator('[data-cy="delete-account-pwd-field"]').fill(user.password);
  await page.locator('[data-cy="delete-account-confirm-btn"]').click();

  await expect(page).toHaveURL(/\/$/);

  await page.goto("/profile/edit?locale=en");

  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(page.getByLabel("Email")).toBeVisible();
});
