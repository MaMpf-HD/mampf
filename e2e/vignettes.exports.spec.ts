import { expect, test } from "./_support/fixtures";
import {
  QUESTIONNAIRE_CSV_HEADERS,
  VignettesPage,
} from "./page-objects/vignettes_page";

test.describe.configure({ timeout: 90_000 });

test.describe("single-slide exports", () => {
  let lectureId: number;
  let studentVignettes: VignettesPage;
  let teacherVignettes: VignettesPage;

  test.beforeEach(async ({ factory, student, teacher }) => {
    studentVignettes = new VignettesPage(student.page);
    teacherVignettes = new VignettesPage(teacher.page);

    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      sort: "vignettes",
    });
    lectureId = lecture.id;

    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
  });

  test("exports text answers", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "Text exporter",
      published: true,
    });
    const slide = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Text slide",
      position: 1,
    });
    await factory.create("vignettes_text_question", [], {
      vignettes_slide_id: slide.id,
      question_text: "Text question",
    });

    await studentVignettes.setPersonalCode(lectureId, "TextCode");
    await studentVignettes.openQuestionnaire(questionnaire.id);
    await studentVignettes.answerText("text-answer");
    await studentVignettes.submitWithStats({
      timeOnSlide: 1,
      totalTimeOnSlide: 1,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    const rows = await teacherVignettes.exportQuestionnaireCsv(questionnaire.id);
    expect(rows[0]).toEqual(QUESTIONNAIRE_CSV_HEADERS);
    expect(rows).toHaveLength(2);
    expect(rows[1][10]).toBe("text-answer");
    expect(rows[1][11]).toBe("");
    expect(rows[1][12]).toBe("");
  });

  test("exports number answers", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "Number exporter",
      published: true,
    });
    const slide = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Number slide",
      position: 1,
    });
    await factory.create("vignettes_number_question", [], {
      vignettes_slide_id: slide.id,
      question_text: "Number question",
    });

    await studentVignettes.setPersonalCode(lectureId, "NumberCode");
    await studentVignettes.openQuestionnaire(questionnaire.id);
    await studentVignettes.answerNumber("42");
    await studentVignettes.submitWithStats({
      timeOnSlide: 1,
      totalTimeOnSlide: 2,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    const rows = await teacherVignettes.exportQuestionnaireCsv(questionnaire.id);
    expect(rows).toHaveLength(2);
    expect(rows[1][10]).toBe("42");
    expect(rows[1][11]).toBe("");
    expect(rows[1][12]).toBe("");
  });

  test("exports multiple-choice answers", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "MC exporter",
      published: true,
    });
    const slide = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "MC slide",
      position: 1,
    });
    const question = await factory.create(
      "vignettes_multiple_choice_question",
      [],
      {
        vignettes_slide_id: slide.id,
        question_text: "MC question",
      },
    );
    await factory.create("vignettes_option", [], {
      vignettes_question_id: question.id,
      text: "Option A",
    });
    await factory.create("vignettes_option", [], {
      vignettes_question_id: question.id,
      text: "Option B",
    });

    await studentVignettes.setPersonalCode(lectureId, "MCCode");
    await studentVignettes.openQuestionnaire(questionnaire.id);
    await studentVignettes.answerMultipleChoice("Option A");
    await studentVignettes.submitWithStats({
      timeOnSlide: 2,
      totalTimeOnSlide: 3,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    const rows = await teacherVignettes.exportQuestionnaireCsv(questionnaire.id);
    expect(rows).toHaveLength(2);
    expect(rows[1][10]).toBe("");
    expect(rows[1][11]).toBe("Option A");
    expect(rows[1][12]).toBe("");
  });

  test("exports likert-scale answers", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "Likert exporter",
      published: true,
    });
    const slide = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Likert slide",
      position: 1,
    });
    await factory.create("vignettes_likert_scale_question", [], {
      vignettes_slide_id: slide.id,
      question_text: "Likert question",
      language: "en",
    });

    await studentVignettes.setPersonalCode(lectureId, "LikertCode");
    await studentVignettes.openQuestionnaire(questionnaire.id);
    await studentVignettes.answerLikert("Complete alignment");
    await studentVignettes.submitWithStats({
      timeOnSlide: 3,
      totalTimeOnSlide: 4,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    const rows = await teacherVignettes.exportQuestionnaireCsv(questionnaire.id);
    expect(rows).toHaveLength(2);
    expect(rows[1][10]).toBe("");
    expect(rows[1][11]).toBe("");
    expect(rows[1][12]).toBe("strongly_agree");
  });
});

test.describe("multi-slide exports", () => {
  let lectureId: number;
  let studentVignettes: VignettesPage;
  let teacherVignettes: VignettesPage;

  test.beforeEach(async ({ factory, student, teacher }) => {
    studentVignettes = new VignettesPage(student.page);
    teacherVignettes = new VignettesPage(teacher.page);

    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      sort: "vignettes",
    });
    lectureId = lecture.id;

    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
  });

  test("exports per-slide times and responses", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "Statistics exporter",
      published: true,
      editable: true,
    });

    const slide1 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Slide 1",
      position: 1,
    });
    await factory.create("vignettes_text_question", [], {
      vignettes_slide_id: slide1.id,
      question_text: "Text question",
    });

    const infoSlide = await factory.create("vignettes_info_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Info 1",
      icon_type: "eye",
    });

    const slide2 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Slide 2",
      position: 2,
      info_slide_ids: [infoSlide.id],
    });
    const mcQuestion = await factory.create(
      "vignettes_multiple_choice_question",
      [],
      {
        vignettes_slide_id: slide2.id,
        question_text: "Multiple choice question",
      },
    );
    await factory.create("vignettes_option", [], {
      vignettes_question_id: mcQuestion.id,
      text: "Option A",
    });
    await factory.create("vignettes_option", [], {
      vignettes_question_id: mcQuestion.id,
      text: "Option B",
    });

    const slide3 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Slide 3",
      position: 3,
    });
    await factory.create("vignettes_likert_scale_question", [], {
      vignettes_slide_id: slide3.id,
      question_text: "Likert question",
      language: "en",
    });

    const codename = "TokenAlpha42";
    await studentVignettes.setPersonalCode(lectureId, codename);
    await studentVignettes.openQuestionnaire(questionnaire.id);

    await studentVignettes.answerText("Text response");
    await studentVignettes.submitWithStats({
      timeOnSlide: 11,
      totalTimeOnSlide: 13,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    await studentVignettes.answerMultipleChoice("Option A");
    await studentVignettes.submitWithStats({
      timeOnSlide: 21,
      totalTimeOnSlide: 27,
      timeOnInfoSlides: `{"${infoSlide.id}":6}`,
      infoSlidesAccessCount: `{"${infoSlide.id}":2}`,
      infoSlidesFirstAccessTime: `{"${infoSlide.id}":4}`,
    });

    await studentVignettes.answerLikert("Complete alignment");
    await studentVignettes.submitWithStats({
      timeOnSlide: 31,
      totalTimeOnSlide: 34,
      timeOnInfoSlides: "{}",
      infoSlidesAccessCount: "{}",
      infoSlidesFirstAccessTime: "{}",
    });

    const rows = await teacherVignettes.exportQuestionnaireCsv(questionnaire.id);
    expect(rows).toHaveLength(4);
    expect(rows[0]).toEqual(QUESTIONNAIRE_CSV_HEADERS);

    const bySlidePosition = new Map(rows.slice(1).map(row => [row[3], row]));

    const row1 = bySlidePosition.get("1");
    const row2 = bySlidePosition.get("2");
    const row3 = bySlidePosition.get("3");

    expect(row1).toBeTruthy();
    expect(row2).toBeTruthy();
    expect(row3).toBeTruthy();

    if (!row1 || !row2 || !row3) {
      throw new Error("Missing expected rows in CSV export");
    }

    expect(row1[2]).toBe(codename);
    expect(row1[4]).toBe("Slide 1");
    expect(row1[5]).toBe("13");
    expect(row1[6]).toBe("11");
    expect(row1[10]).toBe("Text response");

    expect(row2[2]).toBe(codename);
    expect(row2[4]).toBe("Slide 2");
    expect(row2[5]).toBe("27");
    expect(row2[6]).toBe("21");
    expect(row2[7]).toBe(`{"${infoSlide.id}":6}`);
    expect(row2[8]).toBe(`{"${infoSlide.id}":2}`);
    expect(row2[9]).toBe(`{"${infoSlide.id}":4}`);
    expect(row2[11]).toBe("Option A");

    expect(row3[2]).toBe(codename);
    expect(row3[4]).toBe("Slide 3");
    expect(row3[5]).toBe("34");
    expect(row3[6]).toBe("31");
    expect(row3[12]).toBe("strongly_agree");
  });
});
