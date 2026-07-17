import { expect, test } from "./_support/fixtures";
import { dateLabel, selectDate } from "./page-objects/datepicker";
import { LecturePage } from "./page-objects/lecture_page";

test("can schedule medium publication with datetimepicker",
  async ({ factory, teacher: { page, user } }) => {
    const releaseDate = new Date();
    releaseDate.setDate(releaseDate.getDate() + 2);
    const releaseDateLabel = dateLabel(releaseDate);

    const lecture = await factory.create("lecture", ["released_for_all"],
      { teacher_id: user.id, content_mode: "manuscript" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "LessonMaterial" });

    await new LecturePage(page, lecture.id).gotoEdit();
    await page.getByRole("link", { name: medium.description }).click();
    await expect(page).toHaveURL(`/media/${medium.id}/edit`);
    await page.getByRole("button", { name: "publish" }).click();

    await page.getByRole("radio", { name: "at the following time" }).click();
    await expect(page.getByRole("gridcell", { name: releaseDateLabel })).toBeVisible();
    const dayName = await selectDate(page, releaseDate);

    await page.getByRole("checkbox", { name: "I hereby confirm that" }).click();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByText("scheduled for release on")).toBeVisible();
    await expect(page.getByText(dayName)).toBeVisible();
  });
