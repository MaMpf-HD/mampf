import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

// Checking the admission needs a decision of the lecture, which only its
// members have.
test.describe("registering for an admission-checked exam without a place in the lecture", () => {
  test("is refused, and the student is told whom to ask", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("lecture_bookmark", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const campaign = await exam.__call("registration_campaign");
    await factory.create("registration_policy", ["student_performance"], {
      registration_campaign_id: campaign.id,
      phase: "finalization",
      config: { lecture_ids: [String(lecture.id)] },
    });
    const dashboard = new ExamDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Main Exam");
    await dashboard.tab("Registrations").click();
    teacher.page.on("dialog", dialog => dialog.accept());
    await dashboard.pane.getByRole("button", { name: "Start Registration" }).click();
    await expect(dashboard.pane.getByRole("button", { name: "End Registration" }))
      .toBeVisible();

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("heading", { name: "Main Exam" }).click();

    await expect(student.page.getByText(
      "Only participants of this lecture can register for the exam.",
    ).first()).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register for Main Exam" }))
      .toHaveCount(0);
    await expect(student.page.getByRole("button", { name: "Unavailable" })).toBeDisabled();
  });
});
