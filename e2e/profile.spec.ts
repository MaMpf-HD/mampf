import { expect, test } from "./_support/fixtures";

// https://github.com/microsoft/playwright/issues/27046#issuecomment-3493081155

test("can see user information", async ({ student }) => {
  await student.page.goto("/profile/edit");
  await expect(student.page.getByText("display name")).toBeVisible();
  await expect(student.page.getByRole("textbox", { name: "Display name" })).toHaveValue(student.user.name);
});

test("can see user information (with direct destructuring)", async ({ student: { page, user } }) => {
  await page.goto("/profile/edit");
  await expect(page.getByText("display name")).toBeVisible();
  await expect(page.getByRole("textbox", { name: "Display name" })).toHaveValue(user.name);
});

test("only admins have admin icon in menu bar", async ({ student: { page: studentPage }, admin: { page: adminPage } }) => {
  await studentPage.goto("/main/start");
  await adminPage.goto("/main/start");
  await expect(studentPage.getByTitle("administration")).toHaveCount(0);
  await expect(adminPage.getByTitle("administration")).toBeVisible();
});
