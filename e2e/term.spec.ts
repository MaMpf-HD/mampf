import { expect, test } from "./_support/fixtures";
import { TermsPage } from "./page-objects/terms_page";

const currentYear = new Date().getFullYear();

test("create Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  const year = currentYear + 1;
  await termsPage.createTerm(year, "SS");
  await expect(termsPage.getTermRow(year, "SS")).toBeVisible();
});

test("delete Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");
  await termsPage.createTerm(currentYear + 1, "WS");
  await termsPage.createTerm(currentYear + 1, "SS");
  await expect(termsPage.getTermRow(currentYear + 1, "WS")).toBeVisible();
  await termsPage.deleteTerm(currentYear + 1, "WS");
  await expect(termsPage.getTermRow(currentYear + 1, "WS")).not.toBeVisible();
  await expect(termsPage.getTermRow(currentYear, "SS")).toBeVisible();
  await expect(termsPage.getTermRow(currentYear + 1, "SS")).toBeVisible();
});

test("edit Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");

  const row = termsPage.getTermRow(currentYear, "SS");
  await row.getByRole("link", { name: "Edit" }).click();

  const editForm = page.locator("turbo-frame[id^='term_'] form").first();
  await editForm.locator("select#term_year").selectOption((currentYear + 1).toString());
  await editForm.locator("select#term_season").selectOption("WS");
  await editForm.locator("input[type='submit'][value='Save']").click();

  await expect(termsPage.getTermRow(currentYear + 1, "WS")).toBeVisible();
});

test("create invalid Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");
  await termsPage.createTerm(currentYear, "SS");

  const newTermForm = page.locator("turbo-frame#new_term form");
  await expect(newTermForm.locator("select.is-invalid").first()).toBeVisible();
  await expect(newTermForm.locator("select.is-invalid").nth(1)).toBeVisible();
  await expect(newTermForm.locator("span.invalid-feedback")).toHaveText("This term already exists.");
});

test("cancel creating Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");

  await termsPage.createTerm(currentYear + 2, "WS", "cancel");

  await expect(termsPage.getTermRow(currentYear + 2, "WS")).not.toBeVisible();
  await expect(page.getByText(`${currentYear + 2} WS`)).not.toBeVisible();
  await expect(termsPage.getTermRow(currentYear, "SS")).toBeVisible();
});

test("cancel editing Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");

  const row = termsPage.getTermRow(currentYear, "SS");
  await row.getByRole("link", { name: "Edit" }).click();

  const editForm = page.locator("turbo-frame[id^='term_'] form").first();
  await editForm.locator("select#term_year").selectOption((currentYear + 1).toString());
  await editForm.locator("select#term_season").selectOption("WS");
  await editForm.locator("a:has-text('Cancel')").click();

  await expect(termsPage.getTermRow(currentYear, "SS")).toBeVisible();
  await expect(termsPage.getTermRow(currentYear + 1, "WS")).not.toBeVisible();
});
