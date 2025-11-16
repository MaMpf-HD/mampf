/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { APIRequestContext } from "@playwright/test";

export async function callBackend(
  context: APIRequestContext, routeName: string, payload: object): Promise<object> {
  console.log("route name:", routeName);
  const response = await context.post(`cypress/${routeName}`, {
    data: payload,
    headers: {
      "content-type": "application/json",
    },
    failOnStatusCode: false,
  });

  const body = await response.json();

  if (response.status() === 201) {
    return body;
  }

  let errorMsg = `Call to Rails Backend failed: ${body.error}`;
  errorMsg += `\n\nStacktrace:\n${body.stacktrace}`;
  throw new Error(errorMsg);
}
