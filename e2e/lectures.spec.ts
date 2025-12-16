import { expect, Page, test } from "./_support/fixtures";

test("shows content tab button", async ({ factory, teacher: { page, user } }) => {
  const lecture = await factory.create("lecture", [], { teacher_id: user.id });

  await page.goto(`/lectures/${lecture.id}/edit`);
  await expect(page.getByTestId("content-tab-btn")).toBeVisible();
});

async function searchForUserInTomSelect(
  page: Page,
  containerSelector: string,
  user: any,
  waitForAjax = true,
) {
  const container = page.getByTestId(containerSelector);
  const input = container.locator("input:not([type='hidden'])").first();

  await input.fill(user.email);

  if (waitForAjax) {
    await page.waitForResponse(resp => resp.url().includes("/users/fill_user_select"));
  }
}

async function expectUsersInDropdown(
  page: Page,
  containerSelector: string,
  user: any,
  shouldBeVisible: boolean,
) {
  const container = page.getByTestId(containerSelector).first();
  const assertion = shouldBeVisible ? expect(container) : expect(container).not;

  await assertion.toContainText(user.email);
}

test.describe("Lecture people edit page: teacher & editor", () => {
  test.describe("when logged in as teacher", () => {
    test("does not show element to select teacher", async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });

      await page.goto(`/lectures/${lecture.id}/edit?tab=people`);

      // Teachers cannot change the teacher (only admins can)
      const teacherSelect = page.getByTestId("teacher-select");
      await expect(teacherSelect.getByTestId("teacher-admin-select")).not.toBeVisible();
      await expect(teacherSelect.getByTestId("teacher-info")).toBeVisible();
    });

    test("prohibits searching for arbitrary users in the editor dropdown",
      async ({ factory, teacher: { page, user }, student }) => {
        const lecture = await factory.create("lecture", [], { teacher_id: user.id });

        await page.goto(`/lectures/${lecture.id}/edit?tab=people`);

        // Search for users - should NOT find arbitrary users (non-admin restriction)
        await searchForUserInTomSelect(page, "editor-select", student.user, false);
        await expectUsersInDropdown(page, "editor-select", student.user, false);
      });

    test("prohibits searching for arbitrary users in the tutor dropdown",
      async ({ factory, teacher: { page, user }, student }) => {
        const lecture = await factory.create("lecture", [], { teacher_id: user.id });

        await page.goto(`/lectures/${lecture.id}/edit?tab=people`);
        await page.getByTestId("new-tutorial-btn").click();

        // Search for users - should NOT find arbitrary users (non-admin restriction)
        await searchForUserInTomSelect(page, "tutor-select-div", student.user, false);
        await expectUsersInDropdown(page, "tutor-select-div", student.user, false);
      });
  });

  test.describe("when logged in as admin", () => {
    test("allows searching for arbitrary users to assign them as teachers",
      async ({ factory, admin: { page }, teacher }) => {
        const lecture = await factory.create("lecture", [], { teacher_id: teacher.user.id });

        await page.goto(`/lectures/${lecture.id}/edit?tab=people`);

        // Admins can search and find any user
        await searchForUserInTomSelect(page, "teacher-select", teacher.user);
        await expectUsersInDropdown(page, "teacher-select", teacher.user, true);
      });

    test("allows searching for arbitrary users to assign them as editors",
      async ({ factory, admin: { page }, student, teacher }) => {
        const lecture = await factory.create("lecture", [], { teacher_id: teacher.user.id });

        await page.goto(`/lectures/${lecture.id}/edit?tab=people`);

        // Admins can search and find any user
        await searchForUserInTomSelect(page, "editor-select", student.user);
        await expectUsersInDropdown(page, "editor-select", student.user, true);
      });

    test("allows to search for arbitrary users to assign them as tutors",
      async ({ factory, admin: { page }, student, teacher }) => {
        const lecture = await factory.create("lecture", [], { teacher_id: teacher.user.id });

        await page.goto(`/lectures/${lecture.id}/edit?tab=people`);
        await page.getByTestId("new-tutorial-btn").click();

        // Admins can search and find any user
        await searchForUserInTomSelect(page, "tutor-select-div", student.user);
        await expectUsersInDropdown(page, "tutor-select-div", student.user, true);
      });
  });
});

test.describe("Seminar speakers (new talk)", () => {
  async function openTalkForm(page: Page) {
    await page.getByTestId("new-talk-btn").click();
    await page.waitForResponse(resp => resp.url().includes("/talks/new"));
    await page.waitForTimeout(500); // Wait for form initialization
  }

  test.describe("when logged in as teacher", () => {
    test("prohibits searching for arbitrary users in the speakers dropdown",
      async ({ factory, teacher: { page, user: teacher }, student }) => {
        const seminar = await factory.create("seminar", [], { teacher_id: teacher.id });

        await page.goto(`/lectures/${seminar.id}/edit`);
        await openTalkForm(page);

        // Search for users - should NOT find arbitrary users (non-admin restriction)
        await searchForUserInTomSelect(page, "speaker-select-div", student.user, false);
        await expectUsersInDropdown(page, "speaker-select-div", student.user, false);
      });
  });

  test.describe("when logged in as admin", () => {
    test("allows searching for arbitrary users to assign them as speakers",
      async ({ factory, admin: { page }, student, teacher }) => {
        const seminar = await factory.create("seminar", [], { teacher_id: teacher.user.id });

        await page.goto(`/lectures/${seminar.id}/edit`);
        await openTalkForm(page);

        // Admins can search and find any user
        await searchForUserInTomSelect(page, "speaker-select-div", student.user);
        await expectUsersInDropdown(page, "speaker-select-div", student.user, true);
      });
  });
});

test.describe("Seminar speakers (existing talk)", () => {
  test.describe("when logged in as teacher", () => {
    test("prohibits searching for arbitrary users in the speakers dropdown",
      async ({ factory, teacher: { page, user: teacher }, student, student2 }) => {
        const seminar = await factory.create("seminar", [], { teacher_id: teacher.id });
        const talk = await factory.create("talk", [],
          { lecture_id: seminar.id, speaker_ids: [student.user.id] });

        await page.goto(`/talks/${talk.id}/edit`);

        // Search for users - should NOT find arbitrary users (non-admin restriction)
        await searchForUserInTomSelect(page, "speaker-select-div", student2.user, false);
        await expectUsersInDropdown(page, "speaker-select-div", student2.user, false);
      });
  });

  test.describe("when logged in as admin", () => {
    test("allows searching for arbitrary users to assign them as speakers",
      async ({ factory, admin: { page }, student, student2, teacher }) => {
        const seminar = await factory.create("seminar", [], { teacher_id: teacher.user.id });
        const talk = await factory.create("talk", [],
          { lecture_id: seminar.id, speaker_ids: [student.user.id] });

        await page.goto(`/talks/${talk.id}/edit`);

        // Admins can search and find any user
        await searchForUserInTomSelect(page, "speaker-select-div", student2.user);
        await expectUsersInDropdown(page, "speaker-select-div", student2.user, true);
      });
  });
});
