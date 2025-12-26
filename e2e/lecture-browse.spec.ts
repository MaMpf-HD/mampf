import { expect, test } from "./_support/fixtures";
import { DashboardPage } from "./page-objects/dashboard_page";

async function createLecturesWithCourses(factory: any, count: number, titlePrefix: string) {
  for (let i = 1; i <= count; i++) {
    const course = await factory.create("course", [], { title: `${titlePrefix} ${i}` });
    await factory.create("lecture", ["released_for_all"], { course_id: course.id });
  }
}

test("loads initial results when scrolling to search bar",
  async ({ factory, student: { page } }) => {
    await createLecturesWithCourses(factory, 5, "Course");

    const dashboard = new DashboardPage(page);
    await dashboard.goto();

    await expect(dashboard.results).not.toBeVisible();
    await dashboard.scrollToSearchAndWaitForResults();
    await expect(dashboard.results).toBeVisible();
    await expect(dashboard.results).toContainText("Course 1");
    await expect(dashboard.results).toContainText("Course 5");
  });

test("loads more results when scrolling to bottom",
  async ({ factory, student: { page } }) => {
    await createLecturesWithCourses(factory, 25, "Test Course");

    const dashboard = new DashboardPage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();
    await expect(dashboard.results).toBeVisible();

    const initialCount = await dashboard.getLectureCardCount();
    expect(initialCount).toBeGreaterThan(0);
    await dashboard.scrollToBottom();
    const finalCount = await dashboard.getLectureCardCount();
    expect(finalCount).toBeGreaterThan(initialCount);
  });

test("filters results based on search input",
  async ({ factory, student: { page } }) => {
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const algebraCourse = await factory.create("course", [], { title: "Linear Algebra" });
    await factory.create("lecture", ["released_for_all"], { course_id: algebraCourse.id });
    const mathCourse = await factory.create("course", [], { title: "Discrete Mathematics" });
    await factory.create("lecture", ["released_for_all"], { course_id: mathCourse.id });

    const dashboard = new DashboardPage(page);
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

test("resets pagination when performing new search",
  async ({ factory, student: { page } }) => {
    await createLecturesWithCourses(factory, 20, "Calculus");

    const topologyCourse = await factory.create("course", [], { title: "Unique Topology Course" });
    await factory.create("lecture", ["released_for_all"], { course_id: topologyCourse.id });

    const dashboard = new DashboardPage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();
    await dashboard.scrollToBottom();

    const initialCount = await dashboard.getLectureCardCount();
    expect(initialCount).toBeGreaterThan(10);

    await dashboard.searchFor("Topology");
    await expect(dashboard.results).toContainText("Topology");
    const filteredCount = await dashboard.getLectureCardCount();
    expect(filteredCount).toBe(1);
  });
