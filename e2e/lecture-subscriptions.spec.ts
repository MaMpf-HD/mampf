import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("student", () => {
  test("can subscribe", async ({ factory, student: { page } }) => {
    for (let i = 0; i < 6; i++) {
      await factory.create("lecture", ["released_for_all"]);
    }

    await page.goto("/main/start");
    await page.getByRole("button", { name: "Lecture Search" }).click();
    await page.getByRole("button", { name: "Search", exact: true }).click();
    await page.getByTitle("Subscribe").nth(0).click();
    await expect(page.getByTitle("Unsubscribe").nth(0)).toBeVisible();
  });

  test("can not subscribe on page to unpublished", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture");

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByText("You are not authorized to")).toBeVisible();
  });
});
