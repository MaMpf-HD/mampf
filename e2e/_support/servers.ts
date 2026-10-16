import { availableParallelism } from "node:os";

/**
 * Number of Playwright workers. Each worker gets its own app server (and thus
 * its own test database), started by `docker/development/run.sh`.
 *
 * 60% of the cores, rounded (each worker runs a browser and a Rails server).
 * Override via `E2E_WORKERS`. Keep in sync with
 * `docker/development/e2e-workers.sh`.
 */
export const workerCount = Number(
  process.env.E2E_WORKERS ?? Math.max(1, Math.round(availableParallelism() * 0.6)),
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
