/* eslint-disable @typescript-eslint/no-explicit-any */
import { APIRequestContext, Browser, BrowserContext, expect, Page } from "@playwright/test";
import { callBackend } from "./backend";

export type User = {
  id: number;
  email: string;
  password: string;
  name: string;
  name_in_tutorials: string | null;
  created_at: string;
  updated_at: string;
  admin: boolean;
  subscription_type: number;
  consents: boolean;
  consented_at: string | null;
  homepage: string | null;
  no_notifications: boolean;
  locale: string;
  current_lecture_id: number | null;
  unread_comments: boolean;
  email_for_medium: string | null;
  email_for_announcement: string | null;
  email_for_teachable: string | null;
  email_for_news: string | null;

  email_for_submission_upload: string | null;
  email_for_submission_removal: string | null;
  email_for_submission_join: string | null;
  email_for_submission_leave: string | null;
  email_for_correction_upload: string | null;
  email_for_submission_decision: string | null;
  archived: boolean | null;
  deletion_date: string | null;
};

async function useUser(
  context: APIRequestContext,
  role: string,
): Promise<User> {
  const user = await callBackend(context, "user_creator_playwright", { role: role }) as User;
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

  return user;
}

/**
 * Makes it possible to have multiple signed-in user roles in one test.
 *
 * See also https://playwright.dev/docs/auth#testing-multiple-roles-together
 */
export async function userPage(
  browser: Browser,
  role: string,
): Promise<[User, Page, BrowserContext]> {
  const browserContext = await browser.newContext();
  const userPage = await browserContext.newPage();
  const user = await useUser(userPage.request, role);
  return [user, userPage, browserContext];
}
