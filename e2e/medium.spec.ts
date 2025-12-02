import { expect, test } from "./_support/fixtures";
import { selectDate } from "./page-objects/datepicker";

test("can schedule medium publication with datetimepicker",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"],
      { teacher_id: user.id, content_mode: "manuscript" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id });

    await page.goto(`/media/${medium.id}/edit`);
    await page.getByRole("button", { name: "publish" }).click();
    await page.getByTestId("release-date-datetimepicker").click();
    const dayName = await selectDate(page);
    await page.getByRole("checkbox", { name: "I hereby confirm that" }).click();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByText("scheduled for release on")).toBeVisible();
    await expect(page.getByText(dayName)).toBeVisible();
  });
