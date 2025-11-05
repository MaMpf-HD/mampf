import { test as base, Page } from "@playwright/test";
import { userPage } from "./auth";

type UserFixtures = {
  // default page is for a student
  student2Page: Page;
  adminPage: Page;
  teacherPage: Page;
  tutorPage: Page;
};

export * from "@playwright/test";
export const test = base.extend<UserFixtures>({
  page: async ({ browser }, use) => {
    const [page, browserContext] = await userPage(browser, "student");
    await use(page);
    await browserContext.close();
  },

  student2Page: async ({ browser }, use) => {
    const [page, browserContext] = await userPage(browser, "student2");
    await use(page);
    await browserContext.close();
  },

  adminPage: async ({ browser }, use) => {
    const [page, browserContext] = await userPage(browser, "admin");
    await use(page);
    await browserContext.close();
  },

  teacherPage: async ({ browser }, use) => {
    const [page, browserContext] = await userPage(browser, "teacher");
    await use(page);
    await browserContext.close();
  },

  tutorPage: async ({ browser }, use) => {
    const [page, browserContext] = await userPage(browser, "tutor");
    await use(page);
    await browserContext.close();
  },
});
