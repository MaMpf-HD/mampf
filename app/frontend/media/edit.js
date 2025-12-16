import { initializeDatetimePickers } from "../js/datetimepicker";

$(document).on("turbo:load", () => {
  initializeDatetimePickers();
});
