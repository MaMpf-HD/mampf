import { APIRequestContext } from "@playwright/test";
import { callBackend } from "./backend";

/**
 * Moves the server's clock. Only the server travels - the browser keeps its own
 * time - so use it for what the backend decides (a deadline passing, a grace
 * period running out), not for anything the page works out in JavaScript.
 *
 * Always pair a `travelTo` with a `resetClock`, or every test after it inherits
 * the new date.
 */
export async function travelTo(
  context: APIRequestContext, when: Date,
): Promise<void> {
  // Sent as UTC parts: the runner and the server need not agree on a zone, and
  // an hour's difference is exactly the kind that makes a deadline test lie.
  await callBackend(context, "timecop/travel", {
    year: when.getUTCFullYear(),
    month: when.getUTCMonth() + 1,
    day: when.getUTCDate(),
    hours: when.getUTCHours(),
    minutes: when.getUTCMinutes(),
    seconds: when.getUTCSeconds(),
    use_utc: "true",
  });
}

export async function resetClock(context: APIRequestContext): Promise<void> {
  await callBackend(context, "timecop/reset", {});
}
