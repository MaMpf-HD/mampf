import { expect, test } from "./_support/fixtures";
import { VignettesPage } from "./page-objects/vignettes_page";

test.describe.configure({ timeout: 90_000 });

test.describe("Vignettes Exports", () => {
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

  test("exports answers and per-slide timings", async ({ factory }) => {
    const questionnaire = await factory.create("vignettes_questionnaire", [], {
      lecture_id: lectureId,
      title: "Comprehensive exporter",
      published: true,
      editable: true,
    });

    const slide1 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Text slide",
      position: 1,
    });
    await factory.create("vignettes_text_question", [], {
      vignettes_slide_id: slide1.id,
      question_text: "Text question",
    });

    const slide2 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Number slide",
      position: 2,
    });
    await factory.create("vignettes_number_question", [], {
      vignettes_slide_id: slide2.id,
      question_text: "Number question",
    });

    const infoSlide = await factory.create("vignettes_info_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Info 1",
      icon_type: "eye",
    });

    const slide3 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "MC slide",
      position: 3,
      info_slide_ids: [infoSlide.id],
    });
    const question = await factory.create(
      "vignettes_multiple_choice_question",
      [],
      {
        vignettes_slide_id: slide3.id,
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

    const slide4 = await factory.create("vignettes_slide", [], {
      vignettes_questionnaire_id: questionnaire.id,
      title: "Likert slide",
      position: 4,
    });
    await factory.create("vignettes_likert_scale_question", [], {
      vignettes_slide_id: slide4.id,
      question_text: "Likert question",
      language: "en",
    });

    const codename = "UnifiedCode";
    await studentVignettes.enableMockClock(0);
    await studentVignettes.setPersonalCode(lectureId, codename);
    await studentVignettes.openQuestionnaire(questionnaire.id);

    await studentVignettes.answerText("text-answer");
    await studentVignettes.advanceMockTime(11);
    await studentVignettes.submitWithStats();

    await studentVignettes.answerNumber("42");
    await studentVignettes.advanceMockTime(21);
    await studentVignettes.submitWithStats();

    await studentVignettes.answerMultipleChoice("Option A");
    await studentVignettes.advanceMockTime(1);
    await studentVignettes.openInfoSlide();
    await studentVignettes.advanceMockTime(2);
    await studentVignettes.closeInfoSlide();
    await studentVignettes.advanceMockTime(1);
    await studentVignettes.openInfoSlide();
    await studentVignettes.advanceMockTime(2);
    await studentVignettes.closeInfoSlide();
    await studentVignettes.advanceMockTime(29);
    await studentVignettes.submitWithStats();

    await studentVignettes.answerLikert("Complete alignment");
    await studentVignettes.advanceMockTime(41);
    await studentVignettes.submitWithStats();

    const exportData = await teacherVignettes.exportQuestionnaire(questionnaire.id);
    expect(exportData.rows).toHaveLength(4);

    const bySlidePosition = new Map(
      exportData.rows.map(row => [row.slidePosition, row]),
    );

    const row1 = bySlidePosition.get("1");
    const row2 = bySlidePosition.get("2");
    const row3 = bySlidePosition.get("3");
    const row4 = bySlidePosition.get("4");

    if (!row1 || !row2 || !row3 || !row4) {
      throw new Error("Missing expected rows in CSV export");
    }

    expect(row1.codename).toBe(codename);
    expect(row1.slideTitle).toBe("Text slide");
    expect(row1.totalTimeOnSlide).toBe("11");
    expect(row1.timeOnSlide).toBe("11");
    expect(row1.answer).toBe("text-answer");
    expect(row1.selectedOptions).toBe("");
    expect(row1.likertScaleOption).toBe("");

    expect(row2.codename).toBe(codename);
    expect(row2.slideTitle).toBe("Number slide");
    expect(row2.totalTimeOnSlide).toBe("21");
    expect(row2.timeOnSlide).toBe("21");
    expect(row2.answer).toBe("42");
    expect(row2.selectedOptions).toBe("");
    expect(row2.likertScaleOption).toBe("");

    expect(row3.codename).toBe(codename);
    expect(row3.slideTitle).toBe("MC slide");
    expect(row3.totalTimeOnSlide).toBe("35");
    expect(row3.timeOnSlide).toBe("30");
    expect(row3.timeOnInfoSlide).toBe(`{"${infoSlide.id}":5}`);
    expect(row3.infoSlideAccessCount).toBe(`{"${infoSlide.id}":2}`);
    expect(row3.infoSlideFirstAccessTime).toBe(`{"${infoSlide.id}":1}`);
    expect(row3.answer).toBe("");
    expect(row3.selectedOptions).toBe("Option A");
    expect(row3.likertScaleOption).toBe("");

    expect(row4.codename).toBe(codename);
    expect(row4.slideTitle).toBe("Likert slide");
    expect(row4.totalTimeOnSlide).toBe("41");
    expect(row4.timeOnSlide).toBe("41");
    expect(row4.answer).toBe("");
    expect(row4.selectedOptions).toBe("");
    expect(row4.likertScaleOption).toBe("strongly_agree");
  });
});
