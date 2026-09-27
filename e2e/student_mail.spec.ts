import type { FactoryBot } from "./_support/factorybot";
import { expect, test } from "./_support/fixtures";

// Two groups, one member each; the count follows what is picked.
async function lectureWithTwoGroups(factory: FactoryBot, teacherId: number, tutorId: number) {
  const lecture = await factory.create("lecture", [], { teacher_id: teacherId });
  const monday = await factory.create("tutorial", ["with_tutor_by_id"], {
    lecture_id: lecture.id, title: "Mo 10", tutor_id: tutorId,
  });
  const tuesday = await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Tu 14" });
  const members = [[monday, "Ada Lovelace"], [tuesday, "Grace Hopper"]] as const;
  for (const [tutorial, name] of members) {
    const student = await factory.create("confirmed_user", [], { name_in_tutorials: name });
    await factory.create("lecture_membership", [], { lecture_id: lecture.id, user_id: student.id });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.id,
    });
  }
  return { lecture, monday };
}

test.describe("email to students", () => {
  test("the staff pick the groups and the send button counts along",
    async ({ factory, teacher, tutor }) => {
      const { lecture } = await lectureWithTwoGroups(factory, teacher.user.id, tutor.user.id);
      const { page } = teacher;

      await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
      await expect(page.getByRole("button", { name: "Send to 2 students" })).toBeEnabled();
      await expect(page.getByRole("checkbox", { name: /Mo 10/ })).toBeHidden();

      await page.getByRole("radio", { name: "Groups picked" }).check();
      await expect(page.getByRole("button", { name: "Send" })).toBeDisabled();
      await page.getByRole("checkbox", { name: /Mo 10/ }).check();
      await expect(page.getByRole("button", { name: "Send to 1 student" })).toBeEnabled();
      // the section's own box takes the rest, and says so
      await page.getByRole("checkbox", { name: "Tutorials · all" }).check();
      await expect(page.getByRole("checkbox", { name: /Tu 14/ })).toBeChecked();
      await expect(page.getByRole("button", { name: "Send to 2 students" })).toBeVisible();

      await page.getByLabel("Subject").fill("Room change");
      await page.getByLabel("Message").fill("We meet in room 3 from now on.");
      await page.getByRole("button", { name: "Send to 2 students" }).click();

      await expect(page.getByText("Your message is being sent to 2 students.")).toBeVisible();
      const sent = page.getByRole("row", { name: /Room change/ });
      await expect(sent).toContainText("Mo 10 and Tu 14");
      await expect(sent).toContainText("2 recipients");
    });

  test("keeps an attachment above the limit in the browser",
    async ({ factory, teacher, tutor }) => {
      const { lecture } = await lectureWithTwoGroups(factory, teacher.user.id, tutor.user.id);
      const { page } = teacher;
      const sent: string[] = [];
      page.on("request", (request) => {
        if (request.method() !== "GET" && request.url().includes("/student_messages")) {
          sent.push(request.url());
        }
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
      await page.getByLabel("Subject").fill("Program");
      await page.getByLabel("Message").fill("The program is attached.");
      const attachment = page.getByLabel("Attachment (optional)");
      await attachment.setInputFiles({
        name: "program.pdf", mimeType: "application/pdf",
        buffer: Buffer.alloc(10 * 1024 * 1024 + 1, "%"),
      });
      await page.getByRole("button", { name: "Send to 2 students" }).click();

      await expect(attachment)
        .toHaveJSProperty("validationMessage", "The file is larger than 10 MB.");
      expect(sent).toHaveLength(0);
    });

  test("a tutor writes to their own group from the page they grade it on",
    async ({ factory, teacher, tutor }) => {
      const { lecture, monday } = await lectureWithTwoGroups(factory, teacher.user.id,
        tutor.user.id);
      await factory.create("assignment", ["expired"], { lecture_id: lecture.id });
      const { page } = tutor;

      await page.goto(`/lectures/${lecture.id}/tutorials?tutorial=${monday.id}`);
      await page.getByRole("button", { name: "Email the group" }).click();

      const dialog = page.getByRole("dialog", { name: "Email to Mo 10" });
      // the modal's focus trap must not keep the addresses from the clipboard
      await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
      await dialog.getByRole("button", { name: "Copy email addresses" }).click();
      await expect(dialog.getByRole("status")).toHaveText("Addresses copied to clipboard");
      expect(await page.evaluate(() => navigator.clipboard.readText())).toContain("@");

      await dialog.getByLabel("Subject").fill("Next week");
      await dialog.getByLabel("Message").fill("No session next week.");
      await dialog.getByRole("button", { name: "Send to 1 student" }).click();

      await expect(page.getByText("Your message is being sent to 1 student.")).toBeVisible();
      await page.getByRole("button", { name: "Email the group" }).click();
      await expect(page.getByRole("dialog", { name: "Email to Mo 10" })
        .getByRole("row", { name: /Next week/ })).toBeVisible();

      // The lecture's page lists the staff's messages, not a tutor's.
      await teacher.page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
      await expect(teacher.page.getByText("Sent messages")).toHaveCount(0);
    });
});
