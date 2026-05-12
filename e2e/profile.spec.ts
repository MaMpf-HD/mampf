import { expect, test } from "./_support/fixtures";
import { confirmationLinkFor } from "./_support/mail";
import { MediumCommentsPage } from "./page-objects/comments_page";
import { LecturePage } from "./page-objects/lecture_page";
import { ProfilePage } from "./page-objects/profile_page";
import { SubmissionsPage } from "./page-objects/submissions_page";
import { TutorialsPage } from "./page-objects/tutorials_page";

async function login(page: import("@playwright/test").Page, email: string,
  password: string) {
  await page.goto("/users/sign_in?locale=en");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Login" }).click();
}

test.describe("Account settings", () => {
  test("can change user name & reflects it in user comments",
    async ({ factory, student: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
      const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
      const medium = await factory.create("lesson_medium", ["released", "with_lesson_by_id"], { lesson_id: lesson.id });

      const profilePage = new ProfilePage(page);
      const commentsPage = new MediumCommentsPage(page, medium.id);

      await profilePage.goto();
      await expect(page.getByRole("textbox", { name: "display name" })).toHaveValue(user.name);
      await commentsPage.goto();
      const COMMENT = "Super comment";
      await commentsPage.postComment(COMMENT);
      await expect(page.getByText(user.name)).toBeVisible();
      await expect(page.getByText(COMMENT)).toBeVisible();

      const newName = "Jean-Jacques Rousseau";
      await profilePage.goto();
      await page.getByRole("textbox", { name: "display name" }).fill(newName);
      await profilePage.save();
      await commentsPage.goto();
      await expect(page.getByText(newName)).toBeVisible();
      await expect(page.getByText(COMMENT)).toBeVisible();
    });

  test("can change user name in tutorials & reflects it in submissions",
    async ({ factory, student: { page, user }, tutor: { page: tutorPage, user: tutorUser } }) => {
      const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
      await factory.create("assignment", [], { lecture_id: lecture.id });

      const profilePage = new ProfilePage(page);
      await profilePage.goto();
      const originalNameInTutorials = user.name_in_tutorials;
      await expect(page.getByRole("textbox", { name: "name in tutorials" })).toHaveValue(originalNameInTutorials);
      const newName = "Voltaire";
      await page.getByRole("textbox", { name: "name in tutorials" }).fill(newName);
      await profilePage.save();

      await factory.create("tutorial", ["with_tutor_by_id"],
        { lecture_id: lecture.id, tutor_id: tutorUser.id });
      await new LecturePage(page, lecture.id).subscribe();
      const submissionsPage = new SubmissionsPage(page, lecture.id);
      await submissionsPage.goto();
      await submissionsPage.createSubmission();

      await new TutorialsPage(tutorPage, lecture.id).goto();
      await expect(tutorPage.getByText(newName)).toBeVisible();
      await expect(tutorPage.getByText(originalNameInTutorials)).toHaveCount(0);
      await expect(tutorPage.getByText(user.name)).toHaveCount(0);
      // because user name was changed
      await expect(tutorPage.getByText(user.name_in_tutorials)).toHaveCount(0);
    });

  test("can switch the user language",
    async ({ student: { page } }) => {
      const profilePage = new ProfilePage(page);
      await profilePage.goto();

      await expect(page.getByRole("radio", { name: "english" })).toBeChecked();
      await expect(page.getByText("display name")).toBeVisible();
      await expect(page.getByText("receive email")).toBeVisible();
      await expect(page.getByText("want to see related")).toBeVisible();

      await page.getByRole("radio", { name: "german" }).check();
      await profilePage.save();
      await expect(page.getByRole("radio", { name: "deutsch" })).toBeChecked();
      await expect(page.getByText("anzeigename")).toBeVisible();
      await expect(page.getByText("benachrichtigt")).toBeVisible();
      await expect(page.getByText("möchte verknüpfte")).toBeVisible();
    });

  test("can change the email address and confirm it",
    async ({ student: { page, user }, request }) => {
      const profilePage = new ProfilePage(page);
      const newEmail = `updated_${Date.now()}@example.com`;

      await profilePage.goto();
      await page.getByRole("link", { name: "Change login data" }).click();
      await expect(page).toHaveURL(/\/users\/edit/);

      await page.locator("#user_email").fill(newEmail);
      await page.getByLabel("Current password", { exact: true }).fill(user.password);
      await page.getByRole("button", { name: "Update" }).click();

      await expect(page.getByRole("alert")).toBeVisible();

      const confirmationLink = await confirmationLinkFor(request, newEmail);
      await page.goto(confirmationLink);

      await expect(page).toHaveURL(/\/profile\/edit/);

      await page.locator('a[title="Logout"]').click();
      await expect(page).not.toHaveURL(/\/profile\/edit/);

      await login(page, user.email, user.password);
      await expect(page).toHaveURL(/\/users\/sign_in/);
      await expect(page.getByRole("alert")).toBeVisible();

      await login(page, newEmail, user.password);
      await expect(page).toHaveURL(/\/main\/start/);
    });
});

test.describe("Module settings", () => {
  test("can subscribe to a lecture (via profile page)",
    async ({ factory, student: { page } }) => {
      const divisionName = "Fourier Division";
      const courseName = "Happy Calculus 101";
      const division = await factory.create("division", [], { name: divisionName });
      const course = await factory.create("course", ["with_division"], { title: courseName, division_id: division.id });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: course.id });
      const teacher = await lecture.__call("teacher");

      const profilePage = new ProfilePage(page);
      await profilePage.goto();
      await page.getByTestId("courses-accordion").getByRole("button").first().click();
      await expect(page.getByTestId("courses-accordion")).toContainText(divisionName);
      const courseButton = page.getByText(courseName);
      await courseButton.click();
      await page.getByText(teacher.name).click();
      await profilePage.save();

      await page.goto("/");
      const furtherSubscribed = page.getByTestId("further-subscribed");
      await expect(furtherSubscribed).toContainText(courseName);
      await expect(furtherSubscribed).toContainText(teacher.name);
    });
});
