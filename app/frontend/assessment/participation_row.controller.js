import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "form", "refreshForm", "payload", "save", "totalPoints"];

  connect() {
    this.originalValues = this.inputTargets.map(i => i.value);
    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true;
    }
    this.calculateTotalPoints();
  }

  saveRow() {
    // Collect all input values for this row
    const newValues = {};
    this.inputTargets.forEach((input) => {
      const taskId = input.dataset.taskId;
      newValues[taskId] = input.value;
    });

    // Set hidden input value as JSON
    this.payloadTarget.value = JSON.stringify(newValues);

    // Submit the hidden form
    this.formTarget.requestSubmit();
  }

  refreshRow() {
    this.refreshFormTarget.requestSubmit();
  }

  calculateTotalPoints() {
    let totalPoints = 0;
    this.inputTargets.forEach((input) => {
      const points = parseFloat(input.value);
      if (!isNaN(points)) {
        totalPoints += points;
      }
    });
    if (this.hasTotalPointsTarget) {
      this.totalPointsTarget.textContent = totalPoints.toFixed(2);
    }
  }

  alertTotalPointsInvalid() {
    if (this.hasTotalPointsTarget) {
      this.totalPointsTarget.textContent = "N/A";
    }
  }

  onPointSubmissionChanged(event) {
    const valid = this.validateNewPoint(event);
    if (valid) {
      this.markDirty("submission");
      this.calculateTotalPoints();
    }
    else {
      this.alertTotalPointsInvalid();
      this.handleClean("submission");
    }
  }

  onPointParticipationChanged(event) {
    const valid = this.validateNewPoint(event);
    if (valid) {
      this.markDirty("participation");
      this.calculateTotalPoints();
    }
    else {
      this.alertTotalPointsInvalid();
      this.handleClean("participation");
    }
  }

  validateNewPoint(event) {
    const input = event.currentTarget;
    const min = parseFloat(input.min);
    const value = parseFloat(input.value);

    if (Number.isNaN(value)) {
      input.setCustomValidity("");
      return true;
    }

    if (value < min) {
      const message = input.dataset.belowMinMessage.replace("%{min}", min);
      input.setCustomValidity(message);
      input.reportValidity();
      return false;
    }
    else {
      input.setCustomValidity("");
      return true;
    }
  }

  markDirty(targetType) {
    const dirty = this.inputTargets.some((input, idx) => input.value != this.originalValues[idx]);
    if (dirty) {
      this.handleDirty(targetType);
    }
    else {
      this.handleClean(targetType);
    }
  }

  handleDirty(targetType) {
    this.element.classList.add("row-dirty");
    this.dispatch("dirty", {
      prefix: false,
      bubbles: true,
      detail: {
        id: this.element.dataset.rowId,
        target: targetType,
        task_points: this.extractTasksPoints(this.inputTargets),
      },
    });
    if (this.hasSaveTarget) this.saveTarget.disabled = false;
  }

  handleClean(targetType) {
    this.element.classList.remove("row-dirty");
    this.dispatch("clean", {
      prefix: false,
      bubbles: true,
      detail: { id: this.element.dataset.rowId,
        target: targetType },
    });

    if (this.hasSaveTarget) this.saveTarget.disabled = true;
  }

  extractTasksPoints(inputTargets) {
    const participationNewTasksPoints = {};
    for (const input of inputTargets) {
      const id = this.extractId(input.name);
      const points = input.value;
      participationNewTasksPoints[id] = points;
    }
    return participationNewTasksPoints;
  }

  extractId(name) {
    const startIndex = name.indexOf("[") + 1;
    const length = name.indexOf("]", startIndex) - startIndex;
    return name.substring(startIndex, startIndex + length);
  }
}
