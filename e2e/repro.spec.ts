import { test as testBase } from "@playwright/test";
import { test } from "./repro_fixture";

const LINK = "https://github.com/";

test("browser unfortunately doesn't stay open", async ({ page, adminPage }) => {
  await page.goto(LINK);
  await adminPage.goto(LINK);
});

testBase("browser stays open", async ({ page }) => {
  await page.goto(LINK);
});
