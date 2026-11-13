import { expect, test } from "./_support/fixtures";
import { MediumCommentsPage } from "./page-objects/comments_page";

test("shows another image on a vote button while the pointer is over it",
  async ({ factory, student, student2 }) => {
    const medium = await factory.create("lesson_medium", ["with_video", "released"]);
    const authorComments = new MediumCommentsPage(student.page, medium.id);
    await authorComments.goto();
    await authorComments.postComment("Is the bound sharp?");

    const page = student2.page;
    await new MediumCommentsPage(page, medium.id).goto();
    // An image button without an alt text goes by the name "Submit".
    const voteButton = page.getByRole("button", { name: "Submit" });
    await expect(voteButton).toHaveAttribute("src", /upvote-/);

    await voteButton.hover();
    await expect(voteButton).toHaveAttribute("src", /upvote_hover-/);

    await page.mouse.move(0, 0);
    await expect(voteButton).toHaveAttribute("src", /upvote-/);
  });
