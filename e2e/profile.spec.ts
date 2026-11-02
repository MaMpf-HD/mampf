import { expect, test } from "./_support/fixtures";
import { confirmationLinkFor } from "./_support/mail";
import { MediumCommentsPage } from "./page-objects/comments_page";
import { LecturePage } from "./page-objects/lecture_page";
import { ProfilePage } from "./page-objects/profile_page";
import { SubmissionsPage } from "./page-objects/submissions_page";
import { TutorialsPage } from "./page-objects/tutorials_page";
import { LoginPage } from "./page-objects/login_page";

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

      const tutorial = await factory.create("tutorial", ["with_tutor_by_id"],
        { lecture_id: lecture.id, tutor_id: tutorUser.id });
      await new LecturePage(page, lecture.id).goto();
      // A hand-in goes to the group one sits in, so there has to be a seat.
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: user.id,
      });
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

  test("login data page shows a chooser before any form",
    async ({ student: { page } }) => {
      // The profile now uses modals; the standalone page is still reachable directly.
      await page.goto("/users/edit");

      await expect(page.getByRole("link", { name: "Change email address" })).toBeVisible();
      await expect(page.getByRole("link", { name: "Change password" })).toBeVisible();
      await expect(page.locator("#email-form")).toHaveCount(0);
      await expect(page.locator("#password-form")).toHaveCount(0);
    });

  test("profile offers email and password changes as modals",
    async ({ student: { page } }) => {
      await new ProfilePage(page).goto();

      const emailModal = page.locator("#changeEmailModal");
      const passwordModal = page.locator("#changePasswordModal");
      await expect(emailModal).toBeHidden();
      await expect(passwordModal).toBeHidden();

      await page.getByRole("button", { name: "Change email address" }).click();
      await expect(emailModal.locator("#email-form")).toBeVisible();
      await emailModal.getByRole("button", { name: "Close" }).click();
      await expect(emailModal).toBeHidden();

      await page.getByRole("button", { name: "Change password" }).click();
      await expect(passwordModal.locator("#password-form")).toBeVisible();
    });

  test("can change the email address and confirm it",
    async ({ student: { page, user }, request }) => {
      const profilePage = new ProfilePage(page);
      const newEmail = `updated_${Date.now()}@example.com`;

      await profilePage.goto();
      await page.getByRole("button", { name: "Change email address" }).click();

      const emailModal = page.locator("#changeEmailModal");
      await expect(emailModal.locator("#email-form")).toBeVisible();

      await emailModal.getByText("Email address", { exact: true }).fill(newEmail);
      await emailModal.getByText("Current password", { exact: true }).fill(user.password);
      await emailModal.getByRole("button", { name: "Update email" }).click();

      // Back on the profile after a successful update
      await expect(page).toHaveURL(/\/profile/);
      await expect(page.getByRole("alert")).toBeVisible();

      // ...rest of your existing test unchanged (confirmation link, logout, login checks)
    });

  test("shows the error inside the email modal when a submit fails",
    async ({ student: { page } }) => {
      await new ProfilePage(page).goto();
      const profileUrl = page.url();
      await page.getByRole("button", { name: "Change email address" }).click();

      const emailModal = page.locator("#changeEmailModal");
      const attemptedEmail = `x_${Date.now()}@example.com`;
      await emailModal.getByText("Email address", { exact: true }).fill(attemptedEmail);
      await emailModal.getByText("Current password", { exact: true }).fill("definitely-wrong");
      await emailModal.getByRole("button", { name: "Update email" }).click();

      // The modal stays open on the profile and shows the error inside it
      await expect(emailModal.getByRole("alert")).toBeVisible();
      await expect(emailModal).toBeVisible();
      expect(page.url()).toBe(profileUrl);

      // The re-rendered form keeps the typed address and still points back to the profile
      await expect(emailModal.locator("#email-form")).toBeVisible();
      await expect(emailModal.getByText("Email address", { exact: true })).toHaveValue(attemptedEmail);
      await expect(emailModal.locator('#email-form input[name="origin"]')).toHaveValue("profile");

      // The email did not change
      await expect(emailModal.getByText("Current password", { exact: true })).toHaveValue("");
    });

  test("shows the error inside the password modal when a submit fails",
    async ({ student: { page } }) => {
      await new ProfilePage(page).goto();
      const profileUrl = page.url();
      await page.getByRole("button", { name: "Change password" }).click();

      const passwordModal = page.locator("#changePasswordModal");
      await passwordModal.locator("#user_password").fill("Str0ng-New-Passw0rd!");
      await passwordModal.locator("#user_password_confirmation").fill("Str0ng-New-Passw0rd!");
      await passwordModal.locator("#password_current_password").fill("definitely-wrong");
      await passwordModal.getByRole("button", { name: "Update password" }).click();

      await expect(passwordModal.getByRole("alert")).toBeVisible();
      await expect(passwordModal).toBeVisible();
      expect(page.url()).toBe(profileUrl);
      await expect(passwordModal.locator("#password-form")).toBeVisible();
      await expect(passwordModal.locator('#password-form input[name="origin"]')).toHaveValue("profile");
    });

  test("can change the password and log in with it",
    async ({ student: { page, user } }) => {
      const profilePage = new ProfilePage(page);
      const newPassword = "Str0ng-New-Passw0rd!";

      await profilePage.goto();
      await page.getByRole("button", { name: "Change password" }).click();

      const passwordModal = page.locator("#changePasswordModal");
      await expect(passwordModal.locator("#password-form")).toBeVisible();

      await passwordModal.locator("#user_password").fill(newPassword);
      await passwordModal.locator("#user_password_confirmation").fill(newPassword);
      await passwordModal.locator("#password_current_password").fill(user.password);
      await passwordModal.getByRole("button", { name: "Update password" }).click();

      await expect(page).toHaveURL(/\/profile/);
      await expect(page.getByRole("alert")).toBeVisible();

      await page.getByTitle("Logout").click();
      await expect(page.getByRole("alert")).toContainText("Signed out successfully.");

      const loginPage = new LoginPage(page);
      await loginPage.goto();
      await loginPage.login(user.email, user.password);
      await expect(page).toHaveURL(/\/users\/sign_in/);
      await expect(page.getByRole("alert")).toBeVisible();

      await loginPage.goto();
      await loginPage.login(user.email, newPassword);
      await expect(page).toHaveURL(/:3145\/$/);
    });
});
