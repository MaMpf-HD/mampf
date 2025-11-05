import { test } from "@playwright/test";
import { loginStudent } from "./_support/auth";

test("Dummy test", async ({ page }) => {
  await loginStudent(page.request);
  await page.goto("/main/start");
});
