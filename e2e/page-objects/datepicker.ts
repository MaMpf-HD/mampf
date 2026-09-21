import { Locator, Page } from "../_support/fixtures";

const DEFAULT_DATE_FUTURE = new Date();
DEFAULT_DATE_FUTURE.setDate(DEFAULT_DATE_FUTURE.getDate() + 2);

export function dateLabel(date = DEFAULT_DATE_FUTURE) {
  const monthName = date.toLocaleString("en-US", { month: "long" });
  const day = String(date.getDate()).padStart(2, "0");
  return `${monthName} ${day}`;
}

/**
 * Selects a date in the datepicker widget (only based on month and day, not year).
 *
 * @returns the name of the selected day (e.g. "March 15") for further use in assertions.
 */
export async function selectDate(page: Page, date = DEFAULT_DATE_FUTURE) {
  const dayString = dateLabel(date);
  await page.getByRole("gridcell", { name: dayString }).click();
  return dayString;
}

/**
 * Picks a date in the open widget, turning the pages of the calendar first
 * when the date's month is not the one on show: the trailing days of the next
 * month are on the page, but not all of them.
 */
export async function pickDate(page: Page, widget: Locator, date: Date) {
  const monthOnShow = date.toLocaleString("en-US", { month: "long", year: "2-digit" });
  const header = widget.locator(".picker-switch");
  for (let turns = 0; turns < 12 && (await header.innerText()) !== monthOnShow; turns++) {
    await widget.getByTitle("Next Month").click();
  }
  await widget.getByRole("gridcell", { name: dateLabel(date) }).click();
}
