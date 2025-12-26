import { expect, test } from "./_support/fixtures";

test("loads initial results when scrolling to search bar",
  async ({ factory, student: { page } }) => {
    const courses = [];
    for (let i = 1; i <= 5; i++) {
      courses.push(await factory.create("course", [], { title: `Course ${i}` }));
    }
    for (const course of courses) {
      await factory.create("lecture", ["released_for_all"], { course_id: course.id });
    }

    await page.goto("/");
    await expect(page.locator("#lecture-search-results")).not.toBeVisible();

    const lectureSearchPromise = page.waitForResponse(response =>
      response.url().includes("lectures/search"),
    );
    await page.locator("#lecture-search").scrollIntoViewIfNeeded();
    await lectureSearchPromise;

    await expect(page.locator("#lecture-search-results")).toBeVisible();
    await expect(page.locator("#lecture-search-results")).toContainText("Course 1");
    await expect(page.locator("#lecture-search-results")).toContainText("Course 5");
  });

test("loads more results when scrolling to bottom",
  async ({ factory, student: { page } }) => {
    const courses = [];
    for (let i = 1; i <= 25; i++) {
      courses.push(await factory.create("course", [], { title: `Test Course ${i}` }));
    }
    for (const course of courses) {
      await factory.create("lecture", ["released_for_all"], { course_id: course.id });
    }

    await page.goto("/");
    await page.locator("#lecture-search").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);

    await expect(page.locator("#lecture-search-results")).toBeVisible();
    const initialCount = await page.locator("#lecture-search-results .lecture-card").count();

    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await page.waitForTimeout(500);

    const finalCount = await page.locator("#lecture-search-results .lecture-card").count();
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

    await page.goto("/");
    await page.locator("#lecture-search").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);

    await expect(page.locator("#lecture-search-results")).toContainText("Calculus");
    await expect(page.locator("#lecture-search-results")).toContainText("Algebra");
    await expect(page.locator("#lecture-search-results")).toContainText("Mathematics");

    await page.locator("#lecture-search-bar").fill("Algebra");
    await page.waitForTimeout(400);

    await expect(page.locator("#lecture-search-results")).toContainText("Algebra");
    await expect(page.locator("#lecture-search-results")).not.toContainText("Calculus");
    await expect(page.locator("#lecture-search-results")).not.toContainText("Mathematics");
  });

test("resets pagination when performing new search",
  async ({ factory, student: { page } }) => {
    const courses = [];
    for (let i = 1; i <= 20; i++) {
      courses.push(await factory.create("course", [], { title: `Calculus ${i}` }));
    }
    for (const course of courses) {
      await factory.create("lecture", ["released_for_all"], { course_id: course.id });
    }

    const topologyCourse = await factory.create("course", [], { title: "Unique Topology Course" });
    await factory.create("lecture", [], { course_id: topologyCourse.id });

    await page.goto("/");
    await page.locator("#lecture-search").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);

    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await page.waitForTimeout(500);

    const initialCount = await page.locator("#lecture-search-results .lecture-card").count();
    expect(initialCount).toBeGreaterThan(10);

    await page.locator("#lecture-search-bar").fill("Topology");
    await page.waitForTimeout(400);

    await expect(page.locator("#lecture-search-results")).toContainText("Topology");
    const filteredCount = await page.locator("#lecture-search-results .lecture-card").count();
    expect(filteredCount).toBe(1);
  });
