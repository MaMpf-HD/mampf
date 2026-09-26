import { type APIRequestContext, expect, type Page, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { callBackend } from "./_support/backend";
import { LoginPage } from "./page-objects/login_page";

async function signInAsking(page: Page, request: APIRequestContext) {
  const user = await callBackend(request, "user_creator",
    { role: "student", personal_data_pending: true }) as User;
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(user.email, user.password);
  await expect(page).toHaveURL(/\/personal_data/);
}

test("asks once for the name and matriculation number after sign-in",
  async ({ page, request }) => {
    await signInAsking(page, request);

    await page.getByRole("radio", { name: "Yes" }).check();
    await page.getByLabel("First name", { exact: true }).fill("Ada");
    await page.getByLabel("Last name", { exact: true }).fill("Lovelace");
    await page.getByRole("button", { name: "Continue" }).click();

    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Step 2 of 4: Matriculation number")).toBeVisible();
    await page.getByLabel("Matriculation number", { exact: true }).fill("345678");
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Step 2 of 4: Matriculation number")).toBeVisible();
    await page.getByLabel("Matriculation number", { exact: true }).fill("3456789");
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page.getByText("Step 4 of 4: Check your details")).toBeVisible();
    await page.getByRole("button", { name: "Change: Last name" }).click();
    await page.getByLabel("Last name", { exact: true }).fill("King");
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("King", { exact: true })).toBeVisible();
    await expect(page.getByText("3456789")).toBeVisible();

    await page.getByRole("button", { name: "Save" }).click();
    await expect(page.getByText("Please confirm that you have checked your details."))
      .toBeVisible();

    await page.getByLabel(/I have checked these details/).check();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByText("Thank you, your details are saved.")).toBeVisible();
    await page.goto("/");
    await expect(page).toHaveURL(/\/main\/start/);
  });

test("lets a user who takes part in no exercise class skip it",
  async ({ page, request }) => {
    await signInAsking(page, request);

    await expect(page.getByLabel("First name", { exact: true })).toBeHidden();
    await page.getByRole("radio", { name: "No" }).check();
    await page.getByText("Change display name").click();
    await page.getByLabel("Display name").fill("Ada L.");
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page).not.toHaveURL(/\/personal_data/);
    await page.goto("/");
    await expect(page).toHaveURL(/\/main\/start/);

    await page.goto("/profile/edit");
    await expect(page.getByLabel("Display name")).toHaveValue("Ada L.");
    await page.getByRole("link", { name: "Show or complete" }).click();
    await expect(page.getByText("Step 1 of 4: Name")).toBeVisible();
    await page.getByRole("link", { name: "Back", exact: true }).click();
    await expect(page).toHaveURL(/\/profile\/edit/);
  });

test("leads a student of two subjects to mathematics without a list",
  async ({ page, request, factory }) => {
    const math = await factory.create("subject", [], { name: "Mathematik", key: "math" });
    const physics = await factory.create("subject", [], { name: "Physik" });
    for (const subject of [math, physics]) {
      await factory.create("program", [], { subject_id: subject.id, name: "B.Sc. 50%",
        degree: "bsc50" });
    }
    await factory.create("program", [], { subject_id: math.id, name: "M.Sc.", degree: "msc" });
    await signInAsking(page, request);

    await page.getByRole("radio", { name: "Yes" }).check();
    await page.getByLabel("First name", { exact: true }).fill("Ada");
    await page.getByLabel("Last name", { exact: true }).fill("Lovelace");
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByLabel("Matriculation number", { exact: true }).fill("3456789");
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page.getByText("Step 3 of 5: Study program")).toBeVisible();
    await page.getByRole("radio", { name: "B.Sc. 50%" }).check();
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Step 3 of 5: Study program")).toBeVisible();
    await page.getByRole("group", { name: "Is mathematics one of your two subjects?" })
      .getByRole("radio", { name: "Yes" }).check();
    await expect(page.getByRole("radio", { name: "Physik: B.Sc. 50%" })).toBeHidden();
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByRole("definition").getByText("Mathematik: B.Sc. 50%")).toBeVisible();

    await page.getByRole("button", { name: "Change: Study program" }).click();
    await page.getByRole("group", { name: "Is mathematics one of your two subjects?" })
      .getByRole("radio", { name: "No" }).check();
    await expect(page.getByRole("radio", { name: "Other subject" })).toBeVisible();
    await page.getByRole("radio", { name: "Physik: B.Sc. 50%" }).check();
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByRole("definition").getByText("Physik: B.Sc. 50%")).toBeVisible();

    await page.getByLabel(/I have checked these details/).check();
    await page.getByRole("button", { name: "Save" }).click();
    await expect(page.getByText("Thank you, your details are saved.")).toBeVisible();
  });

test("lets a student with a place give it up instead of entering the details",
  async ({ page, request, factory }) => {
    const user = await callBackend(request, "user_creator",
      { role: "student", personal_data_pending: true }) as User;
    const lecture = await factory.create("lecture", ["released_for_all"]);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Mo 10",
    });
    await factory.create("lecture_membership", [], { lecture_id: lecture.id, user_id: user.id });
    await factory.create("tutorial_membership", [], { tutorial_id: tutorial.id, user_id: user.id });
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(user.email, user.password);
    await expect(page).toHaveURL(/\/personal_data/);

    await expect(page.getByRole("group", { name: /^You take part in/ })).toBeVisible();
    await expect(page.getByRole("radio", { name: "No", exact: true })).toHaveCount(0);
    await page.getByRole("radio", { name: "Give up my places" }).check();
    await expect(page.getByText(/You leave the groups, talks, exams and registrations/))
      .toBeVisible();
    await page.getByRole("button", { name: "Give up places and continue" }).click();

    await expect(page).not.toHaveURL(/\/personal_data/);
    await page.goto("/");
    await expect(page).toHaveURL(/\/main\/start/);
  });
