import { expect, test } from "./_support/fixtures";

test.describe("the group rows", () => {
  test("open a roster from the title with the keyboard and take the focus back",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await tutorial.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      const row = page.getByRole("listitem")
        .filter({ has: page.getByRole("heading", { name: "Mo 10", exact: true }) });
      await expect(row).toContainText("1 / 8 members");

      const title = row.getByRole("button", { name: "Mo 10", exact: true });
      await expect(title).toHaveAttribute("aria-expanded", "false");
      await title.focus();
      await page.keyboard.press("Enter");

      const panel = page.getByRole("complementary", { name: "Participants" });
      await expect(panel.getByRole("heading", { name: "Participants" })).toBeFocused();
      await expect(title).toHaveAttribute("aria-expanded", "true");
      await expect(panel.getByRole("button", {
        name: `Copy email address: ${student.user.email}`,
      })).toBeVisible();

      await panel.getByRole("button", { name: "Close", exact: true }).click();
      await expect(title).toBeFocused();
      await expect(title).toHaveAttribute("aria-expanded", "false");
    });

  test("open an allocated group's roster from the allocation table with the keyboard",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const campaign = await factory.create("registration_campaign",
        ["preference_based", "with_items", "processing"], {
          campaignable_id: lecture.id,
          campaignable_type: "Lecture",
          last_allocation_calculated_at: new Date().toISOString(),
        });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8,
      });
      await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Tutorial",
        registerable_id: tutorial.id,
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      const title = page.getByRole("button", { name: "Mo 10", exact: true });
      await title.focus();
      await page.keyboard.press("Enter");

      await expect(page.getByRole("heading", { name: "Allocated Students" })).toBeFocused();
      await expect(title).toHaveAttribute("aria-expanded", "true");
    });

  test("move a student to another tutorial without dragging",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const monday = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Di 12", capacity: 8, skip_campaigns: true,
      });
      await monday.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("heading", { name: "Mo 10", exact: true }).click();

      const panel = page.getByRole("complementary", { name: "Participants" });
      await panel.getByRole("button", { name: /to another group/ }).click();

      const dialog = page.getByRole("dialog", { name: /^Move or add .* to …$/ });
      await expect(dialog.getByRole("button", { name: /Mo 10/ })).toHaveCount(0);
      await dialog.getByRole("button", { name: /Di 12/ }).click();

      const row = (title: string) => page.getByRole("listitem")
        .filter({ has: page.getByRole("heading", { name: title, exact: true }) });
      await expect(row("Di 12")).toContainText("1 / 8 members");
      await expect(row("Mo 10")).toContainText("0 / 8 members");
    });

  test("move with the keyboard, and the focus stays in the panel",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const monday = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Di 12", capacity: 8, skip_campaigns: true,
      });
      await monday.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("button", { name: "Mo 10", exact: true }).focus();
      await page.keyboard.press("Enter");

      const panel = page.getByRole("complementary", { name: "Participants" });
      await panel.getByRole("button", { name: /to another group/ }).focus();
      await page.keyboard.press("Enter");
      const dialog = page.getByRole("dialog", { name: /^Move or add .* to …$/ });
      await expect(dialog.getByRole("button", { name: /Di 12/ })).toBeFocused();
      await page.keyboard.press("Enter");

      await expect(page.getByRole("listitem")
        .filter({ has: page.getByRole("heading", { name: "Di 12", exact: true }) }))
        .toContainText("1 / 8 members");
      await expect(panel.getByRole("heading", { name: "Participants" })).toBeFocused();
    });

  test("offer a group a registration process manages, but not for choosing",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const monday = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Di 12", capacity: 8, skip_campaigns: false,
      });
      await monday.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("heading", { name: "Mo 10", exact: true }).click();
      await page.getByRole("complementary", { name: "Participants" })
        .getByRole("button", { name: /to another group/ }).click();

      const dialog = page.getByRole("dialog", { name: /^Move or add .* to …$/ });
      const locked = dialog.getByRole("button", { name: /Di 12/ });
      await expect(locked).toBeDisabled();
      await expect(locked).toContainText("Managed by a registration process");
    });
});
