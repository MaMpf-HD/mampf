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

  test("is not shown to somebody not signed in", async ({ page }) => {
    await page.goto("/users/sign_in?locale=en");

    await expect(page.getByRole("button", { name: "Contact support" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Tell us what we can improve" }))
      .toHaveCount(0);
  });
});
