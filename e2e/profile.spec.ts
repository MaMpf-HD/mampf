import { test } from "./_support/fixtures";

test("can see user information", async ({ page }) => {
  await page.goto("/profile/edit");
});

// test("Multi-role page access", async ({ page, adminPage }) => {
//   await page.goto("/main/start");
//   await adminPage.goto("/main/start");
// });
