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
