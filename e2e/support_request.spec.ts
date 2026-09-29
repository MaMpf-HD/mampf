import { expect, test } from "./_support/fixtures";

// The mail itself goes out through a job, which the test server only
// enqueues; the request and mailer specs cover what it says and where it goes.
test.describe("the support button", () => {
  test("sends a signed-in user's message", async ({ student }) => {
    const { page } = student;
    await page.goto("/");

    await page.getByRole("button", { name: "Contact support" }).click();
    await expect(page.getByText("You can also write to us at")).toBeVisible();
    const message = page.getByRole("textbox", { name: "Your message" });
    await message.fill("My exam registration does not work.");
    await page.getByRole("button", { name: "Send" }).click();

    await expect(page.getByRole("status")).toContainText("Thank you!");
    // a second question needs no new page
    await expect(message).toHaveValue("");
    await expect(page.getByRole("button", { name: "Send" })).toBeVisible();
  });

  // Runs on the login page, where the button serves visitors who cannot sign in.
  test("asks somebody not signed in for an address to answer to", async ({ page }) => {
    await page.goto("/users/sign_in?locale=en");

    await page.getByRole("button", { name: "Contact support" }).click();
    const email = page.getByRole("textbox", { name: "Your email address" });
    await expect(email).toBeFocused();
    await email.fill("locked-out@example.com");
    await page.getByRole("textbox", { name: "Your message" })
      .fill("I cannot sign in any more.");
    await page.getByRole("button", { name: "Send" }).click();

    await expect(page.getByRole("status")).toContainText("Thank you!");
    await expect(page.getByRole("status")).toBeFocused();
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

  test("leaves the focus where a click outside the panel put it", async ({ page }) => {
    await page.goto("/users/sign_in?locale=en");
    const toggle = page.getByRole("button", { name: "Contact support" });

    const loginEmail = page.getByRole("textbox", { name: "Email", exact: true });

    await toggle.click();
    await loginEmail.click();

    await expect(toggle).toHaveAttribute("aria-expanded", "false");
    await expect(loginEmail).toBeFocused();
  });
});
