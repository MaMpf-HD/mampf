/**
 * Example test demonstrating the FactoryBot integration with Playwright.
 * This shows various patterns for using the factory fixture.
 */

import { expect, test } from "./_support/fixtures";

test("can create factories with traits and arguments", async ({ factory }) => {
  const CONTENT_MODE = "playwright";
  const lecture = await factory.createNoValidate("lecture", [], { content_mode: CONTENT_MODE });
  expect(lecture.content_mode).toBe(CONTENT_MODE);

  const lectureForAll = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
  const tutorial = await factory.create("tutorial", [], { lecture_id: lectureForAll.id });
  expect(tutorial.lecture_id).toBe(lectureForAll.id);
});

test("can call instance methods", async ({ factory, tutor, student }) => {
  const lecture = await factory.create("lecture", ["released_for_all"]);
  const title = await lecture.__call("title");
  expect(title).toBeTruthy();
  console.log("Lecture title:", title);

  const compactTitle = await lecture.__call("compact_title");
  expect(compactTitle).toBeTruthy();
  console.log("Compact title:", compactTitle);

  const tutorial = await factory.create("tutorial", [],
    { lecture_id: lecture.id, tutor_ids: [tutor.user.id, student.user.id] });
  const tutorNames = await tutorial.__call("tutor_names");
  expect(tutorNames).toContain(tutor.user.name_in_tutorials);
  expect(tutorNames).toContain(student.user.name_in_tutorials);
});

test("can call methods that need a user as parameter", async ({ factory, student }) => {
  const lecture = await factory.create("lecture", ["released_for_all"]);
  const visibleForUser = await lecture.__call("visible_for_user?", student.user);
  expect(visibleForUser).toBe(true);

  const lectureNonReleased = await factory.create("lecture");
  const visibleForUserAgain = await lectureNonReleased.__call("visible_for_user?", student.user);
  expect(visibleForUserAgain).toBe(false);
});
