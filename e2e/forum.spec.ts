import { expect, Page, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";

/**
 * An element that is far larger than a post and shifted up and to the left,
 * inside a link. The formula class makes it a box that takes a size.
 */
const OVERSIZED_LINK = "<span class=\"katex\"><a href=\"https://example.org/elsewhere\">"
  + "<span class=\"strut\" style=\"position:relative;top:-600px;left:-600px;"
  + "width:3000px;height:3000px\"></span></a></span>";

/** A link over the whole viewport, once by inline style and once by Bootstrap classes. */
const FIXED_LINK = "<a href=\"https://example.org/elsewhere\">"
  + "<span style=\"position:fixed;top:0;left:0;width:100vw;height:100vh;display:block\">"
  + "</span><span class=\"position-fixed top-0 start-0 vw-100 vh-100 d-block\"></span></a>";

/** Creates a board for a lecture of the teacher and a topic in it, and opens the topic. */
async function openTopic(page: Page, factory: FactoryBot, teacherId: number, content: string) {
  const lecture = await factory.create("lecture_with_sparse_toc", [], { teacher_id: teacherId });
  await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
  await page.getByRole("button", { name: "Create Board" }).click();
  await expect(page.getByRole("button", { name: "Delete Board" })).toBeVisible();

  await page.goto("/forum");
  await page.getByRole("link", { name: /^\(L\)/ }).click();
  await page.getByLabel("Title").fill("Pythagoras");
  await page.getByLabel("Content").fill(content);
  await page.getByRole("button", { name: "Create New Topic" }).click();
  await page.getByRole("link", { name: "Pythagoras" }).first().click();
  await expect(page.getByRole("heading", { name: "Pythagoras" })).toBeVisible();
}

test.describe("forum posts", () => {
  test("shows a formula in a post", async ({ factory, teacher }) => {
    const page = teacher.page;
    await openTopic(page, factory, teacher.user.id, "We have $$a^2+b^2=c^2$$ as usual.");

    const formula = page.getByRole("article").locator(".katex-html");
    await expect(formula).toBeVisible();
    await expect(formula).toContainText("a2+b2=c2");
  });

  for (const [name, element] of [["an oversized", OVERSIZED_LINK], ["a fixed", FIXED_LINK]]) {
    test(`keeps the page usable next to a post with ${name} element`,
      async ({ factory, teacher }) => {
        const page = teacher.page;
        await openTopic(page, factory, teacher.user.id, `Text before.\n\n${element}`);

        await page.getByRole("link", { name: "All Messageboards" }).click();

        await expect(page).toHaveURL(/\/forum\/?$/);
      });
  }
});
