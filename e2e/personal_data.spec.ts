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
    await page.getByLabel("First name").fill("Ada");
    await page.getByLabel("Last name").fill("Lovelace");
    await page.getByRole("button", { name: "Continue" }).click();

    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Step 2 of 4: Matriculation number")).toBeVisible();
    await page.getByLabel("Matriculation number", { exact: true }).fill("3456789");
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page.getByText("Step 4 of 4: Check your details")).toBeVisible();
    await page.getByRole("button", { name: "Change: Name" }).click();
    await page.getByLabel("First name").fill("Augusta Ada");
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Augusta Ada")).toBeVisible();
    await expect(page.getByText("3456789")).toBeVisible();

    await page.getByRole("button", { name: "Save" }).click();
    await expect(page.getByText("must be accepted")).toBeVisible();

    await page.getByLabel(/I have checked these details/).check();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByText("Thank you, your details are saved.")).toBeVisible();
    await page.goto("/main/start");
    await expect(page).toHaveURL(/\/main\/start/);
  });

test("lets a user who takes part in no exercise class skip it",
  async ({ page, request }) => {
    await signInAsking(page, request);

    await expect(page.getByLabel("First name")).toBeHidden();
    await page.getByRole("radio", { name: "No" }).check();
    await page.getByText("Change display name").click();
    await page.getByLabel("Display name").fill("Ada L.");
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page).not.toHaveURL(/\/personal_data/);
    await page.goto("/main/start");
    await expect(page).toHaveURL(/\/main\/start/);

    await page.goto("/profile/edit");
    await expect(page.getByLabel("Display name")).toHaveValue("Ada L.");
    await page.getByRole("link", { name: "Show or complete" }).click();
    await expect(page.getByText("Step 1 of 4: Name")).toBeVisible();
    await page.getByRole("link", { name: "Back", exact: true }).click();
    await expect(page).toHaveURL(/\/profile\/edit/);
  });
