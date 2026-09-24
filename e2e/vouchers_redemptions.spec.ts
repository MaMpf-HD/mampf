import { expect, Locator, Page, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { FactoryBot, FactoryBotObject } from "./_support/factorybot";

type Role = "tutor" | "editor" | "teacher" | "speaker";
type Claimable = "tutorial" | "talk";

const ROLE_NAMES: Record<Role, string> = {
  tutor: "Tutor", editor: "Editor", teacher: "Teacher", speaker: "Speaker",
};

const REDEMPTION_TEXTS: Record<Role, string> = {
  tutor: "With this voucher, you obtain tutor status for",
  editor: "With this voucher, you obtain editor status for",
  teacher: "With this voucher, you obtain teacher status for",
  speaker: "With this voucher, you will obtain speaker status for the seminar",
};

const SUCCESS_MESSAGES: Record<Role, string> = {
  tutor: "Your tutor status has been updated.",
  editor: "Your editor status has been updated.",
  teacher: "Your teacher status has been updated.",
  speaker: "Your speaker status has been updated.",
};

const ALREADY_REDEEMED_MESSAGES: Record<Role, string> = {
  tutor: "You have already redeemed this voucher to become a tutor.",
  editor: "You have already redeemed an editor voucher for this event series.",
  teacher: "You are already the teacher for",
  speaker: "You have already redeemed this voucher to become a speaker.",
};

const NOTHING_TO_CLAIM_MESSAGES: Record<Claimable, string> = {
  tutorial: "After having redeemed the voucher, the teacher can assign you to the tutorials.",
  talk: "After having redeemed the voucher, the teacher can assign you to the talks.",
};

const NOTHING_CLAIMED_MESSAGES: Record<Claimable, string> = {
  tutorial: "No tutorials have been taken over by the redemption.",
  talk: "No talks have been taken over by the redemption.",
};

const CLAIM_PROMPTS: Record<Claimable, string> = {
  tutorial: "Select Tutorials", talk: "Select Talks",
};

// Fixed titles, since the bridge's title methods answer in the default locale
// (German) while the pages speak the user's (English).
const COURSE_TITLE = "Symplectic Geometry";
const COURSE_SHORT_TITLE = "SymplGeo";

async function lectureWithVoucher(
  factory: FactoryBot, teacherId: number, role: Role, sort: "lecture" | "seminar" = "lecture",
) {
  const course = await factory.create("course", [], {
    title: COURSE_TITLE, short_title: COURSE_SHORT_TITLE,
  });
  const lecture = await factory.create("lecture", [], {
    course_id: course.id, teacher_id: teacherId, sort,
  });
  // The role goes in as a trait: speaker vouchers are no longer issued, and
  // the trait builds one that is still in circulation.
  const voucher = await factory.create("voucher", [role], { lecture_id: lecture.id });
  return { lecture, voucher };
}

/** With a user, every tutorial or talk is theirs already, so none is left to claim. */
async function createClaimables(
  factory: FactoryBot, lectureId: number, type: Claimable, user?: User, count = 3,
): Promise<FactoryBotObject[]> {
  const attributes: Record<string, unknown> = { lecture_id: lectureId };
  if (user) {
    attributes[type === "tutorial" ? "tutor_ids" : "speaker_ids"] = [user.id];
  }
  const created = [];
  for (let i = 0; i < count; i++) {
    created.push(await factory.create(type, [], attributes));
  }
  return created;
}

async function openProfile(page: Page) {
  await page.goto("/profile/edit");
  await expect(page.getByRole("heading", { name: "Redeem Voucher" })).toBeVisible();
}

async function submitVoucher(page: Page, code: string) {
  await page.getByRole("textbox", { name: "Voucher code" }).fill(code);
  await page.getByRole("button", { name: "Verify Voucher" }).click();
}

async function expectInvalidVoucherAlert(page: Page, code: string) {
  expect(code).not.toBe("");
  await page.getByRole("textbox", { name: "Voucher code" }).fill(code);
  const alert = page.waitForEvent("dialog");
  await page.getByRole("button", { name: "Verify Voucher" }).click();
  const dialog = await alert;
  expect(dialog.message()).toBe("This voucher is invalid.");
  await dialog.accept();
}

async function redeemVoucher(page: Page, role: Role) {
  await page.getByRole("link", { name: "Redeem Voucher" }).click();
  await expect(page.getByText(SUCCESS_MESSAGES[role])).toBeVisible();
}

// TomSelect keeps the native options next to its own, so the click goes to
// its list, the one on screen.
async function claimAndRedeem(page: Page, role: Role, type: Claimable, titles: string[]) {
  const picker = page.getByRole("combobox", { name: CLAIM_PROMPTS[type] });
  const choices = page.locator(".ts-dropdown");
  for (const title of titles) {
    await picker.fill(title);
    await choices.getByRole("option", { name: title }).click();
  }
  await page.getByRole("button", { name: "Redeem Voucher" }).click();
  await expect(page.getByText(SUCCESS_MESSAGES[role])).toBeVisible();
}

async function expectCancelBringsFormBack(page: Page) {
  await page.getByRole("link", { name: "Cancel" }).click();
  await expect(page.getByRole("textbox", { name: "Voucher code" })).toBeVisible();
}

async function expectLectureSubscribed(page: Page) {
  await page.goto("/main/start");
  const subscribed = page.getByRole("region", { name: "Further subscribed event series" });
  await expect(subscribed.getByRole("link", { name: COURSE_TITLE })).toBeVisible();
}

function notificationList(page: Page): Locator {
  return page.getByRole("list", { name: "New notifications" });
}

// The bell's name carries the icon glyph in front of the count, so the count
// is read off the text.
async function expectOneNotification(page: Page) {
  await page.goto("/main/start");
  await expect(notificationList(page).getByRole("link", { name: "1" })).toHaveText("1");
}

async function expectRoleNotification(page: Page, role: Role, user: User) {
  await expectOneNotification(page);
  const notifications = notificationList(page);
  await notifications.getByRole("button", { name: "Toggle" }).click();
  await expect(notifications.getByRole("link", {
    name: `${ROLE_NAMES[role]} ${user.name_in_tutorials}`,
  })).toBeVisible();

  await page.goto("/notifications");
  await expect(page.getByText("Voucher redeemed:")).toHaveCount(1);
  await expect(page.getByRole("link", { name: COURSE_SHORT_TITLE })).toBeVisible();
  await expect(page.getByText(`${user.name_in_tutorials} (${user.email}) has redeemed`))
    .toBeVisible();
}

async function expectNoNotification(page: Page) {
  await page.goto("/main/start");
  await expect(notificationList(page)).toHaveCount(0);
}

function peopleTabLink(lectureId: number): string {
  return `/lectures/${lectureId}/edit?tab=people`;
}

// The native option behind TomSelect carries the selection; the chip it draws
// has no role.
function editorOption(page: Page, user: User): Locator {
  return page.getByRole("option", {
    name: `${user.name_in_tutorials} (${user.email})`, exact: true, selected: true,
  });
}

async function redeemWithNothingToClaim(
  factory: FactoryBot, teacher: { page: Page; user: User }, student: { page: Page; user: User },
  role: Role, type: Claimable,
) {
  const sort = type === "talk" ? "seminar" : "lecture";
  const { lecture, voucher } = await lectureWithVoucher(factory, teacher.user.id, role, sort);
  await openProfile(student.page);

  await submitVoucher(student.page, voucher.secure_hash as string);
  await expect(student.page.getByText(REDEMPTION_TEXTS[role])).toBeVisible();
  await expect(student.page.getByText(NOTHING_TO_CLAIM_MESSAGES[type])).toBeVisible();
  await expect(student.page.getByRole("link", { name: "Redeem Voucher" })).toBeVisible();
  await redeemVoucher(student.page, role);
  await expectLectureSubscribed(student.page);

  if (type === "talk") {
    await teacher.page.goto(`/lectures/${lecture.id}/edit`);
    await expect(teacher.page.getByText("There are no talks yet.")).toBeVisible();
  }
  else {
    await teacher.page.goto(peopleTabLink(lecture.id));
  }
  await expectRoleNotification(teacher.page, role, student.user);
  await expect(teacher.page.getByText(NOTHING_CLAIMED_MESSAGES[type])).toBeVisible();
}

async function redeemWithSomethingClaimed(
  factory: FactoryBot, teacher: { page: Page; user: User }, student: { page: Page; user: User },
  role: Role, type: Claimable,
) {
  const sort = type === "talk" ? "seminar" : "lecture";
  const { lecture, voucher } = await lectureWithVoucher(factory, teacher.user.id, role, sort);
  const [first, second, third] = await createClaimables(factory, lecture.id, type);
  await openProfile(student.page);

  await submitVoucher(student.page, voucher.secure_hash as string);
  await claimAndRedeem(student.page, role, type, [first.title, second.title]);
  await expectLectureSubscribed(student.page);

  if (type === "talk") {
    await teacher.page.goto(`/lectures/${lecture.id}/edit`);
    for (const talk of [first, second]) {
      await expect(teacher.page.getByRole("region", { name: talk.title }))
        .toContainText(student.user.name_in_tutorials);
    }
    await expect(teacher.page.getByRole("region", { name: third.title }))
      .not.toContainText(student.user.name_in_tutorials);
  }
  await expectRoleNotification(teacher.page, role, student.user);
  const takenOver = teacher.page.getByText(/(Tutorials|Talks) taken over:/);
  await expect(takenOver).toContainText(first.title);
  await expect(takenOver).toContainText(second.title);
  await expect(takenOver).not.toContainText(third.title);
}

async function redeemTwice(
  factory: FactoryBot, teacher: { page: Page; user: User }, student: { page: Page; user: User },
  role: Role, sort: "lecture" | "seminar" = "lecture",
) {
  const { voucher } = await lectureWithVoucher(factory, teacher.user.id, role, sort);
  await openProfile(student.page);

  await submitVoucher(student.page, voucher.secure_hash as string);
  await redeemVoucher(student.page, role);
  await submitVoucher(student.page, voucher.secure_hash as string);

  await expect(student.page.getByText(ALREADY_REDEEMED_MESSAGES[role])).toBeVisible();
  await expectCancelBringsFormBack(student.page);
  await expectOneNotification(teacher.page);
}

test.describe("the verify voucher form", () => {
  test("is shown on the profile page", async ({ student: { page } }) => {
    await openProfile(page);

    await expect(page.getByRole("textbox", { name: "Voucher code" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Verify Voucher" })).toBeVisible();
  });

  test("displays an alert if the voucher is invalid", async ({ student: { page } }) => {
    await openProfile(page);

    await expectInvalidVoucherAlert(page, "incorrect hash");
  });

  test("is valid even if the voucher code has whitespace at the beginning and end",
    async ({ factory, teacher, student: { page } }) => {
      const { voucher } = await lectureWithVoucher(factory, teacher.user.id, "tutor");
      await openProfile(page);

      await submitVoucher(page, `\t  ${voucher.secure_hash} `);

      await expect(page.getByText(REDEMPTION_TEXTS.tutor)).toBeVisible();
    });
});

test.describe("tutor voucher redemption", () => {
  test.describe("when the lecture has no tutorials yet", () => {
    test("allows redemption of the voucher to successfully become tutor",
      async ({ factory, teacher, student }) => {
        await redeemWithNothingToClaim(factory, teacher, student, "tutor", "tutorial");
      });

    test("displays a message that the user has already redeemed the voucher",
      async ({ factory, teacher, student }) => {
        await redeemTwice(factory, teacher, student, "tutor");
      });
  });

  test.describe("when the lecture has tutorials", () => {
    test("allows the user to successfully submit tutorials and become their tutor",
      async ({ factory, teacher, student }) => {
        await redeemWithSomethingClaimed(factory, teacher, student, "tutor", "tutorial");
      });

    // Tutoring every tutorial leaves none to claim, but the voucher itself is
    // still open: the teacher may add a tutorial and put the tutor on it later.
    test("offers to redeem the voucher without a tutorial when the user tutors all of them",
      async ({ factory, teacher, student }) => {
        const { lecture, voucher } = await lectureWithVoucher(factory, teacher.user.id, "tutor");
        await createClaimables(factory, lecture.id, "tutorial", student.user);
        await openProfile(student.page);

        await submitVoucher(student.page, voucher.secure_hash as string);

        await expect(student.page.getByText(NOTHING_TO_CLAIM_MESSAGES.tutorial)).toBeVisible();
        await expect(student.page.getByRole("link", { name: "Redeem Voucher" })).toBeVisible();
        await expectCancelBringsFormBack(student.page);
        await expectNoNotification(teacher.page);
      });
  });
});

test.describe("editor voucher redemption", () => {
  test("allows the user to successfully become an editor",
    async ({ factory, teacher, student }) => {
      const { lecture, voucher } = await lectureWithVoucher(factory, teacher.user.id, "editor");
      await openProfile(student.page);

      await submitVoucher(student.page, voucher.secure_hash as string);
      await expect(student.page.getByText(REDEMPTION_TEXTS.editor)).toBeVisible();
      await redeemVoucher(student.page, "editor");
      await expectLectureSubscribed(student.page);

      await student.page.goto(peopleTabLink(lecture.id));
      await expect(editorOption(student.page, student.user)).toHaveCount(1);
      // Editors are told about redemptions too, so the new editor sees their own.
      await expectRoleNotification(student.page, "editor", student.user);
    });

  test("displays a message that the user has already redeemed the voucher",
    async ({ factory, teacher, student }) => {
      await redeemTwice(factory, teacher, student, "editor");
    });

  test("displays the message that a teacher cannot become an editor",
    async ({ factory, teacher }) => {
      const { voucher } = await lectureWithVoucher(factory, teacher.user.id, "editor");
      await openProfile(teacher.page);

      await submitVoucher(teacher.page, voucher.secure_hash as string);

      await expect(teacher.page.getByText(
        "You are already a teacher and therefore cannot additionally become an editor.",
      )).toBeVisible();
      await expectCancelBringsFormBack(teacher.page);
    });
});

test.describe("teacher voucher redemption", () => {
  test("allows the user to successfully become a teacher",
    async ({ factory, teacher, student }) => {
      const { lecture, voucher } = await lectureWithVoucher(factory, teacher.user.id, "teacher");
      await openProfile(student.page);

      await submitVoucher(student.page, voucher.secure_hash as string);
      await expect(student.page.getByText(REDEMPTION_TEXTS.teacher)).toBeVisible();
      await redeemVoucher(student.page, "teacher");
      await expectLectureSubscribed(student.page);

      await student.page.goto(peopleTabLink(lecture.id));
      await expect(student.page.getByText(
        `${student.user.name_in_tutorials} (${student.user.email})`, { exact: true },
      )).toBeVisible();
      await expect(editorOption(student.page, teacher.user)).toHaveCount(1);
      await expectRoleNotification(student.page, "teacher", student.user);

      // A teacher voucher is spent on redemption.
      await openProfile(student.page);
      await expectInvalidVoucherAlert(student.page, voucher.secure_hash as string);
    });

  test("displays a message that the user is already the teacher",
    async ({ factory, teacher }) => {
      const { voucher } = await lectureWithVoucher(factory, teacher.user.id, "teacher");
      await openProfile(teacher.page);

      await submitVoucher(teacher.page, voucher.secure_hash as string);

      await expect(teacher.page.getByText(ALREADY_REDEEMED_MESSAGES.teacher))
        .toContainText(COURSE_TITLE);
      await expectCancelBringsFormBack(teacher.page);
    });
});

test.describe("speaker voucher redemption", () => {
  test.describe("when the seminar has no talks yet", () => {
    test("allows the user to successfully become a speaker",
      async ({ factory, teacher, student }) => {
        await redeemWithNothingToClaim(factory, teacher, student, "speaker", "talk");
      });

    test("displays a message that the user has already redeemed the voucher",
      async ({ factory, teacher, student }) => {
        await redeemTwice(factory, teacher, student, "speaker", "seminar");
      });
  });

  test.describe("when the seminar has talks", () => {
    test("allows the user to successfully submit talks and become their speaker",
      async ({ factory, teacher, student }) => {
        await redeemWithSomethingClaimed(factory, teacher, student, "speaker", "talk");
      });

    test("displays a message that the user is already a speaker for all talks",
      async ({ factory, teacher, student }) => {
        const { lecture, voucher } = await lectureWithVoucher(
          factory, teacher.user.id, "speaker", "seminar",
        );
        await createClaimables(factory, lecture.id, "talk", student.user);
        await openProfile(student.page);

        await submitVoucher(student.page, voucher.secure_hash as string);

        await expect(student.page.getByText(
          "There are no more talks available for this seminar that you can take over.",
        )).toBeVisible();
        await expectCancelBringsFormBack(student.page);
        await expectNoNotification(teacher.page);
      });
  });
});
