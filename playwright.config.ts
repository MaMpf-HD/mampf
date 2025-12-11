import { defineConfig, devices } from "@playwright/test";

/**
 * See https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: "./e2e/",
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests. */
  workers: 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: "html",
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('')`. */
    baseURL: "http://app-test:3145",

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: "on-first-retry",
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        // Use new Chromium headless mode:
        // https://playwright.dev/docs/browsers#chromium-new-headless-mode
        // We need this since the old headless mode has this bug
        // https://issues.chromium.org/issues/40168268
        // see also: https://github.com/microsoft/playwright/issues/22944
        channel: "chromium",
        // https://dev.to/muhendiskedibey/how-to-full-screen-a-browser-in-playwright-1np1
        deviceScaleFactor: undefined,
        viewport: {
          width: 1920,
          height: 1080,
        },
        launchOptions: {
          args: [
            "--start-maximized",
            // Required for the Altcha Captcha to work in the test environment
            // (HTTP, not HTTPS). Browsers usually only consider localhost
            // or HTTPS are secure origins. The secure context is needed, such that
            // Playwright can use the browser's Web Crypto API to solve the captcha.
            "--unsafely-treat-insecure-origin-as-secure=http://app-test:3145",
          ],
        },
      },
    },
  ],
});
