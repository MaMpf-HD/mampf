import { expect, test } from "./_support/fixtures";
import { disableFeature, enableFeature } from "./_support/backend";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

/**
 * Tests for the (transitional) banner on the start page that announces the
 * lectures of the upcoming term and deep-links into the pre-filtered
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

test("shows the banner and leads to the next term lecture search",
  async ({ request, factory, student: { page } }) => {
    await createTermsWithLectures(factory);
    await enableFeature(request, "next_term_banner");

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.nextTermBanner).toBeVisible();
    await expect(dashboard.nextTermBanner).toContainText("WS 2025/26");

    await dashboard.clickNextTermBannerCta();
    expect(page.url()).toContain("term_scope=next");
    await expect(dashboard.nextTermFilter).toBeChecked();
    await expect(dashboard.results).toContainText("Topology Next");
    await expect(dashboard.results).not.toContainText("Topology Current");

    await disableFeature(request, "next_term_banner");
  });

test("does not show the banner when the feature flag is disabled",
  async ({ request, factory, student: { page } }) => {
    await createTermsWithLectures(factory);
    await disableFeature(request, "next_term_banner");

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    await expect(dashboard.nextTermBanner).not.toBeVisible();
  });

test("deep-link with term_scope=current overrides the default filter",
  async ({ factory, student: { page } }) => {
    await createTermsWithLectures(factory);

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.gotoWithTermScopeDeepLink("current");

    await expect(dashboard.currentTermFilter).toBeChecked();
    await expect(dashboard.nextTermFilter).not.toBeChecked();
    await expect(dashboard.results).toContainText("Topology Current");
    await expect(dashboard.results).not.toContainText("Topology Next");
  });
