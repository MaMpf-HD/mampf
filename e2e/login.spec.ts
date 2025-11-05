import { test } from "@playwright/test";
import { useUser, userPage } from "./_support/auth";

test("Login with one user", async ({ page }) => {
  await useUser(page.request, "student");
  await page.goto("/main/start");
});

test("Multi-role page access", async ({ browser }) => {
  // think of a "Page" as an isolated browser tab
  // https://playwright.dev/docs/pages
  const studentPage = await userPage(browser, "student");
  const adminPage = await userPage(browser, "admin");

  await studentPage.goto("/main/start");
  await adminPage.goto("/main/start");
});
