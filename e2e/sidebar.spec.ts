import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test("can access tutorial submission page (only as tutor)",
  async ({ factory,
    student: { page: studentPage },
    tutor: { page: tutorPage, user: tutorUser } }) => {
    const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
    await factory.create("assignment", [], { lecture_id: lecture.id });
    await factory.create("tutorial", ["with_tutor_by_id"],
      { lecture_id: lecture.id, tutor_id: tutorUser.id });

    // student should NOT see tutorials link
    await new LecturePage(studentPage, lecture.id).subscribe();
    await expect(studentPage.getByRole("link", { name: "Tutorials" })).toHaveCount(0);

    // tutor should see tutorials link
    await new LecturePage(tutorPage, lecture.id).subscribe();
    await tutorPage.getByRole("link", { name: "Tutorials" }).click();
    await expect(tutorPage).toHaveURL(/tutorials/);
    await expect(tutorPage.getByText("no submissions")).toBeVisible();
  });
