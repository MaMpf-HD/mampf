import { test as base, Page } from "@playwright/test";
import { User, userPage } from "./auth";
import { callBackend } from "./backend";
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

  factory: async ({ request }, use) => {
    await use(new FactoryBot(request));
  },
});

test.beforeEach(async ({ request }) => {
  // Clean database before every test (brutal, but effective for good test isolation)
  await callBackend(request, "database_cleaner", {});
});
