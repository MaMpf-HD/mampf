import { expect, test } from "./_support/fixtures";
import { FactoryBot } from "./_support/factorybot";

async function groupWithMember(factory: FactoryBot, tutorId: number) {
  const lecture = await factory.create("lecture", ["released_for_all"]);
  const monday = await factory.create("tutorial", ["with_tutor_by_id"], {
    lecture_id: lecture.id, title: "Mo 10", tutor_id: tutorId,
  });
  const tuesday = await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Tu 14" });
  for (const [tutorial, name] of [[monday, "Ada Lovelace"], [tuesday, "Grace Hopper"]] as const) {
    const student = await factory.create("confirmed_user", [], { name_in_tutorials: name });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.id,
    });
  }
  return { lecture, monday };
}

test.describe("a tutor's group", () => {
  test("shows who is in it before the lecture has a sheet", async ({ factory, tutor }) => {
    const { lecture } = await groupWithMember(factory, tutor.user.id);
    const { page } = tutor;

    await page.goto(`/lectures/${lecture.id}/tutorials`);

    const participants = page.getByTestId("tutorial-participants");
    await expect(participants.getByRole("heading", { name: /Participants/ })).toBeVisible();
    await expect(participants).toContainText("Ada Lovelace");
    await expect(participants).not.toContainText("Grace Hopper");
  });

  test("shows who registered while the registration runs, and writes to them",
    async ({ factory, tutor }) => {
      const { lecture, monday } = await groupWithMember(factory, tutor.user.id);
      const campaign = await factory.create("registration_campaign", ["first_come_first_served"], {
        campaignable_type: "Lecture", campaignable_id: lecture.id,
        description: "Tutorial registration",
      });
      const item = await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Tutorial", registerable_id: monday.id,
      });
      const registrant = await factory.create("confirmed_user", [], {
        name_in_tutorials: "Alan Turing",
      });
      await factory.create("registration_user_registration", ["confirmed"], {
        registration_campaign_id: campaign.id, registration_item_id: item.id,
        user_id: registrant.id,
      });
      await campaign.__call("open!");
      const { page } = tutor;

      await page.goto(`/lectures/${lecture.id}/tutorials`);

      const participants = page.getByTestId("tutorial-participants");
      await expect(participants.getByRole("heading", { name: /Registered, not final yet/ }))
        .toBeVisible();
      await expect(participants).toContainText("Alan Turing");

      await page.getByRole("button", { name: "Email the registered" }).click();
      const dialog = page.getByRole("dialog", { name: "Email to those registered for Mo 10" });
      await expect(dialog.getByText("The registration is not final yet")).toBeVisible();
      await dialog.getByLabel("Subject").fill("First session");
      await dialog.getByLabel("Message").fill("We start on Monday.");
      await dialog.getByRole("button", { name: "Send to 1 student" }).click();

      await expect(page.getByText("Your message is being sent to 1 student.")).toBeVisible();
    });
});
