import { expect, test } from "./_support/fixtures";

/** The switcher lists a user by the part of the email address before the @. */
function switcherName(email: string) {
  return email.split("@")[0];
}

test("finds a user in the user switcher by name", async ({ student, teacher }) => {
  const page = student.page;
  await page.goto("/");
  await page.getByRole("button", { name: "Switch user (dev only)" }).click();

  const search = page.getByPlaceholder("Search...");
  await expect(search).toBeFocused();

  await search.fill(switcherName(teacher.user.email).toUpperCase());
  await expect(page.getByRole("button", {
    name: switcherName(teacher.user.email), exact: true,
  })).toBeVisible();
  await expect(page.getByRole("button", {
    name: switcherName(student.user.email), exact: true,
  })).toBeHidden();
});
