import { test as base, Page } from "@playwright/test";
import { User, userPage } from "./auth";

class UserFixture {
  page: Page;
  user: User;

  constructor(page: Page, user: User) {
    this.page = page;
    this.user = user;
  }
}

type UserFixtures = {
  student: UserFixture;
  student2: UserFixture;
  admin: UserFixture;
  teacher: UserFixture;
  tutor: UserFixture;
};

export * from "@playwright/test";
export const test = base.extend<UserFixtures>({
  student: async ({ browser }, use) => {
    const [user, page, browserContext] = await userPage(browser, "student");
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  student2: async ({ browser }, use) => {
    const [user, page, browserContext] = await userPage(browser, "student2");
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  admin: async ({ browser }, use) => {
    const [user, page, browserContext] = await userPage(browser, "admin");
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  teacher: async ({ browser }, use) => {
    const [user, page, browserContext] = await userPage(browser, "teacher");
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  tutor: async ({ browser }, use) => {
    const [user, page, browserContext] = await userPage(browser, "tutor");
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },
});
