import { expect, test } from "./_support/fixtures";

// A flexible group usually needs no tutor; if it has one, e.g. for extra
// lessons, they see who is in it and can write to them.
test("a flexible group's tutor sees who is in it", async ({ factory, teacher, tutor }) => {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacher.user.id,
  });
  const cohort = await factory.create("cohort", [], {
    context_type: "Lecture", context_id: lecture.id, title: "Extra lessons",
  });
  const student = await factory.create("confirmed_user", [], { name_in_tutorials: "Ada Lovelace" });
  await factory.create("cohort_membership", [], { cohort_id: cohort.id, user_id: student.id });
  // eligible like any tutor of the lecture
  await factory.create("tutor_appointment", [], { lecture_id: lecture.id, user_id: tutor.user.id });

  const { page } = teacher;
  await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
  const row = page.getByRole("listitem")
    .filter({ has: page.getByRole("heading", { name: "Extra lessons", exact: true }) });
  await row.getByRole("link", { name: "Edit Settings" }).click();
  const dialog = page.getByRole("dialog", { name: "Edit Flexible Group" });
  await dialog.getByRole("combobox", { name: "Tutors" }).fill(tutor.user.email);
  await dialog.getByRole("option", { name: new RegExp(tutor.user.email) }).last().click();
  await page.keyboard.press("Escape");
  await dialog.getByRole("button", { name: "Save" }).click();
  await expect(dialog).toBeHidden();

  await tutor.page.goto(`/lectures/${lecture.id}`);
  await tutor.page.getByRole("link", { name: "Flexible Groups" }).click();
  const participants = tutor.page.getByTestId("tutorial-participants");
  await expect(participants).toContainText("Ada Lovelace");
  await expect(tutor.page.getByRole("button", { name: "Email the group" })).toBeVisible();
});
