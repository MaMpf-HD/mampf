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
    }
  }

  disableAssociatedSelect(element) {
    const select = this.findAssociatedSelect(element);
    if (select?.tomselect) {
      select.tomselect.disable();
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

    // Get the radio group name from data attribute
    const radioGroupName = checkbox.dataset.toggleRadioGroup;
    if (!radioGroupName) return;

    // Find all radio buttons with this name in the same field group
    const radioButtons = fieldGroup.querySelectorAll(`input[type="radio"][name$="[${radioGroupName}]"]`);

    if (!radioButtons.length) return;

    // If checkbox is checked and there's a default value, select that radio
    const defaultValue = checkbox.dataset.defaultRadioValue;
    if (checkbox.checked && defaultValue) {
      radioButtons.forEach((radio) => {
        if (radio.value === defaultValue) {
          radio.checked = true;
        }
      });
    }

    // Disable/enable all radio buttons based on checkbox state
    radioButtons.forEach((radio) => {
      radio.disabled = checkbox.checked;
    });
  }
}
