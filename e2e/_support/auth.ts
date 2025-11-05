import { APIRequestContext, expect } from "@playwright/test";
import { callBackend } from "./backend";

export async function loginStudent(context: APIRequestContext) {
  const user = await callBackend(context, "user_creator", { role: "student" });
  console.log("Created user:", user);

  const response = await context.post("/users/sign_in", {
    form: {
      "user[email]": user.email,
      "user[password]": user.password,
    },
  });

  expect(response.status()).toEqual(200);
  const responseBody = await response.text();
  expect(responseBody).toBeDefined();
  expect(responseBody).not.toMatch(/data-cy\s*=\s*["']?login-form["']?/);
}
