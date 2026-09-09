import { readFileSync } from "node:fs";

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

  test("a second video, without reloading the page in between",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
      const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
        { lecture_id: lecture.id, sort: "Kaviar" });

      await page.goto(`/media/${medium.id}/edit`);
      await attachToUploadArea(page, "#video-uploadArea", "spec/files/talk.mp4");
      await expect(page.locator("#video-file")).toHaveText("talk.mp4");

      await attachToUploadArea(page, "#video-uploadArea",
        { name: "second-talk.mp4", mimeType: "video/mp4",
          buffer: readFileSync("spec/files/talk.mp4") });

      await expect(page.locator("#video-file")).toHaveText("second-talk.mp4");
    });

  test("a rejected file, with the reason the server gave",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id, locale: "en" });
      const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
        { lecture_id: lecture.id, sort: "Kaviar" });

      let attempts = 0;
      await page.route("**/videos/upload*", (route) => {
        attempts += 1;
        return route.fulfill({
          status: 422, contentType: "text/plain; charset=utf-8",
          body: "The file is infected and was not stored.",
        });
      });

      const complaints: string[] = [];
      page.on("dialog", (dialog) => {
        complaints.push(dialog.message());
        void dialog.accept();
      });

      await page.goto(`/media/${medium.id}/edit`);
      await page.locator("#video-uploadArea input.uppy-Dashboard-input").first()
        .setInputFiles("spec/files/talk.mp4");

      // Said once, in the words the server used -- not twice, and not as Uppy's
      // guess that the network is broken.
      await expect(() => {
        expect(complaints).toEqual(
          [expect.stringContaining("The file is infected and was not stored.")],
        );
      }).toPass();
      // A verdict is not a hiccup: the file must not go through the scanner again.
      expect(attempts).toBe(1);
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

      const created = page.waitForResponse(response => response.request().method() !== "GET");
      await page.getByRole("button", { name: "Save" }).click();
      await created;
      await page.goto(`/lectures/${lecture.id}/submissions`);

      await expect(page.getByRole("link", { name: "Submission ↓" })).toBeVisible();
    });

  test("a submission, up to the moment the file is taken back out",
    async ({ factory, student: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      await factory.create("assignment", [], { lecture_id: lecture.id });
      await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Mo 10" });
      await factory.create("lecture_user_join", [], {
        lecture_id: lecture.id, user_id: user.id,
      });

      await page.goto(`/lectures/${lecture.id}/submissions`);
      await page.getByRole("button", { name: "create" }).click();
      const save = page.getByRole("button", { name: "Save" });
      await attachToUploadArea(page, SUBMISSION_FORM, "e2e/files/manuscript.pdf");

      await expect(save).toBeDisabled();

      await page.getByRole("button", { name: "Remove file" }).click();

      await expect(save).toBeEnabled();
      await expect(page.locator("#userManuscript-not-upload-notice")).toBeHidden();
    });

  test("a correction, once the deadline has passed",
    async ({ factory, student, tutor: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      // The trait rather than a date in the past: an assignment refuses a
      // deadline that has already gone by, and writes it afterwards instead.
      const assignment = await factory.create("assignment", ["expired"], {
        lecture_id: lecture.id,
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

      const stored = page.waitForResponse(response => response.url().includes("add_correction"));
      await page.getByRole("button", { name: "Save" }).click();
      await stored;
      await page.goto(`/lectures/${lecture.id}/tutorials`);
      await page.getByRole("link", { name: "Upload" }).first().click();

      await expect(page.locator(`${form} [data-uppy-upload-target='metadata']`))
        .toContainText("manuscript.pdf");
    });

  test("a stack of corrections, each named after its submission",
    async ({ factory, student, tutor: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      // The trait rather than a date in the past: an assignment refuses a
      // deadline that has already gone by, and writes it afterwards instead.
      const assignment = await factory.create("assignment", ["expired"], {
        lecture_id: lecture.id,
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
      await page.getByRole("button", { name: "Bulk upload of corrections" }).click();
      // Bulk upload assigns by filename: everything behind -ID- is the submission.
      await attachToUploadArea(page, "#bulk-upload-form", {
        name: `correction-ID-${submission.id}.pdf`,
        mimeType: "application/pdf",
        buffer: readFileSync("e2e/files/manuscript.pdf"),
      });

      const save = page.locator("#upload-bulk-correction-save");
      await expect(page.locator("#upload-bulk-correction-metadata"))
        .toContainText("1 file(s) successfully uploaded");
      await expect(save).toBeEnabled();

      await save.click();

      const saved = page.getByRole("row")
        .filter({ hasText: "Number of successfully saved corrections" })
        .getByRole("cell");
      await expect(saved).toHaveText("1");
    });

  test("a stack of corrections the tutor changes their mind about",
    async ({ factory, student, tutor: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      // The trait rather than a date in the past: an assignment refuses a
      // deadline that has already gone by, and writes it afterwards instead.
      const assignment = await factory.create("assignment", ["expired"], {
        lecture_id: lecture.id,
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
      await page.getByRole("button", { name: "Bulk upload of corrections" }).click();
      await attachToUploadArea(page, "#bulk-upload-form", "e2e/files/manuscript.pdf");

      const save = page.locator("#upload-bulk-correction-save");
      await expect(save).toBeEnabled();

      // Reopening the area must not offer to save what the tutor discarded.
      await page.getByRole("button", { name: "Cancel" }).click();
      await page.getByRole("button", { name: "Bulk upload of corrections" }).click();

      await expect(page.locator("#upload-bulk-correction-metadata")).toBeEmpty();
      await expect(page.locator("#upload-bulk-correction-hidden")).toHaveValue("");
      await expect(save).toBeDisabled();
    });

  test("a profile picture", async ({ admin: { page } }) => {
    await page.goto("/administration/profile");
    await attachToUploadArea(page, "#image-uploadArea", "e2e/files/image.png");

    await expect(page.locator("#image-file")).toHaveText("image.png");

    // Saving answers with JavaScript that reloads the page by itself.
    const reloaded = page.waitForResponse(response => response.request().method() === "GET"
      && response.url().endsWith("/administration/profile"));
    await page.getByRole("button", { name: "Save" }).first().click();
    await reloaded;

    await expect(page.locator("#image-file")).toHaveText("image.png");
    await expect(page.locator("#image-preview"))
      .toHaveAttribute("src", /\/users\/\d+\/image\/original/);
  });
});
