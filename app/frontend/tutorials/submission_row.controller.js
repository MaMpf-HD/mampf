import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "form", "refreshForm", "payload", "save", "totalPoints"];

  connect() {
    this.originalValues = this.inputTargets.map(i => i.value);
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

  markDirty() {
    const dirty = this.inputTargets.some((input, idx) => input.value != this.originalValues[idx]);

    if (dirty) {
      this.element.classList.add("row-dirty");
      this.dispatch("dirty", {
        prefix: false,
        bubbles: true,
        detail: {
          id: this.element.dataset.submissionRowId,
          target: "submission",
          task_points: this.extractTasksPoints(this.inputTargets),
        },
      });
      if (this.hasSaveTarget) this.saveTarget.disabled = false;
      this.calculateTotalPoints();
    }
    else {
      this.element.classList.remove("row-dirty");
      this.dispatch("clean", {
        prefix: false,
        bubbles: true,
        detail: { id: this.element.dataset.submissionRowId,
          target: "submission" },
      });

      if (this.hasSaveTarget) this.saveTarget.disabled = true;
      this.calculateTotalPoints();
    }
  }

  markDirtyParticipation() {
    const dirty = this.inputTargets.some((input, idx) => input.value != this.originalValues[idx]);

    if (dirty) {
      this.element.classList.add("row-dirty");
      this.dispatch("dirty", {
        prefix: false,
        bubbles: true,
        detail: {
          id: this.element.dataset.participationRowId,
          target: "participation",
          task_points: this.extractTasksPoints(this.inputTargets),
        },
      });
      if (this.hasSaveTarget) this.saveTarget.disabled = false;
      this.calculateTotalPoints();
    }
    else {
      this.element.classList.remove("row-dirty");
      this.dispatch("clean", {
        prefix: false,
        bubbles: true,
        detail: { id: this.element.dataset.participationRowId,
          target: "participation" },
      });

      if (this.hasSaveTarget) this.saveTarget.disabled = true;
      this.calculateTotalPoints();
    }
  }

  extractTasksPoints(inputTargets) {
    const submissionNewTasksPoints = {};
    for (const input of inputTargets) {
      const id = this.extractId(input.name);
      const points = input.value;
      submissionNewTasksPoints[id] = points;
    }
    return submissionNewTasksPoints;
  }

  extractId(name) {
    const startIndex = name.indexOf("[") + 1;
    const length = name.indexOf("]", startIndex) - startIndex;
    return name.substring(startIndex, startIndex + length);
  }
}
