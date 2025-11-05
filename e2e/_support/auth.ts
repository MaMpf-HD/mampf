import { APIRequestContext, Browser, expect, Page } from "@playwright/test";
import { callBackend } from "./backend";

export async function useUser(
  context: APIRequestContext,
  role: "admin" | "teacher" | "student" | "tutor",
) {
  const user = await callBackend(context, "user_creator", { role: role });
  console.log("Created user:", user);

  const response = await context.post("/users/sign_in", {
    form: {
      "user[email]": user.email,
      "user[password]": user.password,
    },
  });

  expect(response.status()).toEqual(200);
  const responseBody = await response.text();
  expect(responseBody).toBeDefined();
  expect(responseBody).not.toMatch(/data-cy\s*=\s*["']?login-form["']?/);
}

/**
 * Makes it possible to have multiple signed-in user roles in one test.
 *
 * See also https://playwright.dev/docs/auth#testing-multiple-roles-together
 */
export async function userPage(
  browser: Browser,
  role: "admin" | "teacher" | "student" | "tutor",
): Promise<Page> {
  const userContext = await browser.newContext();
  const userPage = await userContext.newPage();
  await useUser(userPage.request, role);
  return userPage;
}
