import { test as base, Page } from "@playwright/test";

type UserFixtures = {
  adminPage: Page;
};

export * from "@playwright/test";
export const test = base.extend<UserFixtures>({
  page: async ({ browser }, use) => {
    const browserContext = await browser.newContext();
    const userPage = await browserContext.newPage();
    // simulate creating new user
    await userPage.request.post("/users/sign_in_as_student");
    await use(userPage);
    await browserContext.close();
  },

  adminPage: async ({ browser }, use) => {
    const browserContext = await browser.newContext();
    const userPage = await browserContext.newPage();
    // simulate creating new user
    await userPage.request.post("/users/sign_in_as_admin");
    await use(userPage);
    await browserContext.close();
  },
});
