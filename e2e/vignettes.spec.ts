import { expect, test } from "./_support/fixtures";
import { FactoryBot, FactoryBotObject } from "./_support/factorybot";
import { CODENAME_PATTERN, VignettesPage } from "./page-objects/vignettes_page";

const CONSENT_TEXT = "We store your answers under the code you are given.";

test.describe.configure({ timeout: 90_000 });

test.describe("Vignettes", () => {
  async function createLecture(factory: FactoryBot, teacherId: number, studentId: number,
    usesVignettes: boolean): Promise<FactoryBotObject> {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      locale: "en",
      teacher_id: teacherId,
      vignettes: usesVignettes,
    });
    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: studentId,
    });
    return lecture;
  }

  async function createVignette(factory: FactoryBot, lectureId: number, title: string,
    collectsData: boolean, editable = true): Promise<FactoryBotObject> {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title,
      published: true,
      editable,
      data_collection: collectsData,
      consent_text: collectsData ? CONSENT_TEXT : "",
    });

    for (const position of [1, 2]) {
      const slide = await factory.create("vignettes_slide", [], {
        vignettes_questionnaire_id: questionnaire.id,
        title: `Slide ${position}`,
        position,
      });
      await factory.create("vignettes_text_question", [], {
        vignettes_slide_id: slide.id,
        question_text: `Question ${position}`,
      });
    }

    return questionnaire;
  }

  test("the sidebar offers vignettes only where they are switched on",
    async ({ factory, student, teacher }) => {
      const without = await createLecture(factory, teacher.user.id, student.user.id, false);
      const with_ = await createLecture(factory, teacher.user.id, student.user.id, true);

      await student.page.goto(`/lectures/${without.id}`);
      await expect(student.page.getByRole("link", { name: "Vignettes" })).toBeHidden();

      await student.page.goto(`/lectures/${with_.id}`);
      await student.page.getByRole("link", { name: "Vignettes" }).click();

      await expect(student.page.getByRole("heading", { name: "Vignettes" })).toBeVisible();
    });

  test("a vignette without data collection asks nothing and stores nothing",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Quiet vignette", false);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Quiet vignette");

      await expect(student.page.getByText("Question 1")).toBeVisible();
      // A vignette is lecture content and keeps the lecture sidebar.
      await expect(student.page.getByRole("link", { name: "Vignettes" })).toBeVisible();
      await studentVignettes.answerText("first");
      await studentVignettes.submit();

      await expect(student.page.getByText("Question 2")).toBeVisible();
      await studentVignettes.answerText("second");
      await studentVignettes.submit(true);

      await expect(student.page.getByRole("heading", { name: "All done" })).toBeVisible();

      const teacherVignettes = new VignettesPage(teacher.page);
      const exportData = await teacherVignettes.exportQuestionnaire(questionnaire.id);
      expect(exportData.rows).toHaveLength(0);
    });

  test("declining data collection leaves the whole vignette usable",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Study vignette", true);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Study vignette");

      await expect(student.page.getByText(CONSENT_TEXT)).toBeVisible();
      await studentVignettes.declineDataCollection();

      await studentVignettes.answerText("first");
      await studentVignettes.submit();
      await expect(student.page.getByText("Question 2")).toBeVisible();
      await studentVignettes.answerText("second");
      await studentVignettes.submit(true);

      await expect(student.page.getByRole("heading", { name: "All done" })).toBeVisible();

      const teacherVignettes = new VignettesPage(teacher.page);
      const exportData = await teacherVignettes.exportQuestionnaire(questionnaire.id);
      expect(exportData.rows).toHaveLength(0);
    });

  test("agreeing hands out a code and files the answers under it",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Study vignette", true);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Study vignette");

      await student.page.getByRole("radio", { name: "Yes, and I need a code." }).check();
      await student.page.getByRole("button", { name: "Continue" }).click();
      await student.page.waitForURL(/\/codename/);

      await expect(student.page.getByText(CODENAME_PATTERN)).toBeVisible();
      await expect(student.page.getByText("exists nowhere but on your note")).toBeVisible();

      const codename = await studentVignettes.acknowledgeCode();

      await studentVignettes.answerText("first");
      await studentVignettes.submit();
      await studentVignettes.answerText("second");
      await studentVignettes.submit(true);

      const teacherVignettes = new VignettesPage(teacher.page);
      const exportData = await teacherVignettes.exportQuestionnaire(questionnaire.id);
      expect(exportData.rows).toHaveLength(2);
      expect(exportData.rows.map(row => row.codename)).toEqual([codename, codename]);
      expect(exportData.rows.map(row => row.answer)).toEqual(["first", "second"]);
    });

  test("the consent text appears only once data collection is switched on",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Quiet vignette", false);

      await teacher.page.goto(`/questionnaires/${questionnaire.id}/edit`);
      const consentText = teacher.page.getByRole("textbox", { name: "Consent text" });
      const toggle = teacher.page.getByRole("checkbox", { name: "Data collection possible" });

      await expect(consentText).toBeHidden();

      await toggle.check();
      await expect(consentText).toBeVisible();

      await toggle.uncheck();
      await expect(consentText).toBeHidden();
    });

  test("data collection cannot be saved without a consent text",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Quiet vignette", false);

      await teacher.page.goto(`/questionnaires/${questionnaire.id}/edit`);
      const toggle = teacher.page.getByRole("checkbox", { name: "Data collection possible" });
      await toggle.check();
      await teacher.page.getByRole("button", { name: "Save data collection settings" })
        .click();

      await expect(teacher.page.getByText("Please write the consent text")).toBeVisible();

      await teacher.page.reload();
      await expect(toggle).not.toBeChecked();
    });

  test("a locked vignette offers no creation buttons at all",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      // Publishing locks a vignette for good; unpublishing does not unlock it.
      const questionnaire = await createVignette(factory, lecture.id, "Locked", false, false);

      await teacher.page.goto(`/questionnaires/${questionnaire.id}/edit`);
      await teacher.page.getByText("Slide 1").waitFor();

      await expect(teacher.page.getByRole("button", { name: "New slide" })).toBeHidden();
      await expect(teacher.page.getByRole("button", { name: "New info slide" })).toBeHidden();
      // The consent settings are frozen along with the content.
      await expect(teacher.page.getByRole("textbox", { name: "Consent text" })).toBeHidden();
      await expect(teacher.page.getByRole("checkbox", { name: "Data collection possible" }))
        .toBeDisabled();
      // The lock next to the title is what explains it.
      await expect(teacher.page.locator("[data-bs-toggle='popover']")).toBeVisible();
    });

  test("the last slide leads to a closing page, with the code for next time",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      await createVignette(factory, lecture.id, "Study vignette", true);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Study vignette");
      const codename = await studentVignettes.consentWithNewCode();

      await studentVignettes.answerText("first");
      await studentVignettes.submit();
      await studentVignettes.answerText("second");
      await studentVignettes.submit(true);

      await expect(student.page.getByRole("heading", { name: "All done" })).toBeVisible();
      await expect(student.page.getByText("Your code, in case you need it")).toBeVisible();
      await expect(student.page.getByText(CODENAME_PATTERN)).toBeVisible();

      const shown = await student.page.getByText(CODENAME_PATTERN).innerText();
      expect(shown.replaceAll("-", "")).toBe(codename);

      await student.page.getByRole("link", { name: "Back to the overview" }).click();
      await expect(student.page.getByRole("heading", { name: "Vignettes" })).toBeVisible();
    });

  test("a preview leaves the reader's resume position alone",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Quiet vignette", false);
      const key = `vignettes.position.${questionnaire.id}`;

      await teacher.page.goto(`/questionnaires/${questionnaire.id}/preview`);
      await expect(teacher.page.getByText("Question 1")).toBeVisible();

      expect(await teacher.page.evaluate(k => window.localStorage.getItem(k), key))
        .toBeNull();
    });

  test("the resume position survives a rejected answer and goes on the closing page",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      const questionnaire = await createVignette(factory, lecture.id, "Study vignette", true);
      const key = `vignettes.position.${questionnaire.id}`;
      const stored = () => student.page.evaluate(k => window.localStorage.getItem(k), key);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Study vignette");
      await studentVignettes.consentWithNewCode();
      await studentVignettes.answerText("first");
      await studentVignettes.submit();

      // An empty answer is refused, and the reader keeps their place.
      await student.page.getByRole("textbox").fill("");
      await student.page.getByLabel("Finish vignette").click();
      await expect(student.page.getByText("Question 2")).toBeVisible();
      expect(await stored()).toBe("2");

      await studentVignettes.answerText("second");
      await studentVignettes.submit(true);
      await expect(student.page.getByRole("heading", { name: "All done" })).toBeVisible();
      expect(await stored()).toBeNull();
    });

  test("the browser remembers which slide the reader stopped at",
    async ({ factory, student, teacher }) => {
      const lecture = await createLecture(factory, teacher.user.id, student.user.id, true);
      await createVignette(factory, lecture.id, "Long vignette", false);

      const studentVignettes = new VignettesPage(student.page);
      await studentVignettes.openOverview(lecture.id);
      await studentVignettes.openQuestionnaire("Long vignette");
      await studentVignettes.answerText("first");
      await studentVignettes.submit();
      await expect(student.page.getByText("Question 2")).toBeVisible();

      await studentVignettes.openOverview(lecture.id);
      const row = studentVignettes.row("Long vignette");
      await expect(row.getByRole("link", { name: "Continue" })).toBeVisible();

      await row.getByRole("link", { name: "Continue" }).click();
      await expect(student.page.getByText("Question 2")).toBeVisible();
    });
});
