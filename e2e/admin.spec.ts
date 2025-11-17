import { expect, test } from "./_support/fixtures";

test("only admins have admin icon in menu bar",
  async ({ student: { page: studentPage }, admin: { page: adminPage } }) => {
    await studentPage.goto("/main/start");
    await adminPage.goto("/main/start");
    await expect(studentPage.getByTitle("administration")).toHaveCount(0);
    await expect(adminPage.getByTitle("administration")).toBeVisible();
  });
