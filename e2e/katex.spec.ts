import { expect, test } from "./_support/fixtures";
import { MediumCommentsPage } from "./page-objects/comments_page";

test("renders math formulas in medium comments", async ({ factory, student: { page } }) => {
  const medium = await factory.create("lesson_medium", ["with_video", "released"]);

  const commentsPage = new MediumCommentsPage(page, medium.id);
  await commentsPage.goto();

  const commentWithMath = "Test inline $x^2 + y^2 = z^2$ and display $$\\int_0^1 f(x) dx$$";
  await commentsPage.postComment(commentWithMath);

  await page.reload();
  await expect(page.locator(".katex")).toHaveCount(2);
  await expect(page.locator(".katex-display")).toHaveCount(1);
});
