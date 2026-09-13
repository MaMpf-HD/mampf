import { expect, test } from "../_support/fixtures";

test.describe("talk grading", () => {
  test("grades a talk from the seminar's table and narrows the rows", async ({
    factory,
    teacher,
  }) => {
    const seminar = await factory.create("lecture", ["released_for_all", "is_seminar"], {
      teacher_id: teacher.user.id,
      locale: "en",
    });
    const speakers = [];
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      speakers.push(await factory.create("confirmed_user", [], { name_in_tutorials: name }));
    }
    await factory.create("talk", [], {
      lecture_id: seminar.id,
      title: "Riemann's hypothesis",
      dates: ["2026-05-06"],
      speaker_ids: [speakers[0].id],
    });
    await factory.create("talk", [], {
      lecture_id: seminar.id, title: "Compilers", speaker_ids: [speakers[1].id],
    });

    await teacher.page.goto(`/lectures/${seminar.id}/edit?tab=assessments`);
    await expect(teacher.page.getByText("2 not yet marked")).toBeVisible();

    const table = teacher.page.getByRole("table");
    const row = table.getByRole("row", { name: /Ada Lovelace/ });
    await expect(row.getByRole("link", { name: "Riemann's hypothesis" })).toBeVisible();
    await expect(row.getByText("2026-05-06")).toBeVisible();
    await expect(row.getByText("Pending Grading")).toBeVisible();

    await row.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("1.3");
    await row.getByRole("textbox", { name: "Internal note on Ada Lovelace" })
      .fill("Clear and well paced");
    await row.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();
    await expect(row.getByText(/\d{4}-\d{2}-\d{2}, \d{2}:\d{2}/)).toBeVisible();
    await expect(teacher.page.getByText("1 marked · 1 not yet marked")).toBeVisible();

    // a grade taken back leaves the note, and nobody is named as its grader
    await row.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("");
    await row.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(row.getByText("Pending Grading")).toBeVisible();
    await expect(row.getByText(/\d{4}-\d{2}-\d{2}, \d{2}:\d{2}/)).toHaveCount(0);
    await expect(row.getByRole("textbox", { name: "Internal note on Ada Lovelace" }))
      .toHaveValue("Clear and well paced");
    await expect(teacher.page.getByText("2 not yet marked")).toBeVisible();

    // reloading brings back what is saved, and the line above with it
    await row.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("2.0");
    await row.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();
    await row.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("4.0");
    await row.getByRole("button", { name: "Reload the saved grade; unsaved changes are lost" })
      .click();
    await expect(row.getByRole("combobox", { name: "Grade for Ada Lovelace" })).toHaveValue("2.0");
    await expect(teacher.page.getByText("1 marked · 1 not yet marked")).toBeVisible();

    // the filters find a row by its state, and by the talk as well as the person
    await teacher.page.getByLabel("Status").selectOption("Pending Grading");
    await expect(row).toBeHidden();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeVisible();
    await expect(teacher.page.getByText("1 of 2 rows")).toBeVisible();

    await teacher.page.getByLabel("Name").fill("Riemann");
    await expect(teacher.page.getByText("No matching rows.")).toBeVisible();

    await teacher.page.getByRole("button", { name: "Reset filters" }).click();
    await teacher.page.getByLabel("Name").fill("Riemann");
    await expect(row).toBeVisible();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeHidden();
  });
});
