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
    const { currentTerm } = await createLectureSearchTerms(factory);
    await createLecturesWithCourses(factory, 5, "Course", currentTerm.id);

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
    const { currentTerm } = await createLectureSearchTerms(factory);
    await createLecturesWithCourses(factory, 50, "Sample Course", currentTerm.id);

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

test("does not duplicate cards when scrolling triggers overlapping page loads",
  async ({ factory, student: { page } }) => {
    const { currentTerm } = await createLectureSearchTerms(factory);
    await createLecturesWithCourses(factory, 60, "Rapid Course", currentTerm.id);

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();

    // Continuously fire synthetic scroll events (dispatching one does not
    // actually move the viewport) while we scroll to the bottom repeatedly.
    // This provokes the race where a page is requested again before its
    // predecessor's turbo-stream response has updated the "next page"
    // marker, which used to duplicate that page's cards.
    await page.evaluate(() => {
      setInterval(() => window.dispatchEvent(new Event("scroll")), 3);
    });

    for (let i = 0; i < 8; i++) {
      const responsePromise = dashboard.getLectureSearchPromise()
        .catch(() => null);
      await page.evaluate(() => {
        window.scrollTo(0, document.body.scrollHeight);
      });
      const response = await Promise.race([
        responsePromise,
        page.waitForTimeout(3000).then(() => null),
      ]);
      if (!response) break; // no more pages to load
    }
    await page.waitForTimeout(300);

    const hrefs = await dashboard.getLectureCardHrefs();
    const duplicates = hrefs.filter((href, index) => hrefs.indexOf(href) !== index);
    expect(duplicates).toEqual([]);
  });

test("filters results based on search input",
  async ({ factory, student: { page } }) => {
    const { currentTerm } = await createLectureSearchTerms(factory);
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: calculusCourse.id,
      term_id: currentTerm.id,
    });
    const algebraCourse = await factory.create("course", [], { title: "Linear Algebra" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: algebraCourse.id,
      term_id: currentTerm.id,
    });
    const mathCourse = await factory.create("course", [], { title: "Discrete Mathematics" });
    await factory.create("lecture", ["released_for_all"], {
      course_id: mathCourse.id,
      term_id: currentTerm.id,
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

test("scopes results to the semester picked in the dropdown",
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
    const termIndependentCourse = await factory.create("course", ["term_independent"], {
      title: "Topology Independent",
    });
    await factory.create("lecture", ["term_independent", "released_for_all"], {
      course_id: termIndependentCourse.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);

    // default: the active term (plus term-independent lectures)
    await dashboard.goto();
    await dashboard.scrollToSearchAndWaitForResults();
    await dashboard.searchFor("Topology");
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).toContainText("Topology Independent");
    await expect(dashboard.results).not.toContainText("Topology Next");

    // pick the upcoming semester: the sections and the search refresh in
    // place, without navigating away or jumping the scroll position
    const scrollBefore = await page.evaluate(() => window.scrollY);
    const searchReloaded = dashboard.getLectureSearchPromise();
    await dashboard.selectTerm("WS 2025/26");
    await searchReloaded;

    const scrollAfter = await page.evaluate(() => window.scrollY);
    expect(Math.abs(scrollAfter - scrollBefore)).toBeLessThan(5);

    await expect(dashboard.results).toContainText("Topology Next");
    await expect(dashboard.results).toContainText("Topology Independent");
    await expect(dashboard.results).not.toContainText("Topology Current");

    // a shared ?term=<slug> link lands on the same scope
    await dashboard.gotoTerm("WS25-26");
    await dashboard.scrollToSearchAndWaitForResults();
    await dashboard.searchFor("Topology");
    await expect(dashboard.results).toContainText("Topology Next");
    await expect(dashboard.results).not.toContainText("Topology Current");
  });
