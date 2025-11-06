import { test as base, Page } from "@playwright/test";
import { User, userPage } from "./auth";
import { FactoryBot } from "./factorybot";

class UserFixture {
  page: Page;
  user: User;

  constructor(page: Page, user: User) {
    this.page = page;
    this.user = user;
  }
}

type MaMpfFixtures = {
  student: UserFixture;
  student2: UserFixture;
  admin: UserFixture;
  teacher: UserFixture;
  tutor: UserFixture;
  factory: FactoryBot;
};

export * from "@playwright/test";
export const test = base.extend<MaMpfFixtures>({
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

  factory: async ({ browser }, use) => {
    const browserContext = await browser.newContext();
    const page = await browserContext.newPage();
    await use(new FactoryBot(page.request));
    await browserContext.close();
  },
});
