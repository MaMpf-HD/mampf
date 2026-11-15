import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

test("closes the policy form of an exam's registration on cancel",
  async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    const dashboard = new ExamDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Main Exam");
    await dashboard.tab("Registrations").click();
    const addPolicy = dashboard.pane.getByRole("link", { name: "Add Policy" });
    await addPolicy.click();
    const cancel = dashboard.pane.getByRole("button", { name: "Cancel" });
    await expect(cancel).toBeVisible();

    await cancel.click();

    await expect(cancel).toBeHidden();
    await expect(addPolicy).toBeVisible();
  });
