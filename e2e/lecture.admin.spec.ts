import { expect, test } from "./_support/fixtures";

test("can upload a manuscript and extract structure from it",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [],
      { teacher_id: user.id, content_mode: "manuscript" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"],
      { lecture_id: lecture.id, sort: "Script" });

    // Upload manuscript PDF
    await page.goto(`/media/${medium.id}/edit`);
    const fileChooserPromise = page.waitForEvent("filechooser");
    await page.getByTestId("manuscript-upload-file").click();
    const fileChooser = await fileChooserPromise;
    await fileChooser.setFiles("e2e/files/manuscript-mampfsty.pdf");
    await page.getByTestId("manuscript-upload").click();

    await expect(page.getByText("upload successful")).toBeVisible();
    await expect(page.getByText("manuscript-mampfsty.pdf")).toBeVisible();
    const saveRequestPromise = page.waitForResponse(`/media/${medium.id}`);
    await page.getByRole("button", { name: "Save" }).click();
    await saveRequestPromise;
    await page.waitForLoadState("networkidle");

    // Verify PDF structure extraction
    await expect(page.getByText(/structure of the manuscript/)).toBeVisible();
    await page.getByRole("button", { name: "Details" }).click();
    await expect(page.getByText("current version 2.12")).toBeVisible();
    const CHAPTER1 = "Chapter 1. Bla";
    const SECTION1 = "1.1. Blub";
    await expect(page.getByText(CHAPTER1)).toBeVisible();
    await expect(page.getByText(SECTION1)).toBeVisible();

    // Import the structure
    await page.getByLabel("Structure of the manuscript")
      .getByRole("button", { name: "Close" }).click();
    page.on("dialog", dialog => dialog.accept());
    const importRequestPromise = page.waitForResponse(`/media/${medium.id}/import_manuscript`);
    await page.getByRole("button", { name: "Import" }).click();
    await importRequestPromise;

    await page.goto(`/lectures/${lecture.id}/edit`);
    await expect(page.getByText(CHAPTER1)).toBeVisible();
    await page.getByText(SECTION1).click();
    await expect(page.getByText("Def. 1.1")).toBeVisible();
    await expect(page.getByText("Space")).toBeVisible();
  });
