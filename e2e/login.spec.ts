import { test } from "@playwright/test";
import { useUser } from "./_support/auth";

test("Login with one user", async ({ page }) => {
  await useUser(page.request, "student");
  await page.goto("/main/start");
});
