import { expect, test } from "./_support/fixtures";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

async function createLectureSearchTerms(factory: any) {
  const currentTerm = await factory.create("term", ["summer", "active"], { year: 2025 });
  const nextTerm = await factory.create("term", ["winter"], { year: 2025 });

  return { currentTerm, nextTerm };
}

async function createLecturesWithCourses(
  factory: any,
  count: number,
  titlePrefix: string,
  termId: number,
) {
  for (let i = 1; i <= count; i++) {
    const course = await factory.create("course", [], { title: `${titlePrefix} ${i}` });
    await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: termId,
    });
  }
}

test("loads initial results when scrolling to search bar",
  async ({ factory, student: { page } }) => {
    const { nextTerm } = await createLectureSearchTerms(factory);
    await createLecturesWithCourses(factory, 5, "Course", nextTerm.id);

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.results).not.toBeVisible();
    await dashboard.scrollToSearchAndWaitForResults();
    await expect(dashboard.results).toBeVisible();
    await expect(dashboard.results).toContainText("Course 1");
    await expect(dashboard.results).toContainText("Course 5");
  });

test("loads more results when scrolling to bottom (even multiple times)",
  async ({ factory, student: { page } }) => {
    const { nextTerm } = await createLectureSearchTerms(factory);
    await createLecturesWithCourses(factory, 50, "Sample Course", nextTerm.id);

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();
    await expect(dashboard.results).toBeVisible();

    const firstCount = await dashboard.getLectureCardCount();
    expect(firstCount).toBeGreaterThan(0);

    await dashboard.scrollToBottom();
    const secondCount = await dashboard.getLectureCardCount();
    expect(secondCount).toBeGreaterThan(firstCount);

    await dashboard.scrollToBottom();
    const thirdCount = await dashboard.getLectureCardCount();
    expect(thirdCount).toBeGreaterThan(secondCount);
  });

test("filters results based on search input",
  async ({ factory, student: { page } }) => {
    const { nextTerm } = await createLectureSearchTerms(factory);
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: calculusCourse.id,
      term_id: nextTerm.id,
    });
    const algebraCourse = await factory.create("course", [], { title: "Linear Algebra" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: algebraCourse.id,
      term_id: nextTerm.id,
    });
    const mathCourse = await factory.create("course", [], { title: "Discrete Mathematics" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: mathCourse.id,
      term_id: nextTerm.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();

    await expect(dashboard.results).toContainText("Calculus");
    await expect(dashboard.results).toContainText("Algebra");
    await expect(dashboard.results).toContainText("Mathematics");

    await dashboard.searchFor("Algebra");
    await expect(dashboard.results).toContainText("Algebra");
    await expect(dashboard.results).not.toContainText("Calculus");
    await expect(dashboard.results).not.toContainText("Mathematics");
  });

test("filters results by selected semester",
  async ({ factory, student: { page } }) => {
    const { currentTerm, nextTerm } = await createLectureSearchTerms(factory);
    const currentCourse = await factory.create("course", [], { title: "Topology Current" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: currentCourse.id,
      term_id: currentTerm.id,
    });
    const nextCourse = await factory.create("course", [], { title: "Topology Next" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: nextCourse.id,
      term_id: nextTerm.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();

    await expect(dashboard.nextSemesterFilter).toBeChecked();

    await dashboard.searchFor("Topology");
    await expect(dashboard.results).toContainText("Topology Next");
    await expect(dashboard.results).not.toContainText("Topology Current");

    await dashboard.clearNextSemester();
    await expect(dashboard.nextSemesterFilter).not.toBeChecked();
    await expect(dashboard.currentSemesterFilter).not.toBeChecked();
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).toContainText("Topology Next");

    await dashboard.selectCurrentSemester();
    await expect(dashboard.currentSemesterFilter).toBeChecked();
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).not.toContainText("Topology Next");

    await dashboard.clearCurrentSemester();
    await expect(dashboard.currentSemesterFilter).not.toBeChecked();
    await expect(dashboard.nextSemesterFilter).not.toBeChecked();
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).toContainText("Topology Next");
  });
