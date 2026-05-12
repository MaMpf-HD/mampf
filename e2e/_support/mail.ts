import { APIRequestContext } from "@playwright/test";
import { callBackend } from "./backend";

type MailDelivery = {
  subject: string;
  to: string[];
  text_body?: string;
  html_body?: string;
  urls: string[];
};

export async function latestMail(
  context: APIRequestContext,
  recipient: string,
): Promise<MailDelivery> {
  return await callBackend(context, "mails_playwright", { recipient }) as MailDelivery;
}

function toRelativeAppUrl(url: string): string {
  const parsedUrl = new URL(url);
  return `${parsedUrl.pathname}${parsedUrl.search}${parsedUrl.hash}`;
}

async function mailLinkFor(
  context: APIRequestContext,
  recipient: string,
  pathFragment: string,
): Promise<string> {
  const mail = await latestMail(context, recipient);
  const url = mail.urls.find(candidate => candidate.includes(pathFragment));

  if (!url) {
    throw new Error(`No ${pathFragment} URL found in mail for ${recipient}`);
  }

  return toRelativeAppUrl(url);
}

export async function confirmationLinkFor(
  context: APIRequestContext,
  recipient: string,
): Promise<string> {
  return await mailLinkFor(context, recipient, "/users/confirmation");
}

export async function resetPasswordLinkFor(
  context: APIRequestContext,
  recipient: string,
): Promise<string> {
  return await mailLinkFor(context, recipient, "/users/password/edit");
}
