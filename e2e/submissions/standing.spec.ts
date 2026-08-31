import { expect, test } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";
import { SubmissionsPage } from "../page-objects/submissions_page";

/**
 * The exam-admission block beside the card: what the reader has, what the
 * lecture asks, and one line per condition. It is a second place on the page,
 * and handing in changes both - so the answer carries both.
 */
test.describe("the standing beside the card", () => {
  async function lectureWithRule(
    factory: FactoryBot,
    teacherId: number,
    studentId: number,
  ): Promise<FactoryBotObject> {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacherId, locale: "en", uses_exam_eligibility: true,
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Monday group",
    });
    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id, user_id: studentId,
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: studentId,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: studentId,
    });

    // one sheet marked, one still open
    const past = await factory.create("assignment", ["expired"], {
      lecture_id: lecture.id, title: "Homework 1",
    });
    const pastBook = await past.__call("assessment");
    await factory.create("assessment_participation", ["marked"], {
      assessment_id: pastBook.id, user_id: studentId,
    });
    const open = await factory.create("assignment", [], {
      lecture_id: lecture.id, title: "Homework 2",
    });
    const openBook = await open.__call("assessment");
    await factory.create("assessment_task", [], {
      assessment_id: openBook.id, max_points: 16,
    });

    const achievement = await factory.create("achievement", [], {
      lecture_id: lecture.id, title: "Blackboard Talk",
    });
    const rule = await factory.create(
      "student_performance_rule", ["active", "with_percentage"],
      { lecture_id: lecture.id, min_percentage: 50 },
    );
    await factory.create("student_performance_rule_achievement", [], {
      rule_id: rule.id, achievement_id: achievement.id,
    });
    return lecture;
  }

  test("shows the points, the threshold and a line per condition", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await lectureWithRule(
      factory, teacher.user.id, student.user.id,
    );

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    const standing = student.page
      .getByRole("complementary", { name: "Exam admission" });

    await expect(standing.getByText("of 24 points")).toBeVisible();
    await expect(standing.getByText("12 needed")).toBeVisible();
    await expect(standing.getByText("50 % of the points")).toBeVisible();
    await expect(standing.getByText("Blackboard Talk")).toBeVisible();
    await expect(standing.getByText("not recorded yet")).toBeVisible();
  });

  // Handing in makes a sheet count among the points still being marked, and
  // that number lives in the standing, not on the card.
  test("moves with the card when a sheet is handed in", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await lectureWithRule(
      factory, teacher.user.id, student.user.id,
    );

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    const standing = student.page
      .getByRole("complementary", { name: "Exam admission" });
    await expect(standing.getByText("still being marked")).toHaveCount(0);

    await page.createSubmission();

    await expect(standing.getByText("16 points are still being marked."))
      .toBeVisible();
  });
});
