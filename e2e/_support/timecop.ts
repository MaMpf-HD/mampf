import { APIRequestContext } from "@playwright/test";
import { callBackend } from "./backend";

/**
 * Moves the server's clock. Only the server travels - the browser keeps its own
 * time - so use it for what the backend decides (a deadline passing, a grace
 * period running out), not for anything the page works out in JavaScript.
 *
 * Reach it through the `clock` fixture, which puts the clock back when the
 * test ends - however it ends. A `finally` in the test cannot: after a timeout
 * the browser contexts are gone before it runs, and every test after inherits
 * the date.
 */
export class Clock {
  private readonly context: APIRequestContext;

  constructor(context: APIRequestContext) {
    this.context = context;
  }

  async travelTo(when: Date): Promise<void> {
    // Sent as UTC parts: the runner and the server need not agree on a zone, and
    // an hour's difference is exactly the kind that makes a deadline test lie.
    await callBackend(this.context, "timecop/travel", {
      year: when.getUTCFullYear(),
      month: when.getUTCMonth() + 1,
      day: when.getUTCDate(),
      hours: when.getUTCHours(),
      minutes: when.getUTCMinutes(),
      seconds: when.getUTCSeconds(),
      use_utc: "true",
    });
  }

  async reset(): Promise<void> {
    await callBackend(this.context, "timecop/reset", {});
  }
}
