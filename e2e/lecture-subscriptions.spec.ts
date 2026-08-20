import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("student", () => {
  test("can subscribe", async ({ factory, student: { page } }) => {
    for (let i = 0; i < 6; i++) {
      await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
    }

    await page.goto("/main/start");
    await page.getByRole("link", { name: "Search", exact: true }).click();
    await page.getByRole("button", { name: "Lecture Search" }).click();
    await page.getByRole("button", { name: "Search", exact: true }).click();

    const lectureCard = page.locator(".lectureCard").first();
    const lectureId = await lectureCard.getAttribute("data-id");
    await lectureCard.getByTitle("Subscribe").click();
    await expect(lectureCard.getByTitle("Unsubscribe")).toBeVisible();

    await new LecturePage(page, Number(lectureId)).goto();
    await expect(page).toHaveURL(/\/outline$/);
    await expect(page.getByText("Lecture Contents")).toBeVisible();
    await expect(page.getByText("There is no content information.")).not.toBeVisible();
  });

  test("cannot access an unpublished lecture page", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture");

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByText("You are not authorized to")).toBeVisible();
  });
});
