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

  static values = { maxPoints: Number, studentPoints: Array };

  connect() {
    const raw = this.configFieldTarget.value;
    if (!raw) return;

    try {
      const config = JSON.parse(raw);
      if (config.bands && config.bands.length > 0) {
        this.renderPreview(config.bands);
        this.submitButtonTarget.disabled = false;
        this.bandsPreviewTarget.classList.remove("d-none");
      }
    }
    catch {
      // ignore invalid pre-populated JSON
    }
  }

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
    const table = tbody.closest("table");
    tbody.innerHTML = "";
    const existingTfoot = table.querySelector("tfoot");
    if (existingTfoot) existingTfoot.remove();

    const points = this.studentPointsValue.map(p => parseFloat(p));
    const total = points.length;

    const sorted = [...bands].sort(
      (a, b) => parseFloat(a.grade) - parseFloat(b.grade),
    );

    const counts = this.countPerBand(points, bands);
    const maxCount = total > 0
      ? Math.max(...sorted.map(b => counts[b.grade] || 0))
      : 0;

    sorted.forEach((band) => {
      const tr = document.createElement("tr");
      if (band.grade === "5.0") tr.classList.add("table-danger");

      const badgeClass = GRADE_BADGE_CLASS[band.grade] || "bg-secondary";
      const count = counts[band.grade] || 0;
      const pct = total > 0 ? ((count / total) * 100).toFixed(1) : "0.0";
      const barWidth = maxCount > 0
        ? Math.round((count / maxCount) * 100)
        : 0;
      const barColor = parseFloat(band.grade) <= 4.0
        ? "#198754"
        : "#dc3545";

      tr.innerHTML = `
        <td><span class="badge ${badgeClass}">${band.grade}</span></td>
        <td>${band.min_points}\u2013${band.max_points} pts</td>
        <td>
          <div class="d-flex align-items-center gap-2">
            <div style="flex: 1; height: 14px; background: #e9ecef;
                        border-radius: 3px; overflow: hidden;">
              <div style="width: ${barWidth}%; height: 100%;
                          background: ${barColor};"></div>
            </div>
            <span class="text-muted small" style="min-width: 20px;">
              ${count}
            </span>
          </div>
        </td>
        <td class="text-end">${pct}%</td>
      `;

      tbody.appendChild(tr);
    });

    if (total > 0) {
      const passCount = sorted
        .filter(b => parseFloat(b.grade) <= 4.0)
        .reduce((sum, b) => sum + (counts[b.grade] || 0), 0);
      const passRate = ((passCount / total) * 100).toFixed(1);
      const tfoot = document.createElement("tfoot");
      tfoot.classList.add("table-light");
      tfoot.innerHTML = `
        <tr>
          <th colspan="2">Pass rate:</th>
          <th colspan="2" class="text-end">
            ${passRate}% (${passCount}/${total})
          </th>
        </tr>
      `;
      table.appendChild(tfoot);
    }
  }

  countPerBand(points, allBands) {
    const descending = [...allBands].sort(
      (a, b) => b.min_points - a.min_points,
    );
    const result = {};
    allBands.forEach((b) => {
      result[b.grade] = 0;
    });

    points.forEach((p) => {
      const band = descending.find(b => p >= b.min_points);
      if (band) result[band.grade]++;
    });

    return result;
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
