import { readFileSync } from "node:fs";
import { join } from "node:path";

/**
 * Number of Playwright workers. Each worker gets its own app server (and thus
 * its own test database), started by `docker/development/run.sh`.
 *
 * `e2e-workers.sh` (called by `init.sh`) writes the number of servers to
 * `tmp/e2e-workers`, so this always matches the servers.
 */
export const workerCount = Number(
  readFileSync(join(process.cwd(), "tmp/e2e-workers"), "utf8").trim(),
);

/**
 * Origin of the app server for the worker with the given `parallelIndex`.
 *
 * Worker 0 uses the regular app server on port 3145, worker `i` the one on
 * port `3145 + 10 * i`. Keep this in sync with `docker/development/run.sh`.
 */
export function appOrigin(parallelIndex: number): string {
  return `http://app-test:${3145 + 10 * parallelIndex}`;
}
