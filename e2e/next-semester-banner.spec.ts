/* eslint-disable @typescript-eslint/no-explicit-any */
import { expect, test } from "./_support/fixtures";
import { disableFeature, enableFeature } from "./_support/backend";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

/**
 * Tests for the (transitional) banner on the start page that announces the
 * lectures of the upcoming semester and deep-links into the pre-filtered
 * lecture search.
 */

async function createTermsWithLectures(factory: any) {
  const currentTerm = await factory.create("term", ["summer", "active"], { year: 2025 });
  const nextTerm = await factory.create("term", ["winter"], { year: 2025 });

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

  return { currentTerm, nextTerm };
}

test("shows the banner and leads to the next semester lecture search",
  async ({ request, factory, student: { page } }) => {
    await createTermsWithLectures(factory);
    await enableFeature(request, "next_semester_banner");

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.nextSemesterBanner).toBeVisible();
    await expect(dashboard.nextSemesterBanner).toContainText("WS 2025/26");

    await dashboard.clickNextSemesterBannerCta();
    expect(page.url()).toContain("semester=next");
    await expect(dashboard.nextSemesterFilter).toBeChecked();
    await expect(dashboard.results).toContainText("Topology Next");
    await expect(dashboard.results).not.toContainText("Topology Current");

    await disableFeature(request, "next_semester_banner");
  });

test("banner stays dismissed after a reload",
  async ({ request, factory, student: { page } }) => {
    await createTermsWithLectures(factory);
    await enableFeature(request, "next_semester_banner");

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.nextSemesterBanner).toBeVisible();
    await dashboard.dismissNextSemesterBanner();
    await expect(dashboard.nextSemesterBanner).not.toBeVisible();

    await page.reload();
    await expect(dashboard.nextSemesterBanner).not.toBeVisible();

    await disableFeature(request, "next_semester_banner");
  });

test("does not show the banner when the feature flag is disabled",
  async ({ request, factory, student: { page } }) => {
    await createTermsWithLectures(factory);
    await disableFeature(request, "next_semester_banner");

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.nextSemesterBanner).not.toBeVisible();
  });

test("deep-link with semester=current overrides the default filter",
  async ({ factory, student: { page } }) => {
    await createTermsWithLectures(factory);

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.gotoWithSemesterDeepLink("current");

    await expect(dashboard.currentSemesterFilter).toBeChecked();
    await expect(dashboard.nextSemesterFilter).not.toBeChecked();
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).not.toContainText("Topology Next");
  });
