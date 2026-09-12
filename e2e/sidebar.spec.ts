import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test("can access tutorial submission page (only as tutor)",
  async ({ factory,
    student: { page: studentPage },
    teacher: { page: teacherPage, user: teacherUser },
    tutor: { page: tutorPage, user: tutorUser } }) => {
    const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"],
      { teacher_id: teacherUser.id });
    await factory.create("assignment", [], { lecture_id: lecture.id });
    await factory.create("tutorial", ["with_tutor_by_id"],
      { lecture_id: lecture.id, tutor_id: tutorUser.id });

    // student should NOT see tutorials link
    await new LecturePage(studentPage, lecture.id).subscribe();
    const studentTutorialsLink = studentPage.locator('[data-controller="lecture-sidebar"]')
      .getByRole("link", {
        name: "Tutorials",
      });
    await expect(studentTutorialsLink).toHaveCount(0);

    // the lecturer edits sheets and points from the lecture's edit page, not from here
    await teacherPage.goto(`/lectures/${lecture.id}`);
    const teacherSidebar = teacherPage.locator('[data-controller="lecture-sidebar"]');
    await expect(teacherSidebar.getByRole("link", { name: "Tutorials" })).toHaveCount(0);
    await expect(teacherSidebar.getByRole("link", { name: "Submissions" })).toHaveCount(0);

    // tutor should see tutorials link
    await new LecturePage(tutorPage, lecture.id).subscribe();
    const tutorTutorialsLink = tutorPage.locator('[data-controller="lecture-sidebar"]')
      .getByRole("link", {
        name: "Tutorials",
      });
    await expect(tutorTutorialsLink).toHaveAttribute("href", /tutorials/);
    await tutorTutorialsLink.click();
    await expect(tutorPage.getByText("no submissions")).toBeVisible();
  });
