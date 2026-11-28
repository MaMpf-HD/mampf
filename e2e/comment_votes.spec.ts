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

test("shows the usual image again on a page the browser comes back to",
  async ({ factory, student, student2 }) => {
    const medium = await factory.create("lesson_medium", ["with_video", "released"]);
    const authorComments = new MediumCommentsPage(student.page, medium.id);
    await authorComments.goto();
    await authorComments.postComment("Is the bound sharp?");

    const page = student2.page;
    const comments = new MediumCommentsPage(page, medium.id);
    await comments.goto();
    const voteButton = page.getByRole("button", { name: "Submit" });
    await voteButton.hover();
    await expect(voteButton).toHaveAttribute("src", /upvote_hover-/);

    // Leaves by keyboard, so the pointer is still over the button when the
    // page is put away.
    await page.getByRole("link", { name: "Back to Medium" }).focus();
    await page.keyboard.press("Enter");
    await expect(page).not.toHaveURL(/show_comments/);
    await page.mouse.move(0, 0);

    await page.goBack();
    await expect(page).toHaveURL(/show_comments/);
    await expect(voteButton).toHaveAttribute("src", /upvote-/);
  });
