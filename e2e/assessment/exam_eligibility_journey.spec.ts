import { expect, test } from "../_support/fixtures";
import { createLecture } from "./helpers";

/**
 * The promise of the whole feature, from one end to the other: marked homework
 * becomes an eligibility decision, and that decision is what a student meets or
 * misses when they try to sit the exam. This is the only test that crosses from
 * the assessment side into the registration side.
 */
test.describe("eligibility decides the exam place", () => {
  test("tells a student their admission is what stands in the way", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("lecture_membership", [], {
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
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 50,
    });

    // the teacher opens registration, as they would
    await teacher.page.goto(`/lectures/${lecture.id}/edit?tab=exams`);
    await teacher.page.getByRole("link", { name: "Main Exam", exact: true })
      .click();
    await teacher.page.locator("#exams_container")
      .getByRole("tab", { name: "Registrations" }).click();
    teacher.page.on("dialog", dialog => dialog.accept());
    await teacher.page.locator("#exams_container")
      .getByRole("button", { name: "Start Registration" }).click();
    await expect(teacher.page.locator("#exams_container")
      .getByRole("button", { name: "End Registration" })).toBeVisible();

    await student.page.goto(`/lectures/${lecture.id}/home`);
    await expect(student.page.getByText(
      "Your registration would currently fail at finalization",
    )).toBeVisible();
    // the lecture title sits in its own <em>, so the sentence is matched as a
    // whole rather than as one string
    const requirement = student.page
      .getByText(/You must be admitted to the exam in/).first();
    await expect(requirement).toBeVisible();
    // this <em> was empty before the policy read its own config, and a fallback
    // stands in whenever it still cannot
    await expect(requirement.locator("em")).not.toBeEmpty();
    await expect(requirement).not.toContainText("No configuration available");
    await expect(student.page.getByText("Currently not fulfilled").first())
      .toBeVisible();

    // the teacher admits them
    await factory.create("student_performance_certification", ["passed"], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });

    await student.page.goto(`/lectures/${lecture.id}/home`);
    await expect(student.page.getByText(
      "Your registration would currently fail at finalization",
    )).toHaveCount(0);
    await expect(student.page.getByRole("button", { name: "Register now" }))
      .toBeEnabled();
  });
});
