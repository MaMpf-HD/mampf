/**
 * Tests for the site-wide announcement banner that is rendered above the
 * navbar, both for the regular navbar and the administration navbar.
 */

import { expect, test } from "./_support/fixtures";

test("shows the site announcement banner above the regular navbar",
  async ({ factory, student: { page } }) => {
    await factory.create("announcement", [], {
      details: "Scheduled maintenance tonight",
      on_main_page: true,
    });

    await page.goto("/main/start");

    await expect(page.getByRole("alert").filter({ hasText: "Scheduled maintenance tonight" }))
      .toBeVisible();
  });

test("shows the site announcement banner above the administration navbar",
  async ({ factory, admin: { page } }) => {
    await factory.create("announcement", [], {
      details: "Scheduled maintenance tonight",
      on_main_page: true,
    });

    await page.goto("/administration");

    await expect(page.getByRole("alert").filter({ hasText: "Scheduled maintenance tonight" }))
      .toBeVisible();
  });

test("does not show a banner when there is no active announcement",
  async ({ admin: { page } }) => {
    await page.goto("/administration");

    await expect(page.getByRole("alert").filter({ hasText: "Scheduled maintenance tonight" }))
      .not.toBeVisible();
  });
