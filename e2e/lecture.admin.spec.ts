import { expect, test } from "./_support/fixtures";
import { attachToUploadArea } from "./_support/uploads";

test("can upload a manuscript and extract structure from it",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [],
      { teacher_id: user.id, content_mode: "manuscript", locale: "en" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Script" });

    // Upload manuscript PDF
    await page.goto(`/media/${medium.id}/edit`);
    await attachToUploadArea(page, "#manuscript-uploadArea",
      "e2e/files/manuscript-mampfsty.pdf");

    await expect(page.getByText("manuscript-mampfsty.pdf")).toBeVisible();
    await expect(page.locator("#manuscript-pages")).toHaveText(/^\d+ p$/);
    const saveRequestPromise = page.waitForResponse(`/media/${medium.id}`);
    await page.getByRole("button", { name: "Save" }).click();
    await saveRequestPromise;
    await page.waitForURL(`**/media/${medium.id}/edit`);
    await page.waitForLoadState("networkidle");

    // Verify PDF structure extraction
    const CHAPTER1 = "Chapter 1. Bla";
    const SECTION1 = "1.1. Blub";
    // The analysis re-renders this area, and a dialog opened just before that
    // is thrown away with it, so the click is repeated until one sticks.
    const structure = page.getByLabel("Structure of the manuscript");
    await expect(async () => {
      await page.getByRole("button", { name: "Details" }).click();
      await expect(structure).toBeVisible({ timeout: 1000 });
    }).toPass();
    await expect(structure.getByText("current version 2.12")).toBeVisible();
    await expect(page.getByText(CHAPTER1)).toBeVisible();
    await expect(page.getByText(SECTION1)).toBeVisible();

    // Import the structure
    await page.getByLabel("Structure of the manuscript")
      .getByRole("button", { name: "Close" }).click();
    page.on("dialog", dialog => dialog.accept());
    const importRequestPromise = page.waitForResponse(`/media/${medium.id}/import_manuscript`);
    const importRedirectPromise = page.waitForURL(`/media/${medium.id}/edit`);
    await page.getByRole("button", { name: "Import" }).click();
    await importRequestPromise;
    await importRedirectPromise;

    await page.goto(`/lectures/${lecture.id}/edit`);
    await expect(page.getByText(CHAPTER1)).toBeVisible();
    await page.getByRole("link", { name: SECTION1 }).click();
    await expect(page.getByText("§1.1")).toBeVisible();
    await expect(page.getByText("Blub", { exact: true })).toBeVisible();
    await expect(page.getByText("Space")).toBeVisible();
  });
