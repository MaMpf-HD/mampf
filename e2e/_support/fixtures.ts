import { test as base, expect, Page } from "@playwright/test";
import { userPage } from "./auth";

type UserFixtures = {
  // default page is for a student
  student2Page: Page;
  adminPage: Page;
  teacherPage: Page;
  tutorPage: Page;
};

export const test = base.extend<UserFixtures>({
  page: async ({ browser }, use) => {
    const page = await userPage(browser, "student");
    await use(page);
  },

  student2Page: async ({ browser }, use) => {
    const page = await userPage(browser, "student2");
    await use(page);
  },

  adminPage: async ({ browser }, use) => {
    const page = await userPage(browser, "admin");
    await use(page);
  },

  teacherPage: async ({ browser }, use) => {
    const page = await userPage(browser, "teacher");
    await use(page);
  },

  tutorPage: async ({ browser }, use) => {
    const page = await userPage(browser, "tutor");
    await use(page);
  },
});

export { expect };
