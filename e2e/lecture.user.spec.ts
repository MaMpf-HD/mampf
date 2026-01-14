import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

let lecturePage: LecturePage;

test.describe("section completion", () => {
  /* FIXME: this is not working for the last 2 tests */
  test.beforeEach(async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture", [
      "released_for_all",
      "with_toc",
    ]);
    lecturePage = new LecturePage(page, lecture.id);
    await lecturePage.goto();
    await lecturePage.subscribe();
  });

  test("are visible", async () => {
    const buttons = lecturePage.page.getByTestId("toggle-completion-button");
    await expect(buttons.first()).toBeVisible();
  });

  test("toggle to completed", async () => {
    const completionBefore = await lecturePage.getCompletionValue();

    await lecturePage.toggleSectionCompletion(0);
    const buttonToggled = await lecturePage.isNthSectionCompletionToggled(0);
    expect(buttonToggled).toBeTruthy();

    const completionAfter = await lecturePage.getCompletionValue();
    expect(completionAfter).toBeGreaterThan(completionBefore);
  });

  test("toggle to not completed", async () => {
    await lecturePage.toggleSectionCompletion(0);
    const completionBefore = await lecturePage.getCompletionValue();

    await lecturePage.toggleSectionCompletion(0);
    const buttonToggled = await lecturePage.isNthSectionCompletionToggled(0);
    expect(buttonToggled).toBeFalsy();

    const completionAfter = await lecturePage.getCompletionValue();
    expect(completionAfter).toBeLessThan(completionBefore);
  });
});

test.describe("assignment completion", () => {
  let lecture: any;
  let lecturePage: LecturePage;
  let assignment: any;

  test.beforeEach(async ({ factory, student: { page } }) => {
    lecture = await factory.create("lecture", ["released_for_all"]);
    assignment = await factory.create("assignment", [], { lecture_id: lecture.id });
    lecturePage = new LecturePage(page, lecture.id);
    await lecturePage.gotoAssignments();
    await lecturePage.subscribe();
  });

  test("progress bar is visible", async () => {
    const progressBar = lecturePage.page.getByRole("progressbar");
    await expect(progressBar).toBeVisible();
  });

  test("progress bar increases value on submission", async () => {
    // TODO: implement
  });

  test("updates value downwards", async () => {
    // TODO: implement
  });
});
