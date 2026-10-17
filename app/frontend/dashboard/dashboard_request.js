/**
 * Sends a change to one of the dashboard's endpoints. They answer with a Turbo
 * Stream, or with JSON when `json` is given as the request body.
 *
 * The server answers a stale CSRF token, e.g. after a sign-in in another tab,
 * with 422 and an alert for the next page. Reloading gives the page a fresh
 * token.
 */
export async function sendDashboardRequest(url, method, json = null) {
  const headers = {
    Accept: json ? "application/json" : "text/vnd.turbo-stream.html",
  };
  // absent where forgery protection is off, e.g. the test environment
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  if (json) headers["Content-Type"] = "application/json";

  const response = await fetch(url, {
    method,
    headers,
    body: json ? JSON.stringify(json) : undefined,
  });
  if (response.status === 422) window.location.reload();

  return response;
}
