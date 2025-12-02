import { Page } from "../_support/fixtures";

const DEFAULT_DATE_FUTURE = new Date();
DEFAULT_DATE_FUTURE.setDate(DEFAULT_DATE_FUTURE.getDate() + 2);

/**
 * Selects a date in the datepicker widget (only based on month and day, not year).
 *
 * @returns the name of the selected day (e.g. "March 15") for further use in assertions.
 */
export async function selectDate(page: Page, date = DEFAULT_DATE_FUTURE) {
  const monthName = date.toLocaleString("en-US", { month: "long" });
  const day = String(date.getDate()).padStart(2, "0");
  const dayName = `${monthName} ${day}`;
  await page.getByRole("gridcell", { name: dayName }).click();
  return dayName;
}
