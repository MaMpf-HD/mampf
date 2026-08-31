import { expect, test } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

/**
 * The student's own list of sheets. Two columns carry the state and never both
 * speak: a number wherever there is one, a badge only where there cannot be.
 */
test.describe("the student's sheet list", () => {
  async function enrolledLecture(
    factory: FactoryBot,
    teacherId: number,
    studentId: number,
  ): Promise<FactoryBotObject> {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacherId,
      locale: "en",
    });
    // The subscription is what `proper_student_in?` reads; the roster
    // membership beside it is what the gradebook counts.
    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: studentId,
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: studentId,
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Monday group",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: studentId,
    });
    return lecture;
  }

  /** A sheet whose deadline has passed, so the gradebook has the last word. */
  async function closedSheet(
    factory: FactoryBot,
    lectureId: number,
    title: string,
  ): Promise<FactoryBotObject> {
    return factory.create("assignment", ["expired"], {
      lecture_id: lectureId,
      title,
    });
  }

  /** A marked sheet with both PDFs and the reader on its team. */
  async function markedSheetWithFiles(
    factory: FactoryBot,
    lectureId: number,
    studentId: number,
    title: string,
  ): Promise<FactoryBotObject> {
    const assignment = await closedSheet(factory, lectureId, title);
    const book = await assignment.__call("assessment");
    await factory.create("assessment_participation", ["marked"], {
      assessment_id: book.id,
      user_id: studentId,
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lectureId,
      title: `Group for ${title}`,
    });
    const submission = await factory.create(
      "submission", ["with_manuscript", "with_correction"], {
        assignment_id: assignment.id,
        tutorial_id: tutorial.id,
      },
    );
    await factory.create("user_submission_join", [], {
      submission_id: submission.id,
      user_id: studentId,
    });
    return submission;
  }

  test("shows a marked sheet by its number and an unmarked one by its badge",
    async ({ factory, teacher, student }) => {
      const lecture = await enrolledLecture(
        factory, teacher.user.id, student.user.id,
      );

      const marked = await closedSheet(factory, lecture.id, "Homework 1");
      const markedBook = await marked.__call("assessment");
      await factory.create("assessment_participation", ["marked"], {
        assessment_id: markedBook.id,
        user_id: student.user.id,
      });

      const waiting = await closedSheet(factory, lecture.id, "Homework 2");
      const waitingBook = await waiting.__call("assessment");
      await factory.create("assessment_task", [], {
        assessment_id: waitingBook.id,
        max_points: 10,
      });
      await factory.create("assessment_participation", [], {
        assessment_id: waitingBook.id,
        user_id: student.user.id,
        submitted_at: new Date(Date.now() - 86400000).toISOString(),
      });

      await student.page.goto(`/lectures/${lecture.id}/submissions`);
      const list = student.page.getByRole("region", { name: "Earlier sheets" });

      await expect(list.getByText("Homework 1")).toBeVisible();
      await expect(list.getByText("3.5", { exact: true })).toBeVisible();
      // The badge stands exactly where there is no number, so there is one of
      // it on the page and it belongs to the other sheet.
      await expect(list.getByText("Waiting to be marked")).toHaveCount(1);
      await expect(list.getByText("Homework 2")).toBeVisible();
    });

  // A screen reader gets "3.5 of 8 points", never "3.5 slash 8".
  test("spells the number out for a screen reader", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );
    const marked = await closedSheet(factory, lecture.id, "Homework 1");
    const book = await marked.__call("assessment");
    await factory.create("assessment_participation", ["marked"], {
      assessment_id: book.id,
      user_id: student.user.id,
    });

    await student.page.goto(`/lectures/${lecture.id}/submissions`);

    await expect(
      student.page.getByText("3.5 of 8 points"),
    ).toHaveCount(1);
  });

  test("says in words that an old sheet carries no points", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );
    await factory.create("assignment", ["expired", "without_assessment"], {
      lecture_id: lecture.id,
      title: "Blatt 4",
    });

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    const list = student.page.getByRole("region", { name: "Earlier sheets" });

    await expect(list.getByText("Blatt 4")).toBeVisible();
    await expect(list.getByText("old-style sheet")).toBeVisible();
    await expect(list.getByText("no points")).toBeVisible();
  });

  // The sheet that can still be handed in has its own card above the list;
  // a row for it as well would tell the same sheet twice.
  test("keeps every sheet that is still open out of the list", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );
    await closedSheet(factory, lecture.id, "Homework 1");
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Homework 2",
      deadline: new Date(Date.now() + 7 * 86400000).toISOString(),
    });
    // Weeks away, and still a sheet one may hand in early - so it keeps a card
    // rather than becoming a row nobody can hand in on.
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Homework 3",
      deadline: new Date(Date.now() + 21 * 86400000).toISOString(),
    });

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    const list = student.page.getByRole("region", { name: "Earlier sheets" });

    await expect(student.page.getByText("Homework 2")).toBeVisible();
    await expect(student.page.getByText("Homework 3")).toBeVisible();
    await expect(list.getByText("Homework 2")).toHaveCount(0);
    await expect(list.getByText("Homework 3")).toHaveCount(0);
    await expect(list.getByText("1 sheet", { exact: true })).toBeVisible();
  });

  // The fold is what gives a student their own PDFs back once the deadline has
  // passed and the card is gone.
  test("opens a row on its problems, its files and its team", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );
    await markedSheetWithFiles(factory, lecture.id, student.user.id, "Homework 1");

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    const list = student.page.getByRole("region", { name: "Earlier sheets" });
    const handedIn = list.getByRole("link", { name: "What you handed in" });

    await expect(list.getByText("Points per problem")).toBeHidden();
    await expect(handedIn).toBeHidden();

    await list.getByText("Homework 1").click();

    await expect(list.getByText("Points per problem")).toBeVisible();
    await expect(list.getByText("File and team")).toBeVisible();
    // How a task is named has its own examples in the component spec; what only
    // a browser can show is that the numbers arrive when the row opens.
    await expect(list.getByText("1.5 of 4 points")).toHaveCount(1);
    await expect(handedIn).toBeVisible();
  });

  test("hands the correction and the manuscript back as files", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );
    const submission = await markedSheetWithFiles(
      factory, lecture.id, student.user.id, "Homework 1",
    );

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await student.page.getByText("Homework 1").click();

    // Both fixtures carry the same filename, which is exactly why each link
    // says in words which of the two it is.
    await expect(
      student.page.getByRole("link", { name: "What you handed in" }),
    ).toHaveAttribute("href", `/submissions/${submission.id}/show_manuscript`);
    await expect(
      student.page.getByRole("link", { name: "The correction" }),
    ).toHaveAttribute("href", `/submissions/${submission.id}/show_correction`);
  });

  // Nothing set up yet is a state the page draws, not one it turns you away
  // from - the first week of a term looks exactly like this.
  test("opens for a lecture that has no sheets at all", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await enrolledLecture(
      factory, teacher.user.id, student.user.id,
    );

    await student.page.goto(`/lectures/${lecture.id}/submissions`);

    await expect(
      student.page.getByRole("heading", { name: "Earlier sheets" }),
    ).toBeVisible();
    await expect(student.page.getByText(
      "None yet. Once a sheet has been marked, it appears here with your points.",
    )).toBeVisible();
  });
});
