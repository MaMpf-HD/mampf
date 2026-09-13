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

  saveRow() {
    const newValues = {};
    this.pointInputTargets.forEach((input) => {
      const taskId = input.dataset.taskId;
      newValues[taskId] = input.value;
    });
    this.taskPointsPayloadTarget.value = JSON.stringify(newValues);
    if (this.hasGradeInputTarget && this.hasGradePayloadTarget) {
      this.gradePayloadTarget.value = this.gradeInputTarget.value;
    }
    if (this.hasNoteInputTarget && this.hasNotePayloadTarget) {
      this.notePayloadTarget.value = this.noteInputTarget.value;
    }
    this.formTarget.requestSubmit();
  }

  refreshRow() {
    this.refreshFormTarget.requestSubmit();
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

  // Grade options come from a select; GradeEntryService validates them.
  // Only point inputs need the minimum-value check.
  onParticipationChanged(event) {
    if (this.validateNewPoint(event)) {
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
    let gradeDirty = false;
    let noteDirty = false;
    if (this.hasGradeInputTarget) {
      gradeDirty = this.gradeInputTarget.value !== this.originalGrade;
    }
    if (this.hasNoteInputTarget) {
      noteDirty = this.noteInputTarget.value !== this.originalNote;
    }

    if (pointDirty || gradeDirty || noteDirty) {
      this.handleDirty(targetType);
    }
    else {
      this.handleClean(targetType);
    }
  }

  handleDirty(targetType) {
    this.element.classList.add("row-dirty");

    // pointing-table uses these task_points for submitAll; changing the
    // row-dirty class alone does not update its bulk-save payload.
    this.dispatch("dirty", {
      prefix: false,
      bubbles: true,
      detail: {
        id: this.element.dataset.rowId,
        target: targetType,
        task_points: this.extractTasksPoints(this.pointInputTargets),
      },
    });

    if (this.hasSaveTarget) {
      this.saveTarget.disabled = false;
      this.saveTarget.classList.replace("text-body-tertiary", "text-success");
    }
  }

  handleClean(targetType) {
    this.element.classList.remove("row-dirty");

    this.dispatch("clean", {
      prefix: false,
      bubbles: true,
      detail: { id: this.element.dataset.rowId,
        target: targetType },
    });

    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true;
      this.saveTarget.classList.replace("text-success", "text-body-tertiary");
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
