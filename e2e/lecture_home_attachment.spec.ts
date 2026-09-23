import { readFileSync } from "node:fs";

import { expect, test } from "./_support/fixtures";
import { LectureEditPage } from "./page-objects/lecture_edit_page";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test("teacher puts a program on the home page and a student can open it", async ({
  factory,
  teacher,
  student,
}) => {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacher.user.id,
    locale: "en",
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
