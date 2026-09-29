import { expect, test } from "./_support/fixtures";

test("adds an editor by the address of their account, and removes them in the select",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    const person = await factory.create("confirmed_user", [], { name: "Ada Lovelace" });

    await page.goto(`/lectures/${lecture.id}/edit?tab=people`);
    const address = page.getByRole("textbox", { name: "Add an editor by email address" });

    await address.fill("nobody@example.com");
    await page.getByRole("button", { name: "Add editor" }).click();
    await expect(page.getByText("There is no MaMpf account with this address.")).toBeVisible();

    await address.fill(person.email);
    await page.getByRole("button", { name: "Add editor" }).click();
    await expect(page.getByText("Ada Lovelace is now an editor")).toBeVisible();
    const editors = page.getByTestId("editor-select");
    await expect(editors).toContainText("Ada Lovelace");

    // the select is where editors go again, whichever way they came
    await editors.getByRole("link", { name: "×" }).click();
    const saved = page.waitForResponse(response => response.request().method() !== "GET"
      && response.url().includes(`/lectures/${lecture.id}`));
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await saved;
    await page.reload();
    await expect(page.getByTestId("editor-select")).not.toContainText("Ada Lovelace");
  });
