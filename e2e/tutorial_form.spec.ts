import { expect, test } from "./_support/fixtures";

test("asks before a member of the group becomes its tutor",
  async ({ factory, student, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Mo 10",
    });
    await tutorial.__call("add_user_to_roster!", student.user);
    // tutoring another group of the lecture makes the student a candidate
    await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, title: "Tu 14", tutor_id: student.user.id,
    });

    await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
    await page.getByRole("link", { name: "Edit Settings" }).first().click();

    const dialog = page.getByRole("dialog", { name: "Edit Tutorial" });
    await dialog.getByRole("combobox", { name: "Tutors" }).fill(student.user.email);
    // the native <option> and TomSelect's copy share the name; the copy is the one on screen
    await dialog.getByRole("option", { name: new RegExp(student.user.email) }).last().click();

    // dismissed first: the form stays open
    page.once("dialog", async (confirm) => {
      expect(confirm.message()).toContain("would be marking their own sheets");
      await confirm.dismiss();
    });
    await dialog.getByRole("button", { name: "Save" }).click();
    await expect(dialog).toBeVisible();

    page.once("dialog", confirm => confirm.accept());
    await dialog.getByRole("button", { name: "Save" }).click();
    await expect(dialog).toBeHidden();
    const tile = page.getByTestId("group-row").filter({ hasText: "Mo 10" });
    await expect(tile).toContainText("student (public, 0)");

    // accepted once is accepted: an edit that leaves the tutors alone is not asked again
    let askedAgain = false;
    page.once("dialog", async (confirm) => {
      askedAgain = true;
      await confirm.accept();
    });
    await page.getByRole("link", { name: "Edit Settings" }).first().click();
    await dialog.getByRole("textbox", { name: "Title" }).fill("Mo 10-12");
    await dialog.getByRole("button", { name: "Save" }).click();
    await expect(dialog).toBeHidden();
    await expect(page.getByTestId("group-row").filter({ hasText: "Mo 10-12" })).toBeVisible();
    expect(askedAgain).toBe(false);
  });
