/**
 * Sends a change to one of the dashboard's endpoints. They answer with a Turbo
 * Stream, or with JSON when `json` is given as the request body.
 */
export function sendDashboardRequest(url, method, json = null) {
  const headers = {
    Accept: json ? "application/json" : "text/vnd.turbo-stream.html",
  };
  // absent where forgery protection is off, e.g. the test environment
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  if (json) headers["Content-Type"] = "application/json";

  return fetch(url, {
    method,
    headers,
    body: json ? JSON.stringify(json) : undefined,
  });
}
