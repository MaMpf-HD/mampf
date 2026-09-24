import { readFileSync } from "node:fs";

import { type FactoryBot } from "./_support/factorybot";
import { expect, type Page, test } from "./_support/fixtures";
import { LectureEditPage } from "./page-objects/lecture_edit_page";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test("teacher puts a program on the home page and a student can open it", async ({
  factory,
  teacher,
  student,
}) => {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacher.user.id,
  });

  const editPage = new LectureEditPage(teacher.page, lecture.id);
  await editPage.goto();
  await editPage.homeTab.click();
  await teacher.page.getByLabel("Program (PDF)").setInputFiles("e2e/files/manuscript.pdf");
  await teacher.page.getByRole("button", { name: "Save" }).click();

  await expect(teacher.page.getByRole("link", { name: "manuscript.pdf" })).toBeVisible();

  await new CampaignRegistrationPage(student.page, lecture.id).goto();
  const offer = student.page.getByRole("link", { name: "Download program (PDF)" });
  await expect(offer).toBeVisible();
  const response = await student.page.request.get(await offer.getAttribute("href") ?? "");
  expect(response.ok()).toBe(true);
  expect((await response.body()).equals(readFileSync("e2e/files/manuscript.pdf")))
    .toBe(true);
});

test.describe("a program the home page cannot take", () => {
  async function openHomeTab(factory: FactoryBot, page: Page, teacherId: number) {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacherId,
    });
    const editPage = new LectureEditPage(page, lecture.id);
    await editPage.goto();
    await editPage.homeTab.click();
    return page.getByLabel("Program (PDF)");
  }

  test("names a file that is not a PDF", async ({ factory, teacher }) => {
    const field = await openHomeTab(factory, teacher.page, teacher.user.id);
    await field.setInputFiles({
      name: "notes.pdf", mimeType: "application/pdf", buffer: Buffer.from("just some text"),
    });
    await teacher.page.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByText("The attachment must be a PDF.")).toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "notes.pdf" })).toHaveCount(0);
    await expect(teacher.page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  test("keeps a file above the limit in the browser", async ({ factory, teacher }) => {
    const field = await openHomeTab(factory, teacher.page, teacher.user.id);
    const sent: string[] = [];
    teacher.page.on("request", (request) => {
      if (request.url().includes("/home_content")) sent.push(request.url());
    });

    await field.setInputFiles({
      name: "huge.pdf", mimeType: "application/pdf",
      buffer: Buffer.alloc(10 * 1024 * 1024 + 1, "%"),
    });
    await teacher.page.getByRole("button", { name: "Save" }).click();

    await expect(field).toHaveJSProperty("validationMessage", "The file is larger than 10 MB.");
    expect(sent).toHaveLength(0);
  });

  // nginx answers before the app sees the request; its answer is faked for
  // every save of the lecture.
  async function refuseSaves(page: Page, status: number, contentType: string, body: string) {
    await page.route("**/lectures/**", async (route) => {
      if (route.request().method() === "GET") return route.continue();
      await route.fulfill({ status, contentType, body });
    });
  }

  test("says so when the proxy finds the upload too large", async ({ factory, teacher }) => {
    const field = await openHomeTab(factory, teacher.page, teacher.user.id);
    await refuseSaves(teacher.page, 413, "text/html", "<html><body>413</body></html>");

    await field.setInputFiles("e2e/files/manuscript.pdf");
    await teacher.page.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByRole("alert")).toHaveText("The file is larger than 10 MB.");
    await expect(teacher.page.getByText("Content missing")).toHaveCount(0);
  });

  test("says so when the proxy turns the upload away", async ({ factory, teacher }) => {
    const field = await openHomeTab(factory, teacher.page, teacher.user.id);
    await refuseSaves(teacher.page, 403, "text/plain", "not allowed");

    await field.setInputFiles("e2e/files/manuscript.pdf");
    await teacher.page.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByRole("alert"))
      .toHaveText("Saving did not work. Please try again. (403)");
  });
});
