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

  await page.locator("#term_year").selectOption((currentYear + 1).toString());
  await page.locator("#term_season").selectOption("WS");
  await page.getByRole("button", { name: "Save" }).last().click();

  await expect(termsPage.getTermRow(currentYear + 1, "WS")).toBeVisible();
});

test("create invalid Term", async ({ admin: { page } }) => {
  const termsPage = new TermsPage(page);
  await termsPage.goto();
  await termsPage.createTerm(currentYear, "SS");
  await termsPage.createTerm(currentYear, "SS");

  await expect(page.locator("#term_season")).toContainClass("is-invalid");
  await expect(page.getByText("term already exists")).toBeVisible();
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

  await page.locator("#term_year").selectOption((currentYear + 1).toString());
  await page.locator("#term_season").selectOption("WS");
  await page.getByRole("button", { name: "Cancel" }).click();

  await expect(termsPage.getTermRow(currentYear, "SS")).toBeVisible();
  await expect(termsPage.getTermRow(currentYear + 1, "WS")).not.toBeVisible();
});
