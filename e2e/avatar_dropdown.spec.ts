import { expect, test } from "./_support/fixtures";

test("avatar menu links to profile, annotations and watchlists",
  async ({ student: { page } }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Account menu" }).click();

    const profile = page.getByRole("link", { name: "Profile", exact: true });
    await expect(profile).toBeVisible();
    await expect(page.getByRole("link", { name: "My Annotations" })).toBeVisible();
    await expect(page.getByRole("link", { name: "My Watchlists" })).toBeVisible();

    await profile.click();
    await expect(page).toHaveURL(/\/profile\/edit/);

    await page.getByRole("button", { name: "Account menu" }).click();
    await expect(page.getByRole("link", { name: "Profile", exact: true }))
      .toHaveAttribute("aria-current", "page");
  });

test("avatar menu shows the user switcher and logs out",
  async ({ student: { page } }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Account menu" }).click();

    await expect(page.getByRole("heading", { name: "Switch user (dev only)" })).toBeVisible();
    await expect(page.getByPlaceholder("Search...")).toBeFocused();
    await expect(page.getByRole("link", { name: "Logout" })).toBeVisible();

    await page.getByRole("link", { name: "Logout" }).click();
    await expect(page.getByRole("alert")).toContainText("Signed out successfully.");
  });

test("avatar menu shows the role links only to those having the role",
  async ({ admin, student }) => {
    await student.page.goto("/");
    await student.page.getByRole("button", { name: "Account menu" }).click();
    await expect(student.page.getByRole("link", { name: "Profile", exact: true }))
      .toBeVisible();
    for (const name of ["Support", "Dean's office", "Administration"]) {
      await expect(student.page.getByRole("link", { name })).toHaveCount(0);
    }

    await admin.page.goto("/");
    await admin.page.getByRole("button", { name: "Account menu" }).click();
    await expect(admin.page.getByRole("link", { name: "Support" })).toBeVisible();
    await expect(admin.page.getByRole("link", { name: "Dean's office" })).toBeVisible();
    await admin.page.getByRole("link", { name: "Administration" }).click();
    await expect(admin.page).toHaveURL(/\/administration/);
  });
