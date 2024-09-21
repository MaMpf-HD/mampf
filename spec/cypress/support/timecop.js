import BackendCaller from "./backend_caller";

/**
 * Helper to call Timecop from Cypress tests, which is used to freeze or travel
 * time in the backend.
 *
 * This is different from cy.clock() which only affects the frontend.
 */
class Timecop {
  /**
   * Travels to the given date in the backend.
   *
   * By default, the date is assumed to be in the local timezone (assuming the
   * backend is configured to use local time).
   */
  #travelTo(year, month, day, hours = 0, minutes = 0, seconds = 0, useUTC = false) {
    return BackendCaller.callCypressRoute("timecop/travel", "Timecop.travel()",
      { year: year, month: month, day: day,
        hours: hours, minutes: minutes, seconds: seconds,
        use_utc: useUTC,
      });
  }

  /**
   * Travels to the given date in the backend.
   *
   * By default, the date is assumed to be in the local timezone (assuming the
   * backend is configured to use local time).
   */
  travelToDate(date, useUTC = false) {
    return this.#travelTo(
      date.getFullYear(), date.getMonth() + 1, date.getDate(),
      date.getHours(), date.getMinutes(), date.getSeconds(),
      useUTC,
    );
  }

  /**
   * Moves the time ahead by the given number of days.
   */
  moveAheadDays(days) {
    const now = new Date();
    now.setDate(now.getDate() + days);
    cy.log(`Moving ahead ${days} days to ${now.toISOString()}`);
    return this.#travelTo(
      now.getFullYear(), now.getMonth() + 1, now.getDate(),
      now.getHours(), now.getMinutes(), now.getSeconds(),
    );
  }

  /**
   * Resets the time in the backend to the current time.
   */
  reset() {
    return BackendCaller.callCypressRoute("timecop/reset", "Timecop.reset()");
  }
}

export default new Timecop();
