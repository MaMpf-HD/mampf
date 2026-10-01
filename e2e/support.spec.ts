import { expect, test } from "./_support/fixtures";

test.describe("the support", () => {
  test("is made by an admin, finds a student by number, corrects the data and unlocks",
    async ({ admin, student, factory }) => {
      const other = await factory.create("confirmed_user", [], {
        first_name: "Emmy", last_name: "Noether", matriculation_number: "1234567",
        locked_at: new Date().toISOString(), failed_attempts: 5,
      });

      await admin.page.goto(`/support/users/${student.user.id}/edit`);
      await admin.page.getByRole("checkbox", { name: "Support" }).check();
      await admin.page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(admin.page.getByText("The changes have been saved.")).toBeVisible();
      await expect(admin.page.getByRole("checkbox", { name: "Support" })).toBeChecked();

      const page = student.page;
      await page.goto("/");
      await page.getByRole("link", { name: "Support" }).click();
      await expect(page.getByRole("heading", { name: "Support: accounts" })).toBeVisible();

      await page.getByRole("search").getByLabel("Full text").fill("1234567");
      await page.getByRole("button", { name: "Search" }).click();
      const results = page.getByRole("table");
      await expect(results.getByRole("row", { name: /Noether, Emmy/ })).toBeVisible();

      await results.getByRole("link", { name: `Open the account of ${other.email}` }).click();
      const status = page.getByTestId("support-account-status");
      await expect(status).toContainText("5 failed sign-ins");

      await page.getByRole("button", { name: "Unlock" }).click();
      await expect(page.getByText("The account is unlocked")).toBeVisible();
      await expect(status).not.toContainText("failed sign-in");
      await expect(page.getByRole("button", { name: "Unlock" })).toHaveCount(0);

      await page.getByLabel("Last name").fill("Noether-Lasker");
      await page.getByLabel("Name in tutorials").fill("Emmy");
      await page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(page.getByText("The changes have been saved.")).toBeVisible();
      await expect(page.getByLabel("Last name")).toHaveValue("Noether-Lasker");

      // the search is still there on the way back
      await page.getByRole("link", { name: "Back to the search" }).click();
      await expect(page.getByRole("search").getByLabel("Full text")).toHaveValue("1234567");
      await expect(results.getByRole("row", { name: /Noether-Lasker, Emmy/ })).toBeVisible();
    });

  test("deletes an account when an admin is asked to", async ({ admin: { page }, factory }) => {
    const person = await factory.create("confirmed_user", [], {
      first_name: "Sofja", last_name: "Kowalewskaja",
    });

    await page.goto(`/support/users/${person.id}/edit`);
    page.once("dialog", confirmation => confirmation.accept());
    await page.getByRole("button", { name: "Delete the account" }).click();

    await expect(page.getByText(`The account of ${person.email} has been deleted.`))
      .toBeVisible();
  });
});
