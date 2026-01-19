import { expect, test } from "./_support/fixtures";
import { enableFeature } from "./_support/backend";
import { TalkPage } from "./page-objects/talk_page";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("Talk self rosterization", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "roster_maintenance");
    await enableFeature(request, "registration_campaigns");
  });

  test("should allow self-assign when validation passes",
    async ({ factory, student }) => {
      const seminar = await factory.create("lecture", ["released_for_all", "with_sparse_toc", "is_seminar"]);
      const talk = await factory.create("talk", [], { skip_campaigns: true, self_materialization_mode: "add_and_remove", lecture_id: seminar.id });
      await new LecturePage(student.page, seminar.id).subscribe();

      const talkPage = new TalkPage(student.page, talk.id);
      await talkPage.goto();
      let enrollButton = student.page.getByRole("link", { name: "person_add" });
      await expect(enrollButton).toBeVisible();
      await expect(enrollButton).toBeEnabled();
      let unenrollButton = student.page.getByRole("button", { name: "person_remove" });
      await expect(unenrollButton).toBeDisabled();

      await enrollButton.click();
      enrollButton = student.page.getByRole("button", { name: "person_add" });
      unenrollButton = student.page.getByRole("link", { name: "person_remove" });
      await expect(enrollButton).toBeDisabled();
      await expect(unenrollButton).toBeEnabled();
    });

  test("should not allow self-assign when self_materialization_mode is disabled",
    async ({ factory, student }) => {
      const seminar = await factory.create("lecture", ["released_for_all", "with_sparse_toc", "is_seminar"]);
      const talk = await factory.create("talk", [], { skip_campaigns: true, self_materialization_mode: "disabled", lecture_id: seminar.id });
      await new LecturePage(student.page, seminar.id).subscribe();

      const talkPage = new TalkPage(student.page, talk.id);
      await talkPage.goto();
      const enrollButton = student.page.getByRole("button", { name: "person_add" });
      await expect(enrollButton).toBeDisabled();
      const unenrollButton = student.page.getByRole("button", { name: "person_remove" });
      await expect(unenrollButton).toBeDisabled();
    });

  test("should not allow self-remove when self_materialization_mode is add_only",
    async ({ factory, student }) => {
      const seminar = await factory.create("lecture", ["released_for_all", "with_sparse_toc", "is_seminar"]);
      const talk = await factory.create("talk", [], { skip_campaigns: true, self_materialization_mode: "add_only", lecture_id: seminar.id });
      await new LecturePage(student.page, seminar.id).subscribe();

      const talkPage = new TalkPage(student.page, talk.id);
      await talkPage.goto();
      let enrollButton = student.page.getByRole("link", { name: "person_add" });
      await enrollButton.click();

      enrollButton = student.page.getByRole("button", { name: "person_add" });
      const unenrollButton = student.page.getByRole("button", { name: "person_remove" });
      await expect(enrollButton).toBeDisabled();
      await expect(unenrollButton).toBeDisabled();
    });

  test("should not allow self-remove when rosterable is locked",
    async ({ factory, student }) => {
      const seminar = await factory.create("lecture", ["released_for_all", "with_sparse_toc", "is_seminar"]);
      const talk = await factory.create("talk", [], { skip_campaigns: false, lecture_id: seminar.id });
      const campaign = await factory.create("registration_campaign", [], {
        campaignable_id: seminar.id,
        campaignable_type: "Lecture",
      });
      const item = await factory.create("registration_item", [], { registerable_id: talk.id, registerable_type: "Talk", registration_campaign_id: campaign.id });
      await new LecturePage(student.page, seminar.id).subscribe();

      const talkPage = new TalkPage(student.page, talk.id);
      await talkPage.goto();
      const enrollButton = student.page.getByRole("button", { name: "person_add" });
      await expect(enrollButton).toBeDisabled();
      const unenrollButton = student.page.getByRole("button", { name: "person_remove" });
      await expect(unenrollButton).toBeDisabled();
    });
});
