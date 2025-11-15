/**
 * Example test demonstrating the FactoryBot integration with Playwright.
 * This shows various patterns for using the factory fixture.
 */

import { expect, test } from "./_support/fixtures";

test("can create records and call instance methods", async ({ factory }) => {
  const lecture = await factory.create("lecture", "with_sparse_toc", "released_for_all");
  const title = await lecture.__call("title");
  expect(title).toBeTruthy();
  console.log("Lecture title:", title);

  const compactTitle = await lecture.__call("compact_title");
  expect(compactTitle).toBeTruthy();
  console.log("Compact title:", compactTitle);
});

test("can call methods that need a user as parameter", async ({ factory, student }) => {
  const lecture = await factory.create("lecture", "released_for_all");
  const visibleForUser = await lecture.__call("visible_for_user?", student.user);
  expect(visibleForUser).toBe(true);

  const lectureNonReleased = await factory.create("lecture");
  const notVisibleForUser = await lectureNonReleased.__call("visible_for_user?", student.user);
  expect(notVisibleForUser).toBe(false);
});
