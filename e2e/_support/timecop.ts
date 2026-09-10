import { APIRequestContext } from "@playwright/test";
import { callBackend } from "./backend";

export class TimeCop {
    constructor(private context: APIRequestContext) {}
    
    /*private travelTo(year: number, month: nummber, day: number, hours: 0, minutes:0, seconds: 0, useUTC = false) {
        return callBackend(this.context, "timecop/travel", {
            year: year, month: month, day: day, hours: hours, minutes: minutes, seconds: seconds, use_utc: useUTC,
        });
    }*/

    travelToDate(date: Date, useUTC = false) {
        return callBackend(this.context, "timecop/travel", {
            year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate(),
            hours: date.getHours(), minutes: date.getMinutes(), seconds: date.getSeconds(),
            use_utc: useUTC,
    });
  }

    moveAheadDays(days: number) {
        const now = new Date();
        now.setDate(now.getDate() + days);
        return this.travelToDate(now);
    }

    reset() {
        return callBackend(this.context, "timecop/reset", {});
    }
}