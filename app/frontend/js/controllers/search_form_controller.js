import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "allToggle", "radioToggle"];

  connect() {
    console.log("Search form controller connected");
    this.initializeState();
  }

  initializeState() {
    // Set initial state for all toggles
    this.allToggleTargets.forEach((toggle) => {
      if (toggle.checked) {
        this.disableAssociatedSelect(toggle);
      }
    });

    // Handle radio buttons initial state
    const processedGroups = new Set();
    this.radioToggleTargets.forEach((radio) => {
      if (!processedGroups.has(radio.name) && radio.checked) {
        processedGroups.add(radio.name);
        if (radio.dataset.controlsSelect === "true") {
          this.enableAssociatedSelect(radio);
        }
      }
    });
  }

  toggleFromCheckbox(event) {
    const toggle = event.currentTarget;
    if (toggle.checked) {
      this.disableAssociatedSelect(toggle);
    }
    else {
      this.enableAssociatedSelect(toggle);
    }
  }

  toggleFromRadio(event) {
    const radio = event.currentTarget;
    const radioGroup = radio.name;

    // Handle current radio
    if (radio.dataset.controlsSelect === "true") {
      this.enableAssociatedSelect(radio);
    }

    // Disable selects for other radios in the same group
    this.radioToggleTargets
      .filter(otherRadio => otherRadio !== radio && otherRadio.name === radioGroup)
      .forEach((otherRadio) => {
        if (otherRadio.dataset.controlsSelect === "true") {
          this.disableAssociatedSelect(otherRadio);
        }
      });
  }

  enableAssociatedSelect(element) {
    const select = this.findAssociatedSelect(element);
    if (select?.tomselect) {
      select.tomselect.enable();
      select.setAttribute("aria-disabled", "false");
    }
  }

  disableAssociatedSelect(element) {
    const select = this.findAssociatedSelect(element);
    if (select?.tomselect) {
      select.tomselect.disable();
      select.setAttribute("aria-disabled", "true");
    }
  }

  findAssociatedSelect(element) {
    // First look for select in same form-field-group container
    const fieldGroup = element.closest(".form-field-group");
    if (fieldGroup) {
      const select = fieldGroup.querySelector("[data-search-form-target='select']");
      if (select) return select;
    }

    // Fallback to explicit ID if provided (for special cases)
    if (element.dataset.selectId) {
      return document.getElementById(element.dataset.selectId);
    }

    return null;
  }

  toggleRadioGroup(event) {
    const checkbox = event.currentTarget;
    const fieldGroup = checkbox.closest(".form-field-group");

    if (!fieldGroup) return;

    const radioGroupName = checkbox.dataset.toggleRadioGroup;
    if (!radioGroupName) return;

    const radioButtons = fieldGroup.querySelectorAll(`input[type="radio"][name$="[${radioGroupName}]"]`);

    if (!radioButtons.length) return;

    const defaultValue = checkbox.dataset.defaultRadioValue;
    if (checkbox.checked && defaultValue) {
      radioButtons.forEach((radio) => {
        if (radio.value === defaultValue) {
          radio.checked = true;
        }
      });
    }

    radioButtons.forEach((radio) => {
      radio.disabled = checkbox.checked;
    });
  }

  fillCourses(event) {
    const button = event.currentTarget;
    const courseIds = JSON.parse(button.dataset.courses || "[]");
    const fieldGroup = button.closest(".form-field-group");

    if (!fieldGroup) return;

    const select = fieldGroup.querySelector('[data-search-form-target="select"]');
    if (select?.tomselect) {
      select.tomselect.setValue(courseIds);
      select.tomselect.enable();

      const allToggle = fieldGroup.querySelector('[data-search-form-target="allToggle"]');
      if (allToggle) {
        allToggle.checked = false;
      }
    }
  }
}
