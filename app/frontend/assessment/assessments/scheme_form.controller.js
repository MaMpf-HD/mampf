import { Controller } from "@hotwired/stimulus";

const PASSING_GRADES = [4.0, 3.7, 3.3, 3.0, 2.7, 2.3, 2.0, 1.7, 1.3, 1.0];

const GRADE_BADGE_CLASS = {
  "1.0": "bg-success",
  "1.3": "bg-success",
  "1.7": "bg-success",
  "2.0": "bg-primary",
  "2.3": "bg-primary",
  "2.7": "bg-primary",
  "3.0": "bg-warning text-dark",
  "3.3": "bg-warning text-dark",
  "3.7": "bg-warning text-dark",
  "4.0": "bg-warning text-dark",
  "5.0": "bg-danger",
};

export default class extends Controller {
  static targets = [
    "excellenceInput",
    "passingInput",
    "bandsPreview",
    "bandsBody",
    "configField",
    "submitButton",
    "errorAlert",
  ];

  static values = { maxPoints: Number };

  generate() {
    this.hideError();

    const excellence = parseInt(this.excellenceInputTarget.value, 10);
    const passing = parseInt(this.passingInputTarget.value, 10);
    const maxPoints = this.maxPointsValue;

    if (isNaN(excellence) || isNaN(passing)) {
      this.showError("Please enter valid numbers for both thresholds.");
      return;
    }

    if (excellence <= passing) {
      this.showError(
        "Excellence threshold must be greater than passing threshold.",
      );
      return;
    }

    if (passing < 0) {
      this.showError("Passing threshold must be 0 or greater.");
      return;
    }

    if (excellence > maxPoints) {
      this.showError(
        `Excellence threshold cannot exceed ${maxPoints} points.`,
      );
      return;
    }

    const config = this.computeBands(excellence, passing, maxPoints);
    this.renderPreview(config.bands);
    this.configFieldTarget.value = JSON.stringify(config);
    this.submitButtonTarget.disabled = false;
    this.bandsPreviewTarget.classList.remove("d-none");
  }

  computeBands(excellence, passing, maxPoints) {
    const step = (excellence - passing) / (PASSING_GRADES.length - 1);

    const bands = PASSING_GRADES.map((grade, i) => {
      const minPts = Math.round(passing + i * step);
      const maxPts
        = i === PASSING_GRADES.length - 1
          ? maxPoints
          : Math.round(passing + (i + 1) * step) - 1;
      return {
        min_points: minPts,
        max_points: maxPts,
        grade: grade.toFixed(1),
      };
    });

    if (passing > 0) {
      bands.unshift({
        min_points: 0,
        max_points: passing - 1,
        grade: "5.0",
      });
    }

    return { bands };
  }

  renderPreview(bands) {
    const tbody = this.bandsBodyTarget;
    tbody.innerHTML = "";

    bands.forEach((band) => {
      const tr = document.createElement("tr");
      if (band.grade === "5.0") tr.classList.add("table-danger");

      const badgeClass = GRADE_BADGE_CLASS[band.grade] || "bg-secondary";

      tr.innerHTML = `
        <td><span class="badge ${badgeClass}">${band.grade}</span></td>
        <td>${band.min_points}–${band.max_points} pts</td>
      `;

      tbody.appendChild(tr);
    });
  }

  showError(message) {
    this.errorAlertTarget.textContent = message;
    this.errorAlertTarget.classList.remove("d-none");
    this.bandsPreviewTarget.classList.add("d-none");
    this.submitButtonTarget.disabled = true;
  }

  hideError() {
    this.errorAlertTarget.classList.add("d-none");
  }
}
