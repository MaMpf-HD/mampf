import { TempusDominus, Namespace } from "@eonasdan/tempus-dominus";
import "@eonasdan/tempus-dominus/dist/css/tempus-dominus.min.css";

export function initializeDatetimePickers(container = document) {
  const pickerElements = $(container).find(".td-picker");
  if (pickerElements.length == 0) {
    return;
  }

  pickerElements.each((i, element) => {
    element = $(element);
    const datetimePicker = initDatetimePicker(element);
    registerErrorHandlers(datetimePicker, element);
    registerFocusHandlers(datetimePicker, element);
  });
}

window.initializeDatetimePickers = initializeDatetimePickers;
$(document).ready(initializeDatetimePickers);

function getDateTimePickerIcons() {
  // At the moment: continue to use FontAwesome 5 icons
  // see https://getdatepicker.com/6/plugins/fa5.html
  return {
    type: "icons",
    time: "fas fa-clock",
    date: "fas fa-calendar",
    up: "fas fa-arrow-up",
    down: "fas fa-arrow-down",
    previous: "fas fa-chevron-left",
    next: "fas fa-chevron-right",
    today: "fas fa-calendar-check",
    clear: "fas fa-trash",
    close: "fas fa-times",
  };
}

function initDatetimePicker(element) {
  // see https://getdatepicker.com
  return new TempusDominus(
    element.get(0),
    {
      display: {
        sideBySide: true, // clock to the right of the calendar
        icons: getDateTimePickerIcons(),
      },
      localization: {
        startOfTheWeek: 1,
        // choose format to be compliant with backend time format
        format: "yyyy-MM-dd HH:mm",
        hourCycle: "h23",
      },
    },
  );
}

function registerErrorHandlers(datetimePicker, element) {
  datetimePicker.subscribe(Namespace.events.error, () => {
    const errorMsg = element.find(".td-error").data("td-invalid-date");
    element.find(".td-error").text(errorMsg).show();
  });

  datetimePicker.subscribe(Namespace.events.change, (e) => {
    // see https://getdatepicker.com/6/namespace/events.html#change

    // Clear error message
    if (e.isValid && !e.isClear) {
      element.find(".td-error").empty();
    }

    // If date was selected, close datetimepicker.
    // However: leave the datetimepicker open if user only changed time
    if (e.oldDate && e.date && !hasUserChangedDate(e.oldDate, e.date)) {
      datetimePicker.hide();
    }
  });
}

function hasUserChangedDate(oldDate, newDate) {
  return oldDate.getHours() != newDate.getHours()
    || oldDate.getMinutes() != newDate.getMinutes();
}

function registerFocusHandlers(datetimePicker, element) {
  element.find(".td-input").on("click focusin", (_e) => {
    datetimePicker.show();
  });
}
