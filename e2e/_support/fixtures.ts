import { test as base, expect, Page } from "@playwright/test";
import { User, userPage } from "./auth";
import { callBackend } from "./backend";
import { CspViolation, watchCsp } from "./csp";
import { FactoryBot } from "./factorybot";
import { appOrigin } from "./servers";
import { TimeCop } from "./timecop";

class UserFixture {
  page: Page;
  user: User;

  constructor(page: Page, user: User) {
    this.page = page;
    this.user = user;
  }
}

type MaMpfFixtures = {
  _forEachTest: Array<void>;
  cspViolations: CspViolation[];
  student: UserFixture;
  student2: UserFixture;
  admin: UserFixture;
  teacher: UserFixture;
  tutor: UserFixture;
  tutor2: UserFixture;
  factory: FactoryBot;
  timeCop: TimeCop;
};

export * from "@playwright/test";
export const test = base.extend<MaMpfFixtures>({
  // Each worker talks to its own app server (and thus its own database).
  // `parallelIndex` stays the same when a worker restarts after a failure.
  // eslint-disable-next-line no-empty-pattern
  baseURL: async ({}, use, testInfo) => {
    await use(appOrigin(testInfo.parallelIndex));
  },

  // https://playwright.dev/docs/test-fixtures#adding-global-beforeeachaftereach-hooks
  _forEachTest: [
    async ({ request }, use) => {
      // Clean database before every test (brutal, but effective for good test isolation)
      await callBackend(request, "database_cleaner", {});
      await use([]);
    }, { auto: true },
  ],

  // A test fails if the Content Security Policy blocked something on a page
  // it opened, so a script the policy does not let run cannot go unnoticed.
  cspViolations: [
    // eslint-disable-next-line no-empty-pattern
    async ({}, use) => {
      const violations: CspViolation[] = [];
      await use(violations);
      expect(violations).toEqual([]);
    }, { auto: true },
  ],

  context: async ({ context, cspViolations }, use) => {
    await watchCsp(context, cspViolations);
    await use(context);
  },

  student: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "student", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  student2: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "student2", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  admin: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "admin", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  teacher: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "teacher", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  tutor: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "tutor", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  tutor2: async ({ browser, cspViolations }, use) => {
    const [user, page, browserContext] = await userPage(browser, "tutor2", cspViolations);
    const fixture = new UserFixture(page, user);
    await use(fixture);
    await browserContext.close();
  },

  factory: async ({ request }, use) => {
    await use(new FactoryBot(request));
  },

  // The server's clock, put back after the test whether it passed, failed or
  // timed out; a test that moved it and left it would move every test after.
  timeCop: async ({ request }, use) => {
    const timeCop = new TimeCop(request);
    await use(timeCop);
    await timeCop.reset();
  },
});
