import { User } from "../_support/auth";
import { FactoryBot } from "../_support/factorybot";
import { expect, Page, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

type Actor = { page: Page; user: User };

/**
 * Sets up an exam whose registration is checked against the admission at
 * finalization, opens registration as the teacher and registers the student -
 * the state the three outcomes below start from.
 */
async function registerForAdmissionCheckedExam(
  factory: FactoryBot, teacher: Actor, student: Actor,
) {
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

  const dashboard = new ExamDashboardPage(teacher.page, lecture.id);
  await dashboard.open("Main Exam");
  await dashboard.tab("Registrations").click();
  teacher.page.on("dialog", dialog => dialog.accept());
  await dashboard.pane.getByRole("button", { name: "Start Registration" }).click();
  await expect(dashboard.pane.getByRole("button", { name: "End Registration" }))
    .toBeVisible();

  await student.page.goto(`/lectures/${lecture.id}`);
  await student.page.getByRole("heading", { name: "Main Exam" }).click();
  await student.page.getByRole("button", { name: "Register for Main Exam" }).click();
  await expect(student.page.getByRole("button", { name: "Withdraw from Main Exam" }))
    .toBeVisible();

  return { lecture, dashboard };
}

/** Ends the registration and finalizes it, as the teacher does. */
async function finalizeRegistration(dashboard: ExamDashboardPage) {
  await dashboard.open("Main Exam");
  await dashboard.tab("Registrations").click();
  await dashboard.pane.getByRole("button", { name: "End Registration" }).click();
  await dashboard.pane.getByRole("link", { name: "Review & Finalize" }).click();
  await dashboard.page.getByRole("button", { name: "Finalize Allocation" }).click();
  await expect(dashboard.pane.getByText(/Finalized on/)).toBeVisible();
}

/**
 * The promise of the whole feature, from one end to the other: marked homework
 * becomes an eligibility decision, and that decision is what a student meets or
 * misses when they try to sit the exam. These are the only tests that cross from
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

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("heading", { name: "Main Exam" }).click();
    await expect(student.page.getByText(
      "Your registration would currently fail at finalization",
    )).toBeVisible();
    await student.page.getByText("Policy checks for this registration").click();
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

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("heading", { name: "Main Exam" }).click();
    await expect(student.page.getByText(
      "Your registration would currently fail at finalization",
    )).toHaveCount(0);
    await expect(student.page.getByRole("button", { name: /^Register for / }))
      .toBeEnabled();
  });

  test("holds finalization back while the admission is undecided", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture, dashboard } = await registerForAdmissionCheckedExam(
      factory, teacher, student,
    );

    await dashboard.open("Main Exam");
    await dashboard.tab("Registrations").click();
    await dashboard.pane.getByRole("button", { name: "End Registration" }).click();
    await dashboard.pane.getByRole("link", { name: "Review & Finalize" }).click();

    await expect(dashboard.pane.getByText("Allocation currently not possible")).toBeVisible();
    await expect(dashboard.pane.getByRole("button", { name: "Finalize Allocation" }))
      .toBeDisabled();
    const blocked = dashboard.pane.getByRole("row").filter({ hasText: student.user.email });
    await expect(blocked).toContainText("No certification record");
    await expect(dashboard.pane.getByRole("link", { name: "Resolve in Certifications dashboard" }))
      .toBeVisible();

    // the teacher decides the admission, and the way is free
    await factory.create("student_performance_certification", ["passed"], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
    await dashboard.open("Main Exam");
    await dashboard.tab("Registrations").click();
    await dashboard.pane.getByRole("link", { name: "Review & Finalize" }).click();
    await expect(dashboard.pane.getByRole("button", { name: "Finalize Allocation" }))
      .toBeEnabled();
  });

  test("puts an admitted student on the exam list at finalization", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture, dashboard } = await registerForAdmissionCheckedExam(
      factory, teacher, student,
    );
    await factory.create("student_performance_certification", ["passed"], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });

    await finalizeRegistration(dashboard);

    await student.page.goto(`/lectures/${lecture.id}`);
    const seat = student.page.getByTestId("participation-row")
      .filter({ hasText: "Main Exam" });
    await expect(seat.getByText("On the exam list")).toBeVisible();
  });

  test("turns a student who was not admitted away at finalization", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture, dashboard } = await registerForAdmissionCheckedExam(
      factory, teacher, student,
    );
    await factory.create("student_performance_certification", ["failed"], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });

    await finalizeRegistration(dashboard);

    await student.page.goto(`/lectures/${lecture.id}`);
    const rows = student.page.getByTestId("participation-row");
    await expect(rows.filter({ hasText: "On the exam list" })).toHaveCount(0);
    const rejection = rows.filter({ hasText: "Main Exam" });
    await expect(rejection).toContainText("Rejected");
    await expect(rejection).toContainText("you were not admitted to the exam");
  });
});
