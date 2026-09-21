import { expect, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { LoginPage } from "./page-objects/login_page";

test("deletes an account that has redeemed a voucher", async ({ page, request, factory }) => {
  const teacher = await callBackend(request, "user_creator",
    { role: "teacher" }) as User;
  const user = await callBackend(request, "user_creator",
    { role: "generic" }) as User;
  const lecture = await factory.create("lecture", [], { teacher_id: teacher.id });
  const voucher = await factory.create("voucher", [],
    { lecture_id: lecture.id, role: "tutor" });

  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  // the fixture user has never signed in, so this is their first sign-in
  await expect(page).toHaveURL(/\/profile\/edit/);

  await page.getByRole("textbox", { name: "Voucher code" }).fill(voucher.secure_hash as string);
  await page.getByRole("button", { name: "Verify Voucher" }).click();
  await page.getByRole("link", { name: "Redeem Voucher" }).click();
  await expect(page.getByText("Your tutor status has been updated.")).toBeVisible();

  await page.goto("/profile/edit?locale=en");
  await page.getByRole("link", { name: "Delete Account" }).click();
  const confirmation = page.getByRole("dialog", { name: "Delete Account" });
  await confirmation.getByRole("textbox", { name: "Password" }).fill(user.password);
  await confirmation.getByRole("button", { name: "Delete Account" }).click();

  await expect(page).toHaveURL(/\/$/);

  await page.goto("/profile/edit?locale=en");

  await expect(page).toHaveURL(/\/users\/sign_in/);
  await expect(page.getByLabel("Email")).toBeVisible();
});
