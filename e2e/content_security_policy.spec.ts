import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { expect, test } from "./_support/fixtures";

declare global {
  interface Window {
    Turbo: { visit: (_path: string) => void };
    $: { ajaxSettings: { converters: Record<string, (_text: string) => string> } };
    scriptAnswerRan?: boolean;
  }
}

/**
 * Signing in through the form is a visit by Turbo: the document of the login
 * page stays, and with it the nonce of its policy, while the session changes
 * and later answers name another nonce. Script answers have to run with the
 * nonce of the document.
 */
test("runs script answers after signing in through the form",
  async ({ page, request, factory }) => {
    const medium = await factory.create("lesson_medium", ["with_video", "released"]);
    const user = await callBackend(request, "user_creator", { role: "student" }) as User;
    await page.goto("/users/sign_in");
    await page.getByLabel("Email").fill(user.email);
    await page.getByLabel("Password").fill(user.password);
    await page.getByRole("button", { name: "Login", exact: true }).click();
    await expect(page).not.toHaveURL(/sign_in/);

    // Like a click on a link, this keeps the document.
    await page.evaluate((path) => {
      window.Turbo.visit(path);
    }, `/media/${medium.id}/show_comments`);

    // The form arrives as a script answer to a request of rails-ujs.
    await page.getByRole("button", { name: "New Comment" }).click();
    await expect(page.getByTestId("comment-new-textarea")).toBeVisible();

    // jQuery passes the script answers to its requests through this converter.
    const ran = await page.evaluate(() => {
      window.$.ajaxSettings.converters["text script"]("window.scriptAnswerRan = true");
      return window.scriptAnswerRan;
    });
    expect(ran).toBe(true);
  });
