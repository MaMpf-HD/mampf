import type { FactoryBot } from "./_support/factorybot";
import { expect, test } from "./_support/fixtures";

// A lecturer's lecture is theirs on the start page without a subscription;
// when the term turns, it moves from one fold to the other on its own.
test("shows a lecturer their lectures of both terms, without subscribing",
  async ({ factory, teacher: { page, user } }) => {
    const currentTerm = await factory.create("term", ["summer", "active"], { year: 2025 });
    const nextTerm = await factory.create("term", ["winter"], { year: 2025 });
    await ownLecture(factory, user.id, currentTerm.id, "Algebra Now");
    const ownNext = await ownLecture(factory, user.id, nextTerm.id, "Algebra Next");

    await page.goto("/");

    const current = page.locator("#collapseCurrentStuffContent");
    await expect(current.getByRole("link", { name: "Algebra Now" })).toBeVisible();
    await expect(current.getByTitle("Unsubscribe")).toHaveCount(0);
    await expect(current.getByTitle("Subscribe")).toHaveCount(0);

    await page.getByRole("button", { name: /WS 2025\/26/ }).click();
    const next = page.getByTestId("next-term-subscribed");
    await expect(next.getByRole("link", { name: "Algebra Next" })).toBeVisible();
    await expect(page.getByText("You have not yet subscribed any event series of the coming term."))
      .toBeHidden();

    await next.getByRole("link", { name: "Algebra Next" }).click();
    await expect(page).toHaveURL(new RegExp(`/lectures/${ownNext.id}`));
  });

async function ownLecture(factory: FactoryBot, teacherId: number, termId: number, title: string) {
  const course = await factory.create("course", [], { title });
  return factory.create("lecture", ["released_for_all"], {
    course_id: course.id, term_id: termId, teacher_id: teacherId,
  });
}
