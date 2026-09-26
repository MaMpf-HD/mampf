import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("student", () => {
  test("can access an unprotected lecture without bookmarking it",
    async ({ factory, student: { page, user } }) => {
      const lecture = await factory.create(
        "lecture", ["released_for_all", "with_sparse_toc"],
      );

      await new LecturePage(page, lecture.id).goto();
      await expect(page).toHaveURL(/\/outline$/);
      await expect(page.getByText("Lecture Contents")).toBeVisible();
      expect(await lecture.__call("bookmarked_by?", user)).toBe(false);
    });

  test("can unlock a password-protected lecture", async ({ factory, student: { page } }) => {
    const lecture = await factory.create(
      "lecture", ["released_for_all", "with_sparse_toc"], { passphrase: "secret" },
    );

    const lecturePage = new LecturePage(page, lecture.id);
    await lecturePage.goto();
    await expect(page).toHaveURL(/\/home$/);
    await expect(page.getByText("This lecture is protected by a pass phrase")).toBeVisible();

    await lecturePage.unlock("secret");
    await lecturePage.goto();
    await expect(page).toHaveURL(/\/outline$/);
    await expect(page.getByText("Lecture Contents")).toBeVisible();
  });

  test("cannot access an unpublished lecture page", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture");

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByText("You are not authorized to")).toBeVisible();
  });
});
