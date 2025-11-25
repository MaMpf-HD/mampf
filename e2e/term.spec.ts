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
