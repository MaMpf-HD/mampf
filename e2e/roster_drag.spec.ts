import { expect, test } from "./_support/fixtures";
import { enableFeature } from "./_support/backend";
import { LectureEditPage } from "./page-objects/lecture_edit_page";

/**
 * The drop zones have to be rebuilt whenever a turbo stream re-renders the
 * tiles, which the roster panel wires up with
 *
 *   data-action="turbo:stream-render@document->roster-drag#refreshDropZones"
 *
 * That event is our own (see initHotwire.js) and does not bubble — it is
 * dispatched straight onto `document`. Nothing else covers this wiring, and a
 * "no console errors" check would not either: if the action never fired, there
 * would be no error, just silently stale drop zones. Hence the spy below, which
 * proves the action actually runs, with `this` bound to the controller.
 */
test("roster drag zones refresh on a turbo stream render", async ({
  request,
  factory,
  teacher: { page, user },
}) => {
  const errors: string[] = [];
  page.on("pageerror", error => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });

  await enableFeature(request, "roster_maintenance");
  const lecture = await factory.create("lecture", [], { teacher_id: user.id });
  // skip_campaigns, or the group counts as locked and the panel is read-only,
  // which drops the drag controller altogether.
  await factory.create("tutorial", [],
    { lecture_id: lecture.id, skip_campaigns: true });

  const lectureEditPage = new LectureEditPage(page, lecture.id);
  await lectureEditPage.goto();
  await lectureEditPage.groupsTab.click();

  // clicking a tile loads the side panel, which connects the drag controller
  await page.locator("[data-roster-key]").first().click();
  await expect(page.locator("[data-controller~=\"roster-drag\"]")).toBeVisible();

  const actionRan = await page.evaluate(() => {
    const element = document.querySelector("[data-controller~=\"roster-drag\"]");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const controller = (window as any).Stimulus
      .getControllerForElementAndIdentifier(element, "roster-drag");

    let ran = false;
    controller.clearHighlight = () => {
      ran = true;
    };

    document.dispatchEvent(new Event("turbo:stream-render"));

    return ran;
  });

  expect(actionRan).toBe(true);
  expect(errors).toEqual([]);
});
