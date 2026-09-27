import { expect, test } from "./_support/fixtures";

test.describe("the note pinned to a lecturer's dashboard", () => {
  test("creates a lecture, lists the edited courses and leads to the search", async ({
    factory,
    teacher: { page, user },
  }) => {
    const course = await factory.create("course", ["with_editor_by_id"], {
      editor_id: user.id, title: "Algebra",
    });
    await factory.create("term", ["summer", "active"], { year: 2025 });
    await factory.create("tag", [], { title: "Sylow theorems", course_ids: [course.id] });

    await page.goto("/");
    const note = page.getByRole("complementary", { name: "Now and then" });

    await note.getByRole("button", { name: "My courses" }).click();
    const courses = page.getByRole("dialog", { name: "My courses" });
    await expect(courses.getByRole("link", { name: "Edit Algebra" }))
      .toHaveAttribute("href", `/courses/${course.id}/edit`);
    await courses.getByRole("button", { name: "Close" }).click();
    await expect(courses).toBeHidden();

    const form = page.waitForResponse(response =>
      response.url().includes("/lectures/new") && response.ok());
    await note.getByRole("link", { name: "New lecture" }).click();
    await form;
    await page.getByTestId("new-lecture-course-select").selectOption({ label: "Algebra" });
    await page.keyboard.press("Escape");
    await page.getByTestId("new-lecture-submit").click();
    await expect(page).toHaveURL(/\/lectures\/\d+\/edit/);
    await expect(page.getByText("has been successfully created")).toBeVisible();

    await page.goto("/");
    await note.getByRole("link", { name: "Find media and tags" }).click();
    await expect(page.getByRole("heading", { name: "Search media and tags" })).toBeVisible();

    await page.getByRole("tab", { name: "Tag Search" }).click();
    const tags = page.getByRole("tabpanel").filter({ visible: true });
    await tags.getByRole("textbox").first().fill("Sylow");
    await tags.getByRole("button", { name: "Search" }).click();
    await expect(tags.getByText("Sylow theorems")).toBeVisible();
  });
});
