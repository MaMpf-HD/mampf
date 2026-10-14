import { expect, test } from "./_support/fixtures";
import { createReleasedLecture, subscribeToLecture } from "./user_registration/helpers";

const viewports = [
  { width: 1920, height: 1080 },
  { width: 700, height: 900 },
  { width: 390, height: 844 },
];

for (const viewport of viewports) {
  test(`keeps the notification dropdown inside a ${viewport.width}px wide window`, async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory,
      "Partial Differential Equations and Their Applications in Physics");
    await subscribeToLecture(factory, lecture, student.user.id);
    const announcement = await factory.create("announcement", [], {
      lecture_id: lecture.id,
      announcer_id: student.user.id,
      details: "The exercise class has moved to room 5.",
    });
    await factory.create("notification", [], {
      recipient_id: student.user.id,
      notifiable_type: "Announcement",
      notifiable_id: announcement.id,
    });
    await student.page.setViewportSize(viewport);

    await student.page.goto("/");
    await student.page.getByRole("list", { name: "New notifications" })
      .getByRole("button", { name: "Toggle" }).click();

    const showAll = student.page.getByRole("link", { name: "Show all", exact: true });
    await expect(showAll).toBeVisible();
    const menu = await showAll.locator("..").boundingBox();
    if (!menu) throw new Error("The notification menu has no bounding box.");
    expect(menu.x).toBeGreaterThanOrEqual(0);
    expect(menu.x + menu.width).toBeLessThanOrEqual(viewport.width);
  });
}
