import { expect, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";
import { createReleasedLecture, subscribeToLecture } from "./user_registration/helpers";

async function enrollInTutorial(factory: FactoryBot, userId: number, mode: string) {
  const lecture = await createReleasedLecture(factory, "Linear Algebra");
  await subscribeToLecture(factory, lecture, userId);
  const tutorial = await factory.create("tutorial", [], {
    lecture_id: lecture.id,
    title: "Mo 10",
    skip_campaigns: true,
    self_materialization_mode: mode,
  });
  await factory.create("lecture_membership", [], { lecture_id: lecture.id, user_id: userId });
  await factory.create("tutorial_membership", [], {
    tutorial_id: tutorial.id, user_id: userId,
  });
  return lecture;
}

test.describe("leaving a course", () => {
  test("lists what happens and leaves after confirming", async ({ factory, student }) => {
    const lecture = await enrollInTutorial(factory, student.user.id, "add_and_remove");
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByTestId("participation-row").filter({ hasText: "Linear Algebra" })
      .getByRole("button", { name: "Leave course" }).click();
    const dialog = page.getByRole("dialog", { name: "Leave this course" });
    await expect(dialog.getByText("You leave Mo 10.")).toBeVisible();

    await dialog.getByRole("button", { name: "Leave course" }).click();

    await expect(page.getByText(/^You have left “Linear Algebra/)).toBeVisible();
    await expect(page.getByTestId("participation-row")).toHaveCount(0);
  });

  test("says why a student cannot leave alone", async ({ factory, student }) => {
    const lecture = await enrollInTutorial(factory, student.user.id, "add_only");
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("button", { name: "Leave course" }).click();
    const dialog = page.getByRole("dialog", { name: "Leave this course" });

    await expect(dialog.getByText("You cannot leave “Mo 10” yourself.")).toBeVisible();
    await expect(dialog.getByText("Please contact the lecturer.")).toBeVisible();
    await expect(dialog.getByRole("button", { name: "Leave course" })).toHaveCount(0);
    await dialog.getByRole("button", { name: "Close" }).last().click();
    await expect(dialog).toBeHidden();
  });
});
