import { expect, test } from "./_support/fixtures";

test("tag filter updates question counter when a tag is selected",
  async ({ factory, student: { page, user } }) => {
    const course = await factory.create("course");
    const lecture = await factory.create("lecture", ["released_for_all"],
      { course_id: course.id });

    await factory.create("lecture_user_join", [], { lecture_id: lecture.id, user_id: user.id });

    const tagAlgebra = await factory.create("tag", [], { title: "Algebra" });
    const tagCalculus = await factory.create("tag", [], { title: "Calculus" });

    for (let i = 0; i < 6; i++) {
      const q = await factory.createNoValidate("question", ["with_stuff"], {
        teachable_type: "Course",
        teachable_id: course.id,
        released: "all",
      });
      await factory.create("medium_tag_join", [], { medium_id: q.id, tag_id: tagAlgebra.id });
    }
    for (let i = 0; i < 4; i++) {
      const q = await factory.createNoValidate("question", ["with_stuff"], {
        teachable_type: "Course",
        teachable_id: course.id,
        released: "all",
      });
      await factory.create("medium_tag_join", [], { medium_id: q.id, tag_id: tagCalculus.id });
    }

    await page.goto(`/lectures/${lecture.id}/show_random_quizzes`);

    const tagSelect = page.locator("#search_course_tag_ids-ts-control");

    await tagSelect.click();
    await tagSelect.fill("Alg");
    await page.getByRole("option", { name: "Algebra", exact: true }).click();
    await expect(page.locator("#question_counter"))
      .toContainText("6 questions have been found for the selected tags.");

    await tagSelect.click();
    await tagSelect.fill("Cal");
    await page.getByRole("option", { name: "Calculus", exact: true }).click();
    await expect(page.locator("#question_counter"))
      .toContainText("10 questions have been found for the selected tags.");

    await page.locator(".ts-wrapper .item").filter({ hasText: "Algebra" })
      .locator(".remove").click();
    await expect(page.locator("#question_counter"))
      .toContainText("4 questions have been found for the selected tags.");

    await page.locator(".ts-wrapper .item").filter({ hasText: "Calculus" })
      .locator(".remove").click();
    await expect(page.locator("#question_counter")).toBeEmpty();
  });
