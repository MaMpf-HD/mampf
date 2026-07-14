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
 * would be no error, just silently stale drop zones. Hence the spy below.
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
  await factory.create("tutorial", [], {
    lecture_id: lecture.id,
    title: "Tuesday Tutorial",
    skip_campaigns: true,
  });

  const lectureEditPage = new LectureEditPage(page, lecture.id);
  await lectureEditPage.goto();
  await lectureEditPage.groupsTab.click();

  // clicking a tile loads the side panel, which connects the drag controller
  await page.getByRole("heading", { name: "Tuesday Tutorial" }).click();
  // the attribute is what this test is about, so we assert on it rather than on
  // a test id standing in for it
  await expect(page.locator("[data-controller~=\"roster-drag\"]")).toBeVisible();

  const refreshed = await page.evaluate(() => {
    const element = document.querySelector("[data-controller~=\"roster-drag\"]");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const controller = (window as any).Stimulus
      .getControllerForElementAndIdentifier(element, "roster-drag");

    // wrap rather than replace, so the real method still runs and a broken one
    // would surface through the console/pageerror listeners above
    const refreshDropZones = controller.refreshDropZones;
    let ran = false;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    controller.refreshDropZones = function (this: any, ...args: unknown[]) {
      ran = true;
      refreshDropZones.apply(this, args);
    };

    document.dispatchEvent(new Event("turbo:stream-render"));

    return ran;
  });

  expect(refreshed).toBe(true);
  expect(errors).toEqual([]);
});
