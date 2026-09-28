import { expect, Page, test } from "./_support/fixtures";

async function createLecture(page: Page, course: string) {
  const dialog = page.getByRole("dialog", { name: "Create an event series" });
  await page.getByTestId("new-lecture-course-select").selectOption({ label: course });
  await page.keyboard.press("Escape");
  await dialog.getByRole("button", { name: "Save" }).click();
  return dialog;
}

test.describe("the note pinned to a lecturer's dashboard", () => {
  test("creates a lecture, lists the edited courses and leads to the search", async ({
    factory,
    teacher: { page, user },
  }) => {
    const course = await factory.create("course", ["with_editor_by_id"], {
      editor_id: user.id, title: "Algebra",
    });
    await factory.create("course", ["with_editor_by_id"], {
      editor_id: user.id, title: "Geometry",
    });
    await factory.create("term", ["summer", "active"], { year: 2025 });
    await factory.create("tag", [], { title: "Sylow theorems", course_ids: [course.id] });

    await page.goto("/");
    const note = page.getByRole("region", { name: "For teaching staff" })
      .getByRole("complementary", { name: "Now and then" });

    await note.getByRole("button", { name: "My courses" }).click();
    const courses = page.getByRole("dialog", { name: "My courses" });
    await expect(courses.getByRole("link", { name: "Edit Algebra" }))
      .toHaveAttribute("href", `/courses/${course.id}/edit`);
    await courses.getByRole("button", { name: "Close" }).click();
    await expect(courses).toBeHidden();

    // closing the dialog puts the keyboard back where it was
    const newLecture = note.getByRole("button", { name: "New lecture" });
    await newLecture.click();
    const dialog = page.getByRole("dialog", { name: "Create an event series" });
    await expect(dialog.getByRole("button", { name: "Save" })).toBeVisible();
    await dialog.getByRole("button", { name: "Close" }).click();
    await expect(dialog).toBeHidden();
    await expect(newLecture).toBeFocused();

    await newLecture.click();
    await createLecture(page, "Algebra");
    await expect(page).toHaveURL(/\/lectures\/\d+\/edit/);
    await expect(page.getByText("has been successfully created")).toBeVisible();

    // the same lecture a second time is refused inside the dialog
    await page.goto("/");
    const staffNote = page.getByRole("region", { name: "You are staff in these" })
      .getByRole("complementary", { name: "Now and then" });
    await staffNote.getByRole("button", { name: "New lecture" }).click();
    const refused = await createLecture(page, "Algebra");
    await expect(refused.getByText("same combination of course, term and teacher"))
      .toBeVisible();
    await createLecture(page, "Geometry");
    await expect(page).toHaveURL(/\/lectures\/\d+\/edit/);

    await page.goto("/");
    await staffNote.getByRole("link", { name: "Find media and tags" }).click();
    await expect(page.getByRole("heading", { name: "Search media and tags" })).toBeVisible();

    await page.getByRole("tab", { name: "Tag Search" }).click();
    const tags = page.getByRole("tabpanel", { name: "Tag Search" });
    await tags.getByRole("textbox").first().fill("Sylow");
    await tags.getByRole("button", { name: "Search" }).click();
    await expect(tags.getByText("Sylow theorems")).toBeVisible();
  });
});
