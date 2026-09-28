import { expect, Page, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { FactoryBot, FactoryBotObject } from "./_support/factorybot";
import { AnnotationsOverviewPage } from "./page-objects/annotations_overview_page";
import { ThymePlayer } from "./page-objects/thyme_player";

const LECTURE_TITLE_1 = "SageMath";
const MEDIUM_TITLE_1 = "Intro modules";
const LECTURE_TITLE_2 = "Lean4";
const MEDIUM_TITLE_2 = "Intro operators";
const MEDIUM_TITLE_3 = "Continuous functions";

// A shared card takes its category's colour (category.js), not the author's.
const CATEGORY_COLORS: Record<string, string> = {
  note: "#f78f19",
  content: "#A333C8",
  presentation: "#2185D0",
  mistake: "#fc1461",
};

function hexToRgb(hex: string): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgb(${r}, ${g}, ${b})`;
}

function timestamp(annotation: FactoryBotObject): string {
  return `0:00:${String(annotation.timestamp.seconds).padStart(2, "0")}`;
}

type Scenario = {
  lessons: FactoryBotObject[];
  media: FactoryBotObject[];
  annotations: FactoryBotObject[];
};

/**
 * Two annotations share a medium, so the order within a lecture is covered.
 * Lecture 2 comes first on the page: the overview sorts by lecture.updated_at,
 * and lecture 2 is created after lecture 1.
 */
async function annotationScenario(
  factory: FactoryBot, user: User, teacherId: number,
): Promise<Scenario> {
  const lectureSage = await factory.create("lecture_with_sparse_toc", ["with_title"], {
    title: LECTURE_TITLE_1, teacher_id: teacherId,
  });
  const lectureLean = await factory.create("lecture_with_sparse_toc", ["with_title"], {
    title: LECTURE_TITLE_2, teacher_id: teacherId,
  });

  const lessons = [];
  for (const lecture of [lectureSage, lectureLean, lectureLean]) {
    lessons.push(await factory.create("valid_lesson", [], { lecture_id: lecture.id }));
  }

  const media = [];
  const mediumTitles = [MEDIUM_TITLE_1, MEDIUM_TITLE_2, MEDIUM_TITLE_3];
  for (const [i, lesson] of lessons.entries()) {
    media.push(await factory.create("lesson_medium",
      ["with_video", "released", "with_lesson_by_id"],
      { lesson_id: lesson.id, description: mediumTitles[i] }));
  }

  const annotations = [];
  for (const medium of [media[0], media[1], media[2], media[2]]) {
    annotations.push(await factory.create("annotation", ["with_text"], {
      medium_id: medium.id, user_id: user.id,
    }));
  }

  return { lessons, media, annotations };
}

async function expectPlayerAt(popup: Page, mediumId: number, annotation: FactoryBotObject) {
  const player = new ThymePlayer(popup, mediumId);
  await expect(player.currentTime).toContainText(timestamp(annotation));
  await expect(player.annotationComment).toContainText(annotation.comment as string);
}

test.describe("the annotation sections", () => {
  test("show only own annotations for a student", async ({ student: { page } }) => {
    const overview = new AnnotationsOverviewPage(page);
    await overview.goto();

    await expect(overview.ownAnnotations).toBeVisible();
    await expect(overview.studentsAnnotations).toHaveCount(0);
  });

  test("show both own and students' annotations for a teacher",
    async ({ factory, teacher: { page, user } }) => {
      // The students' section is for people who have given a lecture.
      await factory.create("lecture", [], { teacher_id: user.id });
      const overview = new AnnotationsOverviewPage(page);
      await overview.goto();

      await expect(overview.ownAnnotations).toBeVisible();
      await expect(overview.studentsAnnotations).toBeVisible();
    });
});

test.describe("a card of one's own annotation", () => {
  test("is grouped by lecture", async ({ factory, teacher, student: { page, user } }) => {
    await annotationScenario(factory, user, teacher.user.id);
    const overview = new AnnotationsOverviewPage(page);
    await overview.goto();

    const section = overview.ownAnnotations;
    await expect(overview.lectures(section))
      .toHaveText([/Lean4.*\(3\)/, /SageMath.*\(1\)/]);
    const lean = await overview.openLecture(section, LECTURE_TITLE_2);
    await expect(overview.cards(lean)).toHaveCount(3);
    const sage = await overview.openLecture(section, LECTURE_TITLE_1);
    await expect(overview.cards(sage)).toHaveCount(1);
  });

  test("renders math content", async ({ factory, teacher, student: { page, user } }) => {
    const { media } = await annotationScenario(factory, user, teacher.user.id);
    const overview = new AnnotationsOverviewPage(page);
    await overview.goto();
    const lean = await overview.openLecture(overview.ownAnnotations, LECTURE_TITLE_2);
    await expect(overview.cards(lean).first().getByRole("math")).toHaveCount(0);

    await factory.create("annotation", ["with_text"], {
      medium_id: media[2].id, user_id: user.id,
      comment: "This is a math annotation: $\\frac{1}{2}$",
    });

    await overview.goto();
    const leanAgain = await overview.openLecture(overview.ownAnnotations, LECTURE_TITLE_2);
    await expect(overview.cards(leanAgain).first().getByRole("math")).toHaveCount(1);
  });

  test("shows the medium and the annotation",
    async ({ factory, teacher, student: { page, user } }) => {
      const { lessons, annotations } = await annotationScenario(factory, user, teacher.user.id);
      const overview = new AnnotationsOverviewPage(page);
      await overview.goto();

      // Opening one lecture's panel closes the other, so each is read in turn.
      const expected = [
        { lecture: LECTURE_TITLE_2, cards: [
          { title: MEDIUM_TITLE_3, annotation: annotations[3], lesson: lessons[2] },
          { title: MEDIUM_TITLE_3, annotation: annotations[2], lesson: lessons[2] },
          { title: MEDIUM_TITLE_2, annotation: annotations[1], lesson: lessons[1] },
        ] },
        { lecture: LECTURE_TITLE_1, cards: [
          { title: MEDIUM_TITLE_1, annotation: annotations[0], lesson: lessons[0] },
        ] },
      ];
      for (const { lecture, cards } of expected) {
        const panel = await overview.openLecture(overview.ownAnnotations, lecture);
        for (const [i, { title, annotation, lesson }] of cards.entries()) {
          const card = overview.cards(panel).nth(i);
          await expect(card).toContainText(lesson.date as string);
          await expect(card).toContainText(title);
          await expect(card).toContainText(annotation.category as string, { ignoreCase: true });
          await expect(card).toContainText(annotation.comment as string);
        }
      }
    });

  test("has a border in the annotation's colour",
    async ({ factory, teacher, student: { page, user } }) => {
      const { annotations } = await annotationScenario(factory, user, teacher.user.id);
      const overview = new AnnotationsOverviewPage(page);
      await overview.goto();

      const expected: [string, FactoryBotObject[]][] = [
        [LECTURE_TITLE_2, [annotations[3], annotations[2], annotations[1]]],
        [LECTURE_TITLE_1, [annotations[0]]],
      ];
      for (const [lecture, cards] of expected) {
        const panel = await overview.openLecture(overview.ownAnnotations, lecture);
        for (const [i, annotation] of cards.entries()) {
          await expect(overview.frame(overview.cards(panel).nth(i)))
            .toHaveCSS("border-color", hexToRgb(annotation.color as string));
        }
      }
    });

  test("opens the medium's video at the annotation when clicked",
    async ({ factory, teacher, student: { page, user } }) => {
      const { media, annotations } = await annotationScenario(factory, user, teacher.user.id);
      const overview = new AnnotationsOverviewPage(page);
      const expected = [
        { lecture: LECTURE_TITLE_2, index: 0, medium: media[2], annotation: annotations[3] },
        { lecture: LECTURE_TITLE_2, index: 1, medium: media[2], annotation: annotations[2] },
        { lecture: LECTURE_TITLE_2, index: 2, medium: media[1], annotation: annotations[1] },
        { lecture: LECTURE_TITLE_1, index: 0, medium: media[0], annotation: annotations[0] },
      ];
      for (const { lecture, index, medium, annotation } of expected) {
        await overview.goto();
        const panel = await overview.openLecture(overview.ownAnnotations, lecture);

        const popup = await overview.open(overview.cards(panel).nth(index));

        await expect(popup).toHaveURL(new RegExp(`/media/${medium.id}/play`));
        await expectPlayerAt(popup, medium.id, annotation);
        await popup.close();
      }
    });
});

test.describe("a card of a student's annotation shared with the teacher", () => {
  async function sharedAnnotations(
    factory: FactoryBot, media: FactoryBotObject[], student: User,
  ): Promise<FactoryBotObject[]> {
    const shared = [];
    for (const medium of [media[0], media[0], media[2]]) {
      shared.push(await factory.create("annotation", ["with_text", "shared_with_teacher"], {
        medium_id: medium.id, user_id: student.id,
      }));
    }
    return shared;
  }

  test("has a border in the colour of the annotation's category, not its own",
    async ({ factory, teacher: { page, user }, student }) => {
      const { media } = await annotationScenario(factory, user, user.id);
      const shared = await sharedAnnotations(factory, media, student.user);
      const overview = new AnnotationsOverviewPage(page);
      await overview.goto();

      const expected: [string, FactoryBotObject[]][] = [
        [LECTURE_TITLE_2, [shared[2]]],
        [LECTURE_TITLE_1, [shared[1], shared[0]]],
      ];
      for (const [lecture, cards] of expected) {
        const panel = await overview.openLecture(overview.studentsAnnotations, lecture);
        for (const [i, annotation] of cards.entries()) {
          await expect(overview.frame(overview.cards(panel).nth(i)))
            .toHaveCSS("border-color", hexToRgb(CATEGORY_COLORS[annotation.category as string]));
        }
      }
    });

  test("opens the medium's feedback video at the annotation when clicked",
    async ({ factory, teacher: { page, user }, student }) => {
      const { media } = await annotationScenario(factory, user, user.id);
      const shared = await sharedAnnotations(factory, media, student.user);
      const overview = new AnnotationsOverviewPage(page);
      const expected = [
        { lecture: LECTURE_TITLE_2, index: 0, medium: media[2], annotation: shared[2] },
        { lecture: LECTURE_TITLE_1, index: 0, medium: media[0], annotation: shared[1] },
        { lecture: LECTURE_TITLE_1, index: 1, medium: media[0], annotation: shared[0] },
      ];
      for (const { lecture, index, medium, annotation } of expected) {
        await overview.goto();
        const panel = await overview.openLecture(overview.studentsAnnotations, lecture);

        const popup = await overview.open(overview.cards(panel).nth(index));

        await expect(popup).toHaveURL(new RegExp(`/media/${medium.id}/feedback`));
        await expectPlayerAt(popup, medium.id, annotation);
        await popup.close();
      }
    });
});
