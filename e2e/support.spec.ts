import { expect, test } from "./_support/fixtures";

test.describe("the support", () => {
  test("is made by an admin, finds a student by number and corrects the name",
    async ({ admin, student, factory }) => {
      const other = await factory.create("confirmed_user", [], {
        first_name: "Emmy", last_name: "Noether", matriculation_number: "1234567",
      });

      await admin.page.goto(`/users/${student.user.id}/edit`);
      await admin.page.getByRole("checkbox", { name: "Support" }).check();
      await admin.page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(admin.page.getByRole("checkbox", { name: "Support" })).toBeChecked();

      const page = student.page;
      await page.goto("/");
      await page.getByRole("link", { name: "Support" }).click();
      await expect(page.getByRole("heading", { name: "Support: personal data" })).toBeVisible();

      await page.getByRole("search").getByLabel("Full text").fill("1234567");
      await page.getByRole("button", { name: "Search" }).click();
      const results = page.getByRole("table");
      await expect(results.getByRole("row", { name: /Noether, Emmy/ })).toBeVisible();

      await results.getByRole("link", { name: `Correct the personal data of ${other.email}` })
        .click();
      await page.getByLabel("Last name").fill("Noether-Lasker");
      await page.getByRole("button", { name: "Save" }).click();

      await expect(page.getByText("The personal data has been corrected.")).toBeVisible();
      await expect(page.getByLabel("Last name")).toHaveValue("Noether-Lasker");
      const history = page.getByRole("table");
      await expect(history.getByRole("row", { name: /Last name Noether Noether-Lasker/ }))
        .toBeVisible();
    });
});
