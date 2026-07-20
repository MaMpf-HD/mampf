/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { APIRequestContext } from "@playwright/test";

export async function callBackend(
  context: APIRequestContext, routeName: string, payload: object): Promise<object> {
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

export async function enableFeature(
  context: APIRequestContext, featureName: string): Promise<void> {
  await callBackend(context, "feature_flags/enable", { name: featureName });
}

export async function disableFeature(
  context: APIRequestContext, featureName: string): Promise<void> {
  await callBackend(context, "feature_flags/disable", { name: featureName });
}
