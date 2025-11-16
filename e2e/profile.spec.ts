/**
 * This is just a dummy test file to see how we can use Playwright.
 *
 * See also one bug due to which the browser closes immediately after launching:
 * https://github.com/microsoft/playwright/issues/27046#issuecomment-3493081155
 */

import { expect, test } from "./_support/fixtures";
import { MediumCommentsPage } from "./page-objects/comments_page";
import { ProfilePage } from "./page-objects/profile_page";

test.describe("Account settings", () => {
  test("can change user name & reflects it in user comments",
    async ({ factory, student: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
      const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
      const medium = await factory.create("lesson_medium", ["released", "with_lesson_by_id"], { lesson_id: lesson.id });

      const profilePage = new ProfilePage(page);
      const commentsPage = new MediumCommentsPage(page, medium.id);

      await profilePage.goto();
      await expect(page.getByRole("textbox", { name: "display name" })).toHaveValue(user.name);
      await commentsPage.goto();
      const COMMENT = "Super comment";
      await commentsPage.postComment(COMMENT);
      await expect(page.getByText(user.name)).toBeVisible();
      await expect(page.getByText(COMMENT)).toBeVisible();

      const newName = "Jean-Jacques Rousseau";
      await profilePage.goto();
      await page.getByRole("textbox", { name: "display name" }).clear();
      await page.getByRole("textbox", { name: "display name" }).fill(newName);
      await page.getByRole("button", { name: "save your changes" }).click();
      await commentsPage.goto();
      await expect(page.getByText(newName)).toBeVisible();
      await expect(page.getByText(COMMENT)).toBeVisible();
    });

});

test.describe("Module settings", () => {

test("only admins have admin icon in menu bar", async ({ student: { page: studentPage }, admin: { page: adminPage } }) => {
  await studentPage.goto("/main/start");
  await adminPage.goto("/main/start");
  await expect(studentPage.getByTitle("administration")).toHaveCount(0);
  await expect(adminPage.getByTitle("administration")).toBeVisible();
});
