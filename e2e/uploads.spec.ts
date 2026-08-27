import { expect, test } from "./_support/fixtures";
import { attachToUploadArea } from "./_support/uploads";

const SUBMISSION_FORM = "form[data-controller~='submission-upload']";

// One test per place that uploads through Uppy. They all follow the same
// shape: hand over a file, see it named on the page, save, see it survive.
test.describe("uploading through Uppy", () => {
  test("a video on a medium", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Kaviar" });

    await page.goto(`/media/${medium.id}/edit`);
    await attachToUploadArea(page, "#video-uploadArea", "spec/files/talk.mp4");

    await expect(page.locator("#video-file")).toHaveText("talk.mp4");

    const saved = page.waitForResponse(`/media/${medium.id}`);
    await page.getByRole("button", { name: "Save" }).click();
    await saved;
    await page.waitForURL(`**/media/${medium.id}/edit`);

    await expect(page.locator("#video-file")).toHaveText("talk.mp4");
  });

  test("a geogebra applet on a medium", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "WorkedExample" });

    await page.goto(`/media/${medium.id}/edit`);
    await attachToUploadArea(page, "#geogebra-uploadArea", "spec/files/geogebra.ggb");

    await expect(page.locator("#geogebra-file")).toHaveText("geogebra.ggb");
  });

  test("a submission, once the assurance is given",
    async ({ factory, student: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      await factory.create("assignment", [], { lecture_id: lecture.id });
      await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Mo 10" });
      await factory.create("lecture_user_join", [], {
        lecture_id: lecture.id, user_id: user.id,
      });

      await page.goto(`/lectures/${lecture.id}/submissions`);
      await page.getByRole("button", { name: "create" }).click();
      await attachToUploadArea(page, SUBMISSION_FORM, "e2e/files/manuscript.pdf");

      const stored = page.locator("#userManuscriptMetadata");

      // Nothing is stored until the box about third-party rights is ticked.
      page.once("dialog", dialog => dialog.accept());
      await page.getByRole("button", { name: "Upload file" }).click();
      await expect(stored).toBeHidden();

      await page.getByRole("checkbox", { name: "I assure that" }).check();
      await page.getByRole("button", { name: "Upload file" }).click();

      await expect(stored).toContainText("manuscript.pdf");
    });

  test("a correction, once the deadline has passed",
    async ({ factory, student, tutor: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      const assignment = await factory.create("assignment", [], {
        lecture_id: lecture.id, deadline: "2020-01-01 12:00:00",
      });
      const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
        lecture_id: lecture.id, tutor_id: user.id, title: "Mo 10",
      });
      const submission = await factory.create("submission", ["with_manuscript"], {
        assignment_id: assignment.id, tutorial_id: tutorial.id, accepted: true,
      });
      await factory.create("user_submission_join", [], {
        submission_id: submission.id, user_id: student.user.id,
      });

      await page.goto(`/lectures/${lecture.id}/tutorials`);
      await page.getByRole("link", { name: "Upload" }).first().click();

      const form = "form.correction-upload";
      await attachToUploadArea(page, form, "e2e/files/manuscript.pdf");

      await expect(page.locator(`${form} [data-uppy-upload-target='metadata']`))
        .toContainText("manuscript.pdf");
    });

  test("a stack of corrections as one archive",
    async ({ factory, student, tutor: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      const assignment = await factory.create("assignment", [], {
        lecture_id: lecture.id, deadline: "2020-01-01 12:00:00",
      });
      const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
        lecture_id: lecture.id, tutor_id: user.id, title: "Mo 10",
      });
      const submission = await factory.create("submission", ["with_manuscript"], {
        assignment_id: assignment.id, tutorial_id: tutorial.id, accepted: true,
      });
      await factory.create("user_submission_join", [], {
        submission_id: submission.id, user_id: student.user.id,
      });

      await page.goto(`/lectures/${lecture.id}/tutorials`);
      const form = "#bulk-upload-form";
      await attachToUploadArea(page, form, "e2e/files/corrections.zip");

      await expect(page.locator("#upload-bulk-correction-metadata"))
        .toContainText("1 file(s) successfully uploaded");
      await expect(page.locator("#upload-bulk-correction-save")).toBeEnabled();
    });

  test("a profile picture", async ({ admin: { page } }) => {
    await page.goto("/administration/profile");
    await attachToUploadArea(page, "#image-uploadArea", "e2e/files/image.png");

    await expect(page.locator("#image-file")).toHaveText("image.png");
  });
});
