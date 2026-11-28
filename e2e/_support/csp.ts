import { BrowserContext } from "@playwright/test";

export type CspViolation = {
  page: string;
  directive: string;
  blocked: string;
  source: string;
};

declare global {
  interface Window {
    reportCspViolation: (_violation: CspViolation) => void;
  }
}

/**
 * Notes in `violations` whatever the Content Security Policy blocks on a page
 * of the browser context, for example an inline script without a nonce.
 */
export async function watchCsp(
  context: BrowserContext,
  violations: CspViolation[],
) {
  await context.exposeBinding(
    "reportCspViolation",
    (_source, violation: CspViolation) => {
      violations.push(violation);
    },
  );
  await context.addInitScript(() => {
    document.addEventListener("securitypolicyviolation", (event) => {
      window.reportCspViolation({
        page: document.location.pathname,
        directive: event.effectiveDirective,
        blocked: event.blockedURI,
        source: `${event.sourceFile}:${event.lineNumber}`,
      });
    });
  });
}
