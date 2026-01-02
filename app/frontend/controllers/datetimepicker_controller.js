import { Controller } from "@hotwired/stimulus";
import { TempusDominus, Namespace } from "@eonasdan/tempus-dominus";
import "@eonasdan/tempus-dominus/dist/css/tempus-dominus.min.css";

export default class extends Controller {
  connect() {
    this.initDatetimePicker();
  }

  disconnect() {
    if (this.picker) {
      this.picker.dispose();
    }
  }

  initDatetimePicker() {
    this.picker = new TempusDominus(this.element, {
      display: {
        sideBySide: true,
        icons: this.getDateTimePickerIcons(),
      },
      localization: {
        startOfTheWeek: 1,
        format: "yyyy-MM-dd HH:mm",
        hourCycle: "h23",
      },
    });

    this.registerErrorHandlers();
    this.registerFocusHandlers();
  }

  getDateTimePickerIcons() {
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

  registerErrorHandlers() {
    const errorElement = this.element.querySelector(".td-error");

    this.picker.subscribe(Namespace.events.error, () => {
      if (errorElement) {
        const errorMsg = errorElement.dataset.tdInvalidDate;
        errorElement.textContent = errorMsg;
        errorElement.style.display = "block";
      }
    });

    this.picker.subscribe(Namespace.events.change, (e) => {
      if (e.isValid && !e.isClear && errorElement) {
        errorElement.textContent = "";
      }

      if (e.oldDate && e.date && !this.hasUserChangedDate(e.oldDate, e.date)) {
        this.picker.hide();
      }
    });
  }

  hasUserChangedDate(oldDate, newDate) {
    return (
      oldDate.getHours() != newDate.getHours()
      || oldDate.getMinutes() != newDate.getMinutes()
    );
  }

  registerFocusHandlers() {
    const input = this.element.querySelector(".td-input");
    if (input) {
      ["click", "focusin"].forEach((event) => {
        input.addEventListener(event, () => {
          this.picker.show();
        });
      });
    }
  }
}
