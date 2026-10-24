import { expect, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";
import { subscribeToLecture } from "./user_registration/helpers";

async function enrollInTutorial(factory: FactoryBot, userId: number, mode: string) {
  const course = await factory.create("course", [], {
    title: "Linear Algebra", short_title: "LA 1",
  });
  const lecture = await factory.create("lecture", ["released_for_all"], {
    course_id: course.id,
  });
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
    // the tutorial's self-service mode is about switching groups, not leaving
    const lecture = await enrollInTutorial(factory, student.user.id, "disabled");
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByTestId("participation-row").filter({ hasText: "Linear Algebra" })
      .getByRole("button", { name: "Leave course" }).click();
    const dialog = page.getByRole("dialog", { name: "Leave this course" });
    await expect(dialog.getByText("You leave Mo 10.")).toBeVisible();

    const leaveButton = dialog.getByRole("button", { name: "Leave course" });
    await expect(leaveButton).toBeDisabled();
    const code = dialog.getByLabel("Type “LA1” to confirm:");
    await code.fill("LA2");
    await expect(leaveButton).toBeDisabled();
    await code.fill("la1");
    await expect(leaveButton).toBeEnabled();
    await leaveButton.click();

    await expect(page.getByText(/^You have left “Linear Algebra/)).toBeVisible();
    await expect(page.getByTestId("participation-row")).toHaveCount(0);
  });

  test("leaves the only tutorial with the course alone", async ({ factory, student }) => {
    const lecture = await enrollInTutorial(factory, student.user.id, "add_and_remove");
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    const tutorialRow = page.getByTestId("participation-row").filter({ hasText: "Mo 10" });
    await expect(tutorialRow).toContainText("you leave it only together with the course.");
    await expect(tutorialRow.getByRole("button")).toHaveCount(0);

    await page.getByRole("button", { name: "Leave course" }).click();
    await expect(page.getByRole("dialog", { name: "Leave this course" })
      .getByText("You leave Mo 10.")).toBeVisible();
  });

  test("releases the page when a stream replaces the open dialog", async ({
    factory, student,
  }) => {
    const lecture = await enrollInTutorial(factory, student.user.id, "disabled");
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("button", { name: "Leave course" }).click();
    const dialog = page.getByRole("dialog", { name: "Leave this course" });
    await expect(dialog).toBeVisible();

    // what leaving a group or saving preferences sends back
    await page.evaluate(() => {
      const turbo = (window as unknown as {
        Turbo: { renderStreamMessage: (_html: string) => void };
      }).Turbo;
      turbo.renderStreamMessage(
        "<turbo-stream action=\"update\" target=\"student_registration_participation\">"
        + "<template><p>Replaced</p></template></turbo-stream>",
      );
    });

    await expect(page.getByText("Replaced")).toBeVisible();
    await expect(dialog).toHaveCount(0);
    await expect(page.locator(".modal-backdrop")).toHaveCount(0);
    await expect(page.locator("body")).not.toHaveClass(/modal-open/);
  });

  test("says why a student cannot leave alone", async ({ factory, student }) => {
    const lecture = await enrollInTutorial(factory, student.user.id, "disabled");
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Final Exam",
    });
    await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: student.user.id });
    const { page } = student;

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("button", { name: "Leave course" }).click();
    const dialog = page.getByRole("dialog", { name: "Leave this course" });

    await expect(dialog.getByText("You cannot withdraw from “Final Exam” yourself."))
      .toBeVisible();
    await expect(dialog.getByText("Please contact the lecturer.")).toBeVisible();
    await expect(dialog.getByRole("button", { name: "Leave course" })).toHaveCount(0);
    await dialog.getByRole("button", { name: "Close" }).last().click();
    await expect(dialog).toBeHidden();
  });
});

test.describe("people who left a course", () => {
  test("are listed for the lecturer, who can readmit them", async ({ factory, teacher }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const former = await factory.create("confirmed_user", [], { name_in_tutorials: "Lina Berg" });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: former.id,
      excluded_at: new Date().toISOString(),
      excluded_by_id: former.id,
    });
    const { page } = teacher;

    await page.goto(`/lectures/${lecture.id}/performance/records`);
    await page.getByRole("combobox", { name: "All participants" })
      .selectOption({ label: "Left the course" });
    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" }))
      .toContainText("Left the course");

    await page.goto(`/lectures/${lecture.id}/edit?tab=participants`);
    await page.getByRole("link", { name: /^Left/ }).click();
    const row = page.getByRole("row").filter({ hasText: "Lina Berg" });
    await expect(row).toContainText("Left on");

    page.once("dialog", dialog => void dialog.accept());
    await row.getByRole("button", { name: "Readmit" }).click();

    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" })).toHaveCount(0);
    await page.getByRole("link", { name: /^Enrolled/ }).click();
    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" })).toBeVisible();
  });
});
