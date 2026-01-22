import { expect, test } from "./_support/fixtures";
import { selectDate } from "./page-objects/datepicker";
import { LecturePage } from "./page-objects/lecture_page";

test("can create assignment when publishing Exercise medium",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"],
      { teacher_id: user.id, content_mode: "manuscript" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Exercise" });

    await new LecturePage(page, lecture.id).gotoEdit();
    await page.getByRole("link", { name: medium.description }).click();
    await page.getByRole("button", { name: "publish" }).click();

    await page.getByLabel("Immediately").check();
    await page.getByLabel("Create assignment for this").check();
    await expect(page.locator("#medium_assignment_row")).toBeVisible();

    await page.locator("#medium_assignment_title").fill("Test Assignment");
    await page.locator("#medium_assignment_deadline").click();
    await selectDate(page);

    const today = new Date();
    const nextSemester = new Date(today);
    nextSemester.setMonth(today.getMonth() + 6);
    const deletionDate = `${nextSemester.toLocaleString("en-US", { month: "long" })} ${nextSemester.getFullYear()}`;
    await page.selectOption("#medium_assignment_deletion_date", { label: deletionDate });

    await page.getByRole("checkbox", { name: "I hereby confirm that" }).check();
    await page.getByRole("button", { name: "Save" }).click();

    await page.waitForURL(/\/media\/\d+\/edit/);
    await expect(page.getByText("published")).toBeVisible();
    await page.goto(`/lectures/${lecture.id}/edit`);
    await page.getByRole("tab", { name: "assignments" }).click();
    await expect(page.getByRole("link", { name: "Test Assignment" })).toBeVisible();
  });

test("assignment fields are hidden when checkbox is not checked",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"],
      { teacher_id: user.id, content_mode: "manuscript" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Exercise" });

    await new LecturePage(page, lecture.id).gotoEdit();
    await page.getByRole("link", { name: medium.description }).click();
    await page.getByRole("button", { name: "publish" }).click();

    await expect(page.locator("#medium_assignment_row")).toHaveClass(/no_display/);
    await page.getByLabel("Create assignment for this").check();
    await expect(page.locator("#medium_assignment_row")).not.toHaveClass(/no_display/);
    await page.getByLabel("Create assignment for this").uncheck();
    await expect(page.locator("#medium_assignment_row")).toHaveClass(/no_display/);
  });
