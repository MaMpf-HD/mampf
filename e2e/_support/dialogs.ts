import { expect, Locator } from "./fixtures";

/**
 * Waits until a Bootstrap modal has finished its opening animation.
 * Bootstrap ignores closing (e.g. via Escape or Cancel) and some other
 * interactions until then.
 */
export async function expectDialogOpened(dialog: Locator) {
  await expect(dialog.getByRole("document")).toHaveCSS("transform", "none");
}
