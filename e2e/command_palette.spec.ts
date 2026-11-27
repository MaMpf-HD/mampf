import { expect, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";
import { CommandPalette } from "./page-objects/command_palette";

async function createLecture(factory: FactoryBot, attributes: object = {}) {
  const course = await factory.create("course", [], {
    title: "Advanced Calculus", short_title: "AdvCalc",
  });
  return await factory.create("lecture", ["released_for_all"], {
    course_id: course.id, ...attributes,
  });
}

test.describe("command palette", () => {
  test("opens with Ctrl+K and jumps to a page in a lecture",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory);
      await factory.create("lecture_bookmark", [],
        { lecture_id: lecture.id, user_id: user.id });
      const palette = new CommandPalette(page);

      await palette.goto("/");
      await page.keyboard.press("Control+k");
      await expect(palette.dialog).toBeVisible();
      await page.keyboard.press("Escape");
      await expect(palette.dialog).toBeHidden();

      await page.keyboard.press("Control+k");
      await palette.input.fill("advcalc exercises");
      await expect(palette.firstOption).toHaveAccessibleName(/^Exercises\s*AdvCalc/);
      await page.keyboard.press("Enter");
      await expect(page).toHaveURL(`/lectures/${lecture.id}/exercises`);
    });

  test("finds the user's own lectures in German as well",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory);
      await factory.create("lecture_bookmark", [],
        { lecture_id: lecture.id, user_id: user.id });
      const palette = new CommandPalette(page);

      await palette.goto("/");
      await palette.search("übungen adv");
      await expect(palette.option(/^Exercises\s*AdvCalc/)).toBeVisible();
    });

  test.describe("'homework' leads to a page depending on the role", () => {
    test("a student gets to the submissions",
      async ({ factory, student: { page, user } }) => {
        const lecture = await createLecture(factory);
        await factory.create("lecture_bookmark", [],
          { lecture_id: lecture.id, user_id: user.id });
        const palette = new CommandPalette(page);

        await palette.goto("/");
        await palette.search("advcalc homework");
        await expect(palette.firstOption).toHaveAccessibleName(/^Submissions/);
        await palette.chooseActive();
        await expect(page).toHaveURL(`/lectures/${lecture.id}/submissions`);
      });

    test("a tutor gets to the tutorials",
      async ({ factory, tutor: { page, user } }) => {
        const lecture = await createLecture(factory);
        await factory.create("tutorial", ["with_tutor_by_id"],
          { lecture_id: lecture.id, tutor_id: user.id });
        const palette = new CommandPalette(page);

        await palette.goto("/");
        await palette.search("advcalc homework");
        await expect(palette.firstOption).toHaveAccessibleName(/^Tutorials/);
        await palette.chooseActive();
        await expect(page).toHaveURL(`/lectures/${lecture.id}/tutorials`);
      });

    test("a teacher gets to the assessments on the edit page",
      async ({ factory, teacher: { page, user } }) => {
        const lecture = await createLecture(factory, { teacher_id: user.id });
        const palette = new CommandPalette(page);

        await palette.goto("/");
        await palette.search("advcalc homework");
        await expect(palette.firstOption).toHaveAccessibleName(/^Assessments/);
        await palette.chooseActive();
        await expect(page).toHaveURL(`/lectures/${lecture.id}/edit?tab=assessments`);
      });
  });

  test("prefers the lecture of the current semester over older ones of the course",
    async ({ factory, teacher: { page, user } }) => {
      const course = await factory.create("course", [], {
        title: "Advanced Calculus", short_title: "AdvCalc",
      });
      const older = await factory.create("term", ["winter"], { year: 2021 });
      const current = await factory.create("term", ["summer", "active"], { year: 2025 });
      for (const term of [older, current]) {
        await factory.create("lecture", ["released_for_all"],
          { course_id: course.id, term_id: term.id, teacher_id: user.id });
      }
      const palette = new CommandPalette(page);

      await palette.goto("/");
      await palette.search("advcalc groups");
      await expect(palette.firstOption).toHaveAccessibleName(/^Groups\s*AdvCalc SS 25/);
    });

  test("prefers lectures the student holds a place in over bookmarked ones",
    async ({ factory, student: { page, user } }) => {
      const bookmarked = await factory.create("course", [], {
        title: "Topology", short_title: "Topo",
      });
      const bookmarkedLecture = await factory.create("lecture", ["released_for_all"],
        { course_id: bookmarked.id });
      await factory.create("lecture_bookmark", [],
        { lecture_id: bookmarkedLecture.id, user_id: user.id });
      const enrolledLecture = await createLecture(factory);
      await factory.create("lecture_membership", [],
        { lecture_id: enrolledLecture.id, user_id: user.id });
      const palette = new CommandPalette(page);

      await palette.goto("/");
      await palette.search("submissions");
      await expect(palette.firstOption).toHaveAccessibleName(/^Submissions\s*AdvCalc/);
    });

  test("lists visited lectures under 'Recently visited'",
    async ({ factory, student: { page } }) => {
      const lecture = await createLecture(factory);
      const palette = new CommandPalette(page);

      await palette.goto(`/lectures/${lecture.id}`);
      await palette.goto("/");
      await palette.open();
      await expect(palette.group("Recently visited")
        .getByRole("option", { name: /^AdvCalc/ })).toBeVisible();
    });

  test("lists other published lectures, but neither their pages nor unpublished ones",
    async ({ factory, student: { page } }) => {
      const course = await factory.create("course", [], {
        title: "Topology", short_title: "Topo",
      });
      const lecture = await factory.create("lecture", ["released_for_all"],
        { course_id: course.id });
      const hidden = await factory.create("course", [], {
        title: "Secret Seminar", short_title: "Secret",
      });
      await factory.create("lecture", [], { course_id: hidden.id });
      const palette = new CommandPalette(page);

      await palette.goto("/");
      await palette.search("topo");
      await expect(palette.option(/^Topo/)).toBeVisible();

      await palette.search("topo exercises");
      await expect(palette.option(/^Exercises\s*Topo/)).toHaveCount(0);

      await palette.search("secret");
      await expect(palette.dialog.getByText("Nothing found.")).toBeVisible();

      await palette.search("topology");
      await palette.chooseActive();
      await expect(page).toHaveURL(`/lectures/${lecture.id}`);
    });

  test("pins and unpins the open lecture",
    async ({ factory, student: { page } }) => {
      const lecture = await createLecture(factory);
      const palette = new CommandPalette(page);
      const pin = palette.option("Pin AdvCalc");
      const unpin = palette.option("Unpin AdvCalc");
      const favorite = palette.group("Favorites").getByRole("option", { name: /^AdvCalc/ });

      await palette.goto(`/lectures/${lecture.id}`);
      await palette.open();
      await pin.click();
      await expect(page.getByText("AdvCalc pinned.")).toBeVisible();

      await palette.open();
      await expect(favorite).toBeVisible();
      await unpin.click();
      await expect(page.getByText("AdvCalc unpinned.")).toBeVisible();

      await palette.open();
      await expect(pin).toBeVisible();
      await expect(favorite).toHaveCount(0);
    });
});
