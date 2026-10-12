import { expect, test } from "./_support/fixtures";

test.describe("the feedback muffin", () => {
  test("sends a signed-in user's feedback", async ({ student }) => {
    const { page } = student;
    await page.goto("/");

    await page.getByRole("button", { name: "Tell us what we can improve" }).click();
    const body = page.getByRole("textbox", { name: "Your feedback" });
    await expect(body).toBeFocused();
    await body.fill("The search could find more.");
    await page.getByRole("button", { name: "Send" }).click();

    await expect(page.getByRole("status")).toContainText("Thank you!");
    await expect(body).toHaveValue("");
  });

  test("opens from its mother on a wide dashboard", async ({ student }) => {
    const { page } = student;
    await page.setViewportSize({ width: 1600, height: 900 });
    await page.goto("/");

    await page.getByRole("button", { name: /My little one down there/ }).click();

    await expect(page.getByRole("textbox", { name: "Your feedback" })).toBeFocused();
  });

  test("is not shown to somebody not signed in", async ({ page }) => {
    await page.goto("/users/sign_in?locale=en");

    await expect(page.getByRole("button", { name: "Contact support" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Tell us what we can improve" }))
      .toHaveCount(0);
  });
});
