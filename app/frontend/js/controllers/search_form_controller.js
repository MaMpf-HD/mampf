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

  toggleTagOperators(event) {
    const checkbox = event.currentTarget;
    const fieldGroup = checkbox.closest(".form-field-group");

    if (!fieldGroup) return;

    // Find radio buttons with data-tag-operator attribute in the same field group
    const orRadio = fieldGroup.querySelector('[data-tag-operator="or"]');
    const andRadio = fieldGroup.querySelector('[data-tag-operator="and"]');

    if (!orRadio || !andRadio) return;

    // If "all tags" is checked, select the OR operator
    if (checkbox.checked) {
      orRadio.checked = true;
    }

    // Disable both operators when "all tags" is checked
    orRadio.disabled = checkbox.checked;
    andRadio.disabled = checkbox.checked;
  }
}
