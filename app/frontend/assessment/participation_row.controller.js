import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "pointInput", "gradeInput", "noteInput",
    "form", "refreshForm",
    "taskPointsPayload", "gradePayload", "notePayload",
    "save",
    "totalPoints",
  ];

  connect() {
    this.originalPoints = this.hasPointInputTarget ? this.pointInputTargets.map(i => i.value) : null;
    this.originalGrade = this.hasGradeInputTarget ? this.gradeInputTarget.value : null;
    this.originalNote = this.hasNoteInputTarget ? this.noteInputTarget.value : null;
    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true;
    }
    this.calculateTotalPoints();
  }

  // -- Actions ---
  saveRow() {
    // Collect all input values for this row
    const newValues = {};
    this.pointInputTargets.forEach((input) => {
      const taskId = input.dataset.taskId;
      newValues[taskId] = input.value;
    });

    // Set hidden input value as JSON
    this.taskPointsPayloadTarget.value = JSON.stringify(newValues);
    if (this.hasGradeInputTarget && this.hasGradePayloadTarget) {
      this.gradePayloadTarget.value = this.gradeInputTarget.value;
    }
    if (this.hasNoteInputTarget && this.hasNotePayloadTarget) {
      this.notePayloadTarget.value = this.noteInputTarget.value;
    }

    // Submit the hidden form
    this.formTarget.requestSubmit();
  }

  refreshRow() {
    this.refreshFormTarget.requestSubmit();
  }

  // --- Change Handlers ---
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

  onParticipationChanged(event) {
    console.log("onParticipationChanged called");
    const validPoints = this.validateNewPoint(event);
    const validGrade = this.validateNewGrade(event);
    const validNote = this.validateNewNote(event);

    if (validPoints && validGrade && validNote) {
      this.markDirty("participation");
      this.calculateTotalPoints();
    }
    else {
      this.alertTotalPointsInvalid();
      this.handleClean("participation");
    }
  }

  markDirty(targetType) {
    const pointDirty = this.pointInputTargets.some((input, idx) => input.value != this.originalPoints[idx]);
    const gradeDirty = this.gradeInputTarget.value !== this.originalGrade;
    const noteDirty = this.noteInputTarget.value !== this.originalNote;

    if (pointDirty || gradeDirty || noteDirty) {
      this.handleDirty(targetType);
    }
    else {
      this.handleClean(targetType);
    }
  }

  handleDirty(targetType) {
    // Add the "row-dirty" style to the row
    this.element.classList.add("row-dirty");

    // Force table controller to add the row to the dirty rows list
    // (so that it would be saved)
    this.dispatch("dirty", {
      prefix: false,
      bubbles: true,
      detail: {
        id: this.element.dataset.rowId,
        target: targetType,
        task_points: this.extractTasksPoints(this.pointInputTargets),
        // extend this if want to save bulk also with grade and note
      },
    });

    // Enable the save button
    if (this.hasSaveTarget) this.saveTarget.disabled = false;
  }

  handleClean(targetType) {
    // Remove the "row-dirty" style
    this.element.classList.remove("row-dirty");

    // Force table controller to remove the row from the dirty rows list
    // (so that it would not be saved)
    this.dispatch("clean", {
      prefix: false,
      bubbles: true,
      detail: { id: this.element.dataset.rowId,
        target: targetType },
    });

    // Disable the save button
    if (this.hasSaveTarget) this.saveTarget.disabled = true;
  }

  // --- Validation Methods ---

  validateNewGrade(event) {
    return true;
  }

  validateNewNote(event) {
    return true;
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

  // --- Data extraction Methods ---

  extractTasksPoints(pointInputTargets) {
    const participationNewTasksPoints = {};
    for (const input of pointInputTargets) {
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

  calculateTotalPoints() {
    let totalPoints = 0;
    this.pointInputTargets.forEach((input) => {
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
}
