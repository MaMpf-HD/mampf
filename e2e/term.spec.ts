import { expect, test } from "./_support/fixtures";
import { TermsPage } from "./page-objects/terms_page";

test("create Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2027, "SS");
  await expect(termsPage.getTermRow(2027, "SS")).toBeVisible();
});

test("delete Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2026, "SS");
  await termsPage.createTerm(2026, "WS");
  await termsPage.createTerm(2025, "SS");
  await expect(termsPage.getTermRow(2026, "WS")).toBeVisible();
  await termsPage.deleteTerm(2026, "WS");
  await expect(termsPage.getTermRow(2026, "WS")).not.toBeVisible();
  await expect(termsPage.getTermRow(2026, "SS")).toBeVisible();
  await expect(termsPage.getTermRow(2025, "SS")).toBeVisible();
});

test("edit Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2024, "SS");

  const row = termsPage.getTermRow(2024, "SS");
  await row.getByRole("link", { name: "Edit" }).click();

  const editForm = page.locator("turbo-frame[id^='term_'] form").first();
  await editForm.locator("select#term_year").selectOption("2023");
  await editForm.locator("select#term_season").selectOption("WS");
  await editForm.locator("input[type='submit'][value='Save']").click();

  await expect(termsPage.getTermRow(2023, "WS")).toBeVisible();
});

test("create invalid Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2026, "SS");
  await termsPage.createTerm(2025, "SS");
  await termsPage.createTerm(2025, "SS");

  const newTermForm = page.locator("turbo-frame#new_term form");
  await expect(newTermForm.locator("select.is-invalid").first()).toBeVisible();
  await expect(newTermForm.locator("select.is-invalid").nth(1)).toBeVisible();
  await expect(newTermForm.locator("span.invalid-feedback")).toHaveText("This term already exists.");
});

test("cancel creating Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2026, "SS");

  await termsPage.createTerm(2024, "WS", "cancel");

  await page.waitForTimeout(500);
  await expect(termsPage.getTermRow(2024, "WS")).not.toBeVisible();
  await expect(page.getByText("2024 WS")).not.toBeVisible();
  await expect(termsPage.getTermRow(2026, "SS")).toBeVisible();
});

test("cancel editing Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(2024, "SS");

  const row = termsPage.getTermRow(2024, "SS");
  await row.getByRole("link", { name: "Edit" }).click();

  const editForm = page.locator("turbo-frame[id^='term_'] form").first();
  await editForm.locator("select#term_year").selectOption("2023");
  await editForm.locator("select#term_season").selectOption("WS");
  await editForm.locator("a:has-text('Cancel')").click();

  await expect(termsPage.getTermRow(2024, "SS")).toBeVisible();
  await expect(termsPage.getTermRow(2023, "WS")).not.toBeVisible();
});
