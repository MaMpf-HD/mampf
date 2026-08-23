import { expect, test, Page } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

/**
 * A teacher who set up the wrong groups or opened a registration process by
 * mistake has to be able to get out of it again: discard the whole process,
 * take a single group out of it, or delete that group for good.
 */
test.describe("getting out of a registration process", () => {
  interface Setup {
    lecture: FactoryBotObject;
    campaign: FactoryBotObject;
    tutorials: FactoryBotObject[];
    items: FactoryBotObject[];
  }

  async function setUpCampaign(
    factory: FactoryBot, teacherId: number, tutorialTitles: string[],
  ): Promise<Setup> {
    const lecture = await factory.create("lecture", [], {
      teacher_id: teacherId,
      locale: "en",
    });
    const campaign = await factory.create(
      "registration_campaign", ["first_come_first_served"],
      {
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Tutorial registration",
      },
    );

    const tutorials: FactoryBotObject[] = [];
    const items: FactoryBotObject[] = [];
    for (const title of tutorialTitles) {
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id,
        title,
        capacity: 5,
      });
      items.push(await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Tutorial",
        registerable_id: tutorial.id,
      }));
      tutorials.push(tutorial);
    }

    return { lecture, campaign, tutorials, items };
  }

  function tile(page: Page, title: string) {
    return page.getByTestId("group-tile").filter({ hasText: title });
  }

  function noCampaignSection(page: Page) {
    return page.getByTestId("registration-no-campaign-section");
  }

  test("spells out what opening a registration process freezes",
    async ({ factory, teacher: { page, user } }) => {
      const { lecture, campaign } = await setUpCampaign(factory, user.id, ["Monday Tutorial"]);

      let confirmation = "";
      page.once("dialog", async (dialog) => {
        confirmation = dialog.message();
        await dialog.accept();
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("button", { name: "Start Registration" }).click();

      await expect(page.getByText("Registration process opened.")).toBeVisible();
      expect(await campaign.__call("status")).toBe("open");

      expect(confirmation).toContain(
        "Settings, rules and the allocation mode can no longer be changed.");
      expect(confirmation).toContain(
        "Groups that already have registrations can no longer be removed from the process.");
      expect(confirmation).toContain(
        "you can still take the process back to draft or discard it entirely.");
    });

  test("discards a process that was opened by mistake and keeps its groups",
    async ({ factory, teacher: { page, user } }) => {
      const { lecture, campaign } = await setUpCampaign(
        factory, user.id, ["Monday Tutorial", "Tuesday Tutorial"]);
      await campaign.__call("open!");

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("button", { name: "Discard registration process" }).click();

      await expect(page.getByText("Tutorial registration")).toBeHidden();
      await expect(noCampaignSection(page).getByText("Monday Tutorial")).toBeVisible();
      await expect(noCampaignSection(page).getByText("Tuesday Tutorial")).toBeVisible();

      const tutorials = await lecture.__call("tutorials") as unknown[];
      expect(tutorials).toHaveLength(2);
    });

  test("offers deletion only as long as nothing depends on the process",
    async ({ factory, student, teacher: { page, user } }) => {
      const { lecture, campaign, items } = await setUpCampaign(
        factory, user.id, ["Monday Tutorial", "Tuesday Tutorial"]);
      await campaign.__call("open!");
      await factory.create("registration_user_registration", [], {
        user_id: student.user.id,
        registration_campaign_id: campaign.id,
        registration_item_id: items[0].id,
        status: "confirmed",
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);

      await expect(
        page.getByRole("button", { name: "Discard registration process" }),
      ).toBeHidden();

      // the group that was registered for is pinned, the other one is not. A
      // blocked button keeps its place in the tab order, so its name carries
      // the reason - the tooltip on the wrapper is mouse-only.
      const pinned = tile(page, "Monday Tutorial");
      await expect(
        pinned.getByRole("button", {
          name: "Remove from registration process: Cannot be removed because students "
            + "have already registered for it.",
          exact: true,
        }),
      ).toBeDisabled();
      await expect(
        pinned.getByRole("button", { name: "Delete group completely:" }),
      ).toBeDisabled();
      // deleting the group inherits the reason the item cannot leave the process
      await expect(
        pinned.getByTitle("Cannot be removed because students have already registered for it."),
      ).toHaveCount(2);
      await expect(
        tile(page, "Tuesday Tutorial")
          .getByRole("link", { name: "Remove from registration process" }),
      ).toBeVisible();
    });

  test("takes a group out of the process without deleting it",
    async ({ factory, teacher: { page, user } }) => {
      const { lecture } = await setUpCampaign(factory, user.id, ["Monday Tutorial"]);

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await expect(noCampaignSection(page).getByText("Monday Tutorial")).toBeHidden();

      await tile(page, "Monday Tutorial")
        .getByRole("link", { name: "Remove from registration process" }).click();

      await expect(page.getByText(
        "Group removed from the registration process. It can now be managed manually.",
      )).toBeVisible();
      await expect(noCampaignSection(page).getByText("Monday Tutorial")).toBeVisible();

      const tutorials = await lecture.__call("tutorials") as unknown[];
      expect(tutorials).toHaveLength(1);
    });

  test("deletes a group together with its entry in the process",
    async ({ factory, teacher: { page, user } }) => {
      const { lecture } = await setUpCampaign(factory, user.id, ["Monday Tutorial"]);

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await tile(page, "Monday Tutorial")
        .getByRole("link", { name: "Delete group completely" }).click();

      await expect(page.getByText("Group deleted successfully.")).toBeVisible();
      await expect(page.getByText("Monday Tutorial")).toBeHidden();

      const tutorials = await lecture.__call("tutorials") as unknown[];
      expect(tutorials).toHaveLength(0);
    });

  test("takes a process back to draft to get at its last group",
    async ({ factory, teacher: { page, user } }) => {
      const { lecture, campaign } = await setUpCampaign(factory, user.id, ["Monday Tutorial"]);
      await campaign.__call("open!");

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);

      // a running process needs a group, so both actions are barred - and say so
      const onlyGroup = tile(page, "Monday Tutorial");
      await expect(
        onlyGroup.getByRole("button", { name: "Remove from registration process" }),
      ).toBeDisabled();
      await expect(
        onlyGroup.getByTitle(/Take the process back to draft to change its groups/),
      ).toHaveCount(2);

      // exact, because a blocked button's name now quotes this action as the way out
      await page.getByRole("button", { name: "Back to draft", exact: true }).click();
      await expect(page.getByText(
        "Registration process taken back to draft. You can change its settings and its groups again.",
      )).toBeVisible();
      expect(await campaign.__call("status")).toBe("draft");

      await tile(page, "Monday Tutorial")
        .getByRole("link", { name: "Delete group completely" }).click();

      await expect(page.getByText("Group deleted successfully.")).toBeVisible();
      expect(await lecture.__call("tutorials")).toHaveLength(0);
    });

  // Masonry measures the content grid once, while the tab it sits in is still
  // hidden. Re-laying it out was bound on DOM ready, which a Turbo redirect
  // does not run again - so after a refused deletion every talk card ended up
  // stacked in the same spot.
  test("lays the seminar's talks out after a refused deletion",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["is_seminar"], {
        teacher_id: user.id,
        locale: "en",
      });
      const talks = [];
      for (const title of ["First Talk", "Second Talk"]) {
        talks.push(await factory.create("talk", [], { lecture_id: lecture.id, title }));
      }
      const campaign = await factory.create(
        "registration_campaign", ["first_come_first_served"],
        { campaignable_type: "Lecture", campaignable_id: lecture.id },
      );
      await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Talk",
        registerable_id: talks[0].id,
      });
      // another process requiring this one is what still refuses the deletion
      const other = await factory.create("registration_campaign", []);
      await factory.create("registration_policy", ["prerequisite_campaign"], {
        registration_campaign_id: other.id,
        config: { prerequisite_campaign_id: campaign.id },
      });

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("link", { name: "Delete", exact: true }).first().click();
      await expect(page.getByText("could not be deleted")).toBeVisible();

      await page.getByTestId("content-tab-btn").click();

      const first = await page.getByText("Talk 1. First Talk").boundingBox();
      const second = await page.getByText("Talk 2. Second Talk").boundingBox();

      // side by side at this width; stacked means both sit at the same point
      expect(first).not.toBeNull();
      expect(second).not.toBeNull();
      expect([first?.x, first?.y]).not.toEqual([second?.x, second?.y]);
    });

  // The last dead end of the report: the seminar itself could not be deleted,
  // because a finalized process vetoed the cascade.
  test("deletes a seminar whose registration process is over",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["is_seminar"], {
        teacher_id: user.id,
        locale: "en",
      });
      const talk = await factory.create("talk", [], {
        lecture_id: lecture.id, title: "Nobody's Talk",
      });
      const campaign = await factory.create(
        "registration_campaign", ["first_come_first_served"],
        { campaignable_type: "Lecture", campaignable_id: lecture.id },
      );
      const item = await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Talk",
        registerable_id: talk.id,
      });
      await campaign.__call("open!");
      await factory.create("registration_user_registration", [], {
        user_id: student.user.id,
        registration_campaign_id: campaign.id,
        registration_item_id: item.id,
        status: "confirmed",
      });
      await campaign.__call("completed!");

      let confirmation = "";
      page.once("dialog", async (dialog) => {
        confirmation = dialog.message();
        await dialog.accept();
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("link", { name: "Delete", exact: true }).first().click();

      await expect(page).not.toHaveURL(/lectures/);
      expect(confirmation).toContain("1 registration processes with 1 registrations");
    });

  // The complaint from production: after finalizing, the talks nobody took are
  // still there and nothing can remove them.
  test("deletes a talk nobody took once the process is finalized",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["is_seminar"], {
        teacher_id: user.id,
        locale: "en",
      });
      const campaign = await factory.create(
        "registration_campaign", ["first_come_first_served"],
        {
          campaignable_type: "Lecture",
          campaignable_id: lecture.id,
          description: "Talk assignment",
        },
      );
      const talk = await factory.create("talk", [], {
        lecture_id: lecture.id,
        title: "Nobody's Talk",
      });
      await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Talk",
        registerable_id: talk.id,
      });
      await campaign.__call("open!");
      await campaign.__call("completed!");

      page.on("dialog", dialog => dialog.accept());

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await tile(page, "Nobody's Talk")
        .getByRole("link", { name: "Delete", exact: true }).click();

      // gone from the group tiles and from the seminar's content list above them
      await expect(page.getByText("Nobody's Talk")).toHaveCount(0);
      expect(await lecture.__call("talks")).toHaveLength(0);
    });

  test("refuses to delete a group that still has participants",
    async ({ factory, student, teacher: { page, user } }) => {
      const { lecture, tutorials } = await setUpCampaign(factory, user.id, ["Monday Tutorial"]);
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorials[0].id,
        user_id: student.user.id,
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);

      const occupied = tile(page, "Monday Tutorial");
      await expect(
        occupied.getByRole("button", { name: "Delete group completely" }),
      ).toBeDisabled();
      await expect(
        occupied.getByTitle("Cannot be deleted because there are participants."),
      ).toBeVisible();
      // taking it out of the process is still allowed - that loses nothing
      await expect(
        tile(page, "Monday Tutorial")
          .getByRole("link", { name: "Remove from registration process" }),
      ).toBeVisible();
    });
});
