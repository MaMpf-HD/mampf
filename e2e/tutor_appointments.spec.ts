import { expect, test } from "./_support/fixtures";

test("adds a tutor by the address of their account, before any group exists",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    const person = await factory.create("confirmed_user", [], { name_in_tutorials: "Grace Hopper" });

    await page.goto(`/lectures/${lecture.id}/edit?tab=people`);
    const address = page.getByRole("textbox", { name: "Add a tutor by email address" });

    await address.fill("nobody@example.com");
    await page.getByRole("button", { name: "Add", exact: true }).click();
    await expect(page.getByText("There is no MaMpf account with this address.")).toBeVisible();

    await address.fill(person.email);
    await page.getByRole("button", { name: "Add", exact: true }).click();
    const overview = page.getByTestId("tutors-overview");
    await expect(overview.getByRole("row", { name: /Grace Hopper/ }))
      .toContainText("added by address, not on a tutorial yet");

    // the group's dialog offers her, and says where somebody missing is added
    await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Mo 10" });
    await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
    await page.getByRole("link", { name: "Edit Settings" }).first().click();
    const dialog = page.getByRole("dialog", { name: "Edit Tutorial" });
    await expect(dialog.getByText("Somebody missing?")).toBeVisible();
    await dialog.getByRole("combobox", { name: "Tutors" }).fill(person.email);
    await expect(dialog.getByRole("option", { name: new RegExp(person.email) }).last())
      .toBeVisible();
  });
