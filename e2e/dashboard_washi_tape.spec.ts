import { expect, Page, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

async function createLecture(factory: FactoryBot, attributes: Record<string, unknown> = {}) {
  const term = await factory.create("term", ["summer", "active"], { year: 2025 });
  return factory.create("lecture", ["released_for_all"], { term_id: term.id, ...attributes });
}

/** Picks "Mint" on the lecture's card and checks that it survives a reload. */
async function expectColorKeptAcrossReload(page: Page, lectureId: number) {
  const dashboard = new DashboardLectureBrowsePage(page);
  await dashboard.goto();
  const card = dashboard.dashboardCard(lectureId);

  await dashboard.chooseWashiTapeColor(lectureId, "Mint");
  await expect(card).toHaveAttribute("style", /--washi-tape-color-mint/);

  await page.reload();
  await expect(card).toHaveAttribute("style", /--washi-tape-color-mint/);
  await dashboard.openWashiTapePicker(lectureId);
  await expect(card.getByRole("radio", { name: "Mint" })).toBeChecked();
}

test.describe("washi tape", () => {
  test.describe("keeps a picked color across a reload on the card of", () => {
    test("a bookmarked lecture", async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory);
      await factory.create("lecture_bookmark", [], {
        lecture_id: lecture.id,
        user_id: user.id,
      });

      await expectColorKeptAcrossReload(page, lecture.id);
    });

    test("a lecture shown only through a pending registration",
      async ({ factory, student: { page, user } }) => {
        const lecture = await createLecture(factory);
        const campaign = await factory.create("registration_campaign", ["open"], {
          campaignable_type: "Lecture",
          campaignable_id: lecture.id,
        });
        const items = await campaign.__call("registration_items");
        await factory.create("registration_user_registration", ["pending"], {
          user_id: user.id,
          registration_campaign_id: campaign.id,
          registration_item_id: items[0].id,
        });

        await expectColorKeptAcrossReload(page, lecture.id);
      });

    test("a lecture the user teaches", async ({ factory, teacher: { page, user } }) => {
      const lecture = await createLecture(factory, { teacher_id: user.id });

      await expectColorKeptAcrossReload(page, lecture.id);
    });

    test("a lecture the user tutors", async ({ factory, tutor: { page, user } }) => {
      const lecture = await createLecture(factory);
      await factory.create("tutorial", [], {
        lecture_id: lecture.id,
        tutor_ids: [user.id],
      });

      await expectColorKeptAcrossReload(page, lecture.id);
    });
  });

  test("puts the saved color back when the server refuses a new one",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory);
      await factory.create("lecture_bookmark", [], {
        lecture_id: lecture.id,
        user_id: user.id,
      });

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();
      const card = dashboard.dashboardCard(lecture.id);
      await dashboard.chooseWashiTapeColor(lecture.id, "Mint");

      await page.route("**/dashboard/lectures/*/washi_tape", route => route.fulfill({ status: 500 }));
      const refused = page.waitForResponse(response =>
        response.url().endsWith("/washi_tape"));
      await card.getByRole("radio", { name: "Mint" }).focus();
      await page.keyboard.press("ArrowLeft");
      await refused;

      await expect(card).toHaveAttribute("style", /--washi-tape-color-mint/);
      await expect(card.getByRole("radio", { name: "Mint" })).toBeChecked();
    });
});
