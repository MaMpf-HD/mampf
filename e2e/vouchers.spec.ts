import { expect, Locator, Page, test } from "./_support/fixtures";
import { User } from "./_support/auth";
import { FactoryBot } from "./_support/factorybot";

// Vouchers hand out staff roles; speakers come through registration.
// A seminar's groups are talks, so it offers no tutor role.
const LECTURE_ROLES = ["tutor", "editor", "teacher"] as const;
const SEMINAR_ROLES = LECTURE_ROLES.filter(role => role !== "tutor");

type Role = (typeof LECTURE_ROLES)[number];

const CARD_TITLES: Record<Role, string> = {
  tutor: "Voucher for Tutors",
  editor: "Voucher for Editors",
  teacher: "Voucher for Teachers",
};

async function openPeopleTab(
  factory: FactoryBot, teacher: { page: Page; user: User }, sort: "lecture" | "seminar",
) {
  const lecture = await factory.create(sort, [], { teacher_id: teacher.user.id });
  await teacher.page.goto(`/lectures/${lecture.id}/edit?tab=people`);
  await expect(teacher.page.getByRole("heading", { name: "Vouchers" })).toBeVisible();
  return lecture;
}

function voucherCard(page: Page, role: Role): Locator {
  return page.getByRole("region", { name: CARD_TITLES[role] });
}

async function expectVoucherShown(card: Locator) {
  await expect(card.getByRole("link", { name: "Create Voucher" })).toHaveCount(0);
  await expect(card.getByRole("link", { name: "Invalidate" })).toBeVisible();
  await expect(card.getByRole("textbox", { name: "Voucher code" }))
    .toHaveValue(/^[a-z0-9]{32}$/);
}

async function expectNoVoucher(card: Locator) {
  await expect(card.getByRole("link", { name: "Invalidate" })).toHaveCount(0);
  await expect(card.getByRole("link", { name: "Create Voucher" })).toBeVisible();
  await expect(card.getByRole("textbox", { name: "Voucher code" })).toHaveCount(0);
}

async function createVoucher(card: Locator) {
  await card.getByRole("link", { name: "Create Voucher" }).click();
  await expectVoucherShown(card);
}

async function invalidateVoucher(page: Page, card: Locator) {
  page.once("dialog", dialog => dialog.accept());
  await card.getByRole("link", { name: "Invalidate" }).click();
  await expectNoVoucher(card);
}

test.describe("the people tab of a lecture", () => {
  test("shows buttons for creating tutor, editor and teacher vouchers",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "lecture");

      for (const role of LECTURE_ROLES) {
        await expect(voucherCard(teacher.page, role).getByRole("link", { name: "Create Voucher" }))
          .toBeVisible();
      }
      await expect(teacher.page.getByRole("region", { name: "Voucher for Speakers" }))
        .toHaveCount(0);
    });

  test("displays the voucher and invalidate button after the create button is clicked",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "lecture");

      for (const role of LECTURE_ROLES) {
        await createVoucher(voucherCard(teacher.page, role));
      }
    });

  test("displays that there is no active voucher after the invalidate button is clicked",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "lecture");

      for (const role of LECTURE_ROLES) {
        const card = voucherCard(teacher.page, role);
        await createVoucher(card);
        await invalidateVoucher(teacher.page, card);
      }
    });

  test("copies the voucher code to the clipboard", async ({ factory, teacher }) => {
    await teacher.page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
    await openPeopleTab(factory, teacher, "lecture");

    for (const role of LECTURE_ROLES) {
      const card = voucherCard(teacher.page, role);
      await createVoucher(card);
      const code = await card.getByRole("textbox", { name: "Voucher code" }).inputValue();

      await card.getByRole("button", { name: "Copy to Clipboard" }).click();

      expect(await teacher.page.evaluate(() => navigator.clipboard.readText())).toBe(code);
    }
  });
});

test.describe("the people tab of a seminar", () => {
  test("shows buttons for creating editor and teacher vouchers",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "seminar");

      for (const role of SEMINAR_ROLES) {
        await expect(voucherCard(teacher.page, role).getByRole("link", { name: "Create Voucher" }))
          .toBeVisible();
      }
      await expect(voucherCard(teacher.page, "tutor")).toHaveCount(0);
      await expect(teacher.page.getByRole("region", { name: "Voucher for Speakers" }))
        .toHaveCount(0);
    });

  test("displays the voucher and invalidate button after the create button is clicked",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "seminar");

      for (const role of SEMINAR_ROLES) {
        await createVoucher(voucherCard(teacher.page, role));
      }
    });

  test("displays that there is no active voucher after the invalidate button is clicked",
    async ({ factory, teacher }) => {
      await openPeopleTab(factory, teacher, "seminar");

      for (const role of SEMINAR_ROLES) {
        const card = voucherCard(teacher.page, role);
        await createVoucher(card);
        await invalidateVoucher(teacher.page, card);
      }
    });
});

test.describe("when the server's clock moves ahead", () => {
  test("does not show expired vouchers (far in the future)",
    async ({ factory, teacher, timeCop }) => {
      await openPeopleTab(factory, teacher, "seminar");
      for (const role of SEMINAR_ROLES) {
        await createVoucher(voucherCard(teacher.page, role));
      }

      // The model specs cover expiry; this checks that the people tab stops
      // offering a voucher long past it.
      await timeCop.moveAheadDays(1000);
      await teacher.page.reload();

      for (const role of SEMINAR_ROLES) {
        await expectNoVoucher(voucherCard(teacher.page, role));
      }
    });

  test("does not show expired vouchers (near future)",
    async ({ factory, teacher, timeCop }) => {
      const seminar = await openPeopleTab(factory, teacher, "seminar");

      for (const role of SEMINAR_ROLES) {
        const voucher = await factory.create("voucher", [role], { lecture_id: seminar.id });
        await teacher.page.reload();
        await expectVoucherShown(voucherCard(teacher.page, role));

        const justExpired = new Date(voucher.expires_at as string);
        justExpired.setMinutes(justExpired.getMinutes() + 1);
        await timeCop.travelToDate(justExpired);
        await teacher.page.reload();

        await expectNoVoucher(voucherCard(teacher.page, role));
        await timeCop.reset();
      }
    });
});
