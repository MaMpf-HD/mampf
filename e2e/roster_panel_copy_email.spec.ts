import { expect, test } from "./_support/fixtures";

const ADDRESS_BUTTON = { name: "Copy email address" };

test.describe("the roster panel's copy button", () => {
  test("puts the member's address on the clipboard",
    async ({ factory, student, teacher: { page, user } }) => {
      await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);

      const lecture = await factory.create("lecture", [], {
        teacher_id: user.id, locale: "en",
      });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10",
      });
      await tutorial.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByText("Mo 10").click();
      await page.getByRole("button", ADDRESS_BUTTON).click();

      const copied = await page.evaluate(() => navigator.clipboard.readText());
      expect(copied).toBe(student.user.email);
    });

  test("says so when the browser refuses the clipboard",
    async ({ factory, student, teacher: { page, user } }) => {
      await page.addInitScript(() => {
        Object.defineProperty(navigator, "clipboard", {
          value: { writeText: () => Promise.reject(new Error("denied")) },
        });
      });

      const lecture = await factory.create("lecture", [], {
        teacher_id: user.id, locale: "en",
      });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10",
      });
      await tutorial.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByText("Mo 10").click();
      await page.getByRole("button", ADDRESS_BUTTON).click();

      await expect(page.getByRole("status"))
        .toHaveText("The email address could not be copied.");
    });
});
