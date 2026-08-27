import { expect, test } from "./_support/fixtures";

test("copies a member's email address from the roster panel",
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

    await page.getByRole("button", { name: "Copy email address" }).click();

    const copied = await page.evaluate(() => navigator.clipboard.readText());
    expect(copied).toBe(student.user.email);
  });
