import { expect, test } from "./_support/fixtures";

// The mail itself goes out through a job, which the test server only
// enqueues; the request and mailer specs cover what it says and where it goes.
test.describe("the support button", () => {
  test("sends a signed-in user's message", async ({ student }) => {
    const { page } = student;
    await page.goto("/");

    await page.getByRole("button", { name: "Contact support" }).click();
    await page.getByRole("textbox", { name: "Your message" })
      .fill("My exam registration does not work.");
    await page.getByRole("button", { name: "Send" }).click();

    await expect(page.getByRole("status")).toContainText("Thank you!");
  });

  // Whoever cannot sign in needs support most, so the login page has it too.
  test("asks somebody not signed in for an address to answer to", async ({ page }) => {
    await page.goto("/users/sign_in?locale=en");

    await page.getByRole("button", { name: "Contact support" }).click();
    await page.getByRole("textbox", { name: "Your email address" })
      .fill("locked-out@example.com");
    await page.getByRole("textbox", { name: "Your message" })
      .fill("I cannot sign in any more.");
    await page.getByRole("button", { name: "Send" }).click();

    await expect(page.getByRole("status")).toContainText("Thank you!");
  });

  test("closes with Escape and gives the focus back to the button", async ({ student }) => {
    const { page } = student;
    await page.goto("/");
    const toggle = page.getByRole("button", { name: "Contact support" });

    await toggle.click();
    await expect(page.getByRole("textbox", { name: "Your message" })).toBeFocused();
    await page.keyboard.press("Escape");

    await expect(page.getByRole("textbox", { name: "Your message" })).toBeHidden();
    await expect(toggle).toBeFocused();
    await expect(toggle).toHaveAttribute("aria-expanded", "false");
  });
});
