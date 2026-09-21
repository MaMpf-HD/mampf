import { expect, test } from "../_support/fixtures";
import { pickDate } from "../page-objects/datepicker";

// The sheet does not exist until the medium is released; the tab lists it
// anyway, so the lecturer sees it is coming and does not make it twice.
test("shows a sheet scheduled with a medium before it exists",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: user.id, locale: "en",
    });
    await factory.create("assignment", [], { lecture_id: lecture.id, title: "Sheet 1" });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"], {
      lecture_id: lecture.id, sort: "Exercise",
    });
    const release = new Date();
    release.setDate(release.getDate() + 2);
    const due = new Date();
    due.setDate(due.getDate() + 9);

    await page.goto(`/media/${medium.id}/edit`);
    await page.getByRole("button", { name: "publish" }).click();
    const modal = page.locator("#publishMediumModal");
    const widget = page.locator(".tempus-dominus-widget.show");
    await modal.getByRole("radio", { name: "at the following time" }).click();
    await pickDate(page, widget, release);
    await modal.getByRole("checkbox", { name: "Create an assignment" }).check();
    await modal.getByLabel("Title").fill("Sheet 2");
    await modal.locator("#assignment-date-picker [data-td-toggle]").click();
    await pickDate(page, widget, due);
    await expect(modal.getByLabel("Due date")).not.toHaveValue("");
    await modal.getByRole("checkbox", { name: "I hereby confirm that" }).check();
    await modal.getByRole("button", { name: "Save" }).click();
    await expect(page.getByText("scheduled for release on")).toBeVisible();

    await page.goto(`/assessment/assessments?lecture_id=${lecture.id}`);
    const rows = page.getByRole("row");
    await expect(rows.filter({ hasText: "Sheet 2" })).toContainText("appears on");
    // its settings live on the medium, and it has no dashboard yet
    await expect(rows.filter({ hasText: "Sheet 2" }).getByRole("link"))
      .toHaveAttribute("href", `/media/${medium.id}/edit`);
    await expect(rows.filter({ hasText: "Sheet 1" }).getByRole("link", { name: "Sheet 1" }))
      .toBeVisible();
  });
