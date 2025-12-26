import { expect, test } from "./_support/fixtures";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

async function createLecturesWithCourses(factory: any, count: number, titlePrefix: string) {
  for (let i = 1; i <= count; i++) {
    const course = await factory.create("course", [], { title: `${titlePrefix} ${i}` });
    await factory.create("lecture", ["released_for_all"], { course_id: course.id });
  }
}

test("loads initial results when scrolling to search bar",
  async ({ factory, student: { page } }) => {
    await createLecturesWithCourses(factory, 5, "Course");

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
    await createLecturesWithCourses(factory, 50, "Sample Course");

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
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const algebraCourse = await factory.create("course", [], { title: "Linear Algebra" });
    await factory.create("lecture", ["released_for_all"], { course_id: algebraCourse.id });
    const mathCourse = await factory.create("course", [], { title: "Discrete Mathematics" });
    await factory.create("lecture", ["released_for_all"], { course_id: mathCourse.id });

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
