import { Page } from "./fixtures";

/** A path below the repository root, or a file made up on the spot. */
type UploadFile = string | { name: string; mimeType: string; buffer: Buffer };

/**
 * Hands a file to the Uppy drop zone inside the given area. Uppy hides its own
 * file input, so no file chooser ever opens; the caller asserts what the page
 * should show once the upload has landed.
 */
export async function attachToUploadArea(page: Page, area: string, file: UploadFile) {
  await page.locator(`${area} input.uppy-Dashboard-input`).first().setInputFiles(file);
  await page.waitForLoadState("networkidle");
}
