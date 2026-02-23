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

const GRADE_MARKER_COLOR = {
  "1.0": "#198754",
  "1.3": "#198754",
  "1.7": "#198754",
  "2.0": "#223e62",
  "2.3": "#223e62",
  "2.7": "#223e62",
  "3.0": "#ffc107",
  "3.3": "#ffc107",
  "3.7": "#ffc107",
  "4.0": "#dc3545",
};

export default class extends Controller {
  static targets = [
    "excellenceInput",
    "passingInput",
    "pointsStepInput",
    "bandsPreview",
    "bandsBody",
    "configField",
    "submitButton",
    "errorAlert",
    "dirtyHint",
    "manualHistogramContainer",
    "manualBars",
    "manualBandsBody",
    "manualPreview",
    "manualAxis",
  ];

  static values = {
    maxPoints: Number,
    studentPoints: Array,
    passLabel: { type: String, default: "Pass rate" },
    failLabel: { type: String, default: "Fail rate" },
    regenerateHint: {
      type: String,
      default: "Thresholds changed — regenerate bands before saving.",
    },
    errorInvalidNumbers: {
      type: String,
      default: "Please enter valid numbers for both thresholds.",
    },
    errorExcellenceGtPassing: {
      type: String,
      default: "Excellence threshold must be greater than passing threshold.",
    },
    errorPassingNegative: {
      type: String,
      default: "Passing threshold must be 0 or greater.",
    },
    errorExcellenceMax: {
      type: String,
      default: "Excellence threshold cannot exceed %{max} points.",
    },
    errorRangeTooNarrow: {
      type: String,
      default: "Range too narrow: need at least %{min_range} points (%{grades} \u00d7 step %{step}).",
    },
  };

  connect() {
    this._baselineConfig = this.configFieldTarget.value;
    this._baselineStep = this.pointsStepInputTarget.value;

    this._boundSubmit = this._onSubmit.bind(this);
    this.element
      .querySelector("form")
      ?.addEventListener("submit", this._boundSubmit);

    const raw = this._baselineConfig;
    if (!raw) return;

    try {
      const config = JSON.parse(raw);
      if (config.bands && config.bands.length > 0) {
        this.renderPreview(config.bands);
        this.bandsPreviewTarget.classList.remove("d-none");
      }
    }
    catch {
      // ignore invalid pre-populated JSON
    }
  }

  generate() {
    this.hideError();

    const excellence = parseFloat(this.excellenceInputTarget.value);
    const passing = parseFloat(this.passingInputTarget.value);
    const step = parseFloat(this.pointsStepInputTarget.value) || 1;
    const maxPoints = this.maxPointsValue;

    if (isNaN(excellence) || isNaN(passing)) {
      this.showError(this.errorInvalidNumbersValue);
      return;
    }

    if (excellence <= passing) {
      this.showError(this.errorExcellenceGtPassingValue);
      return;
    }

    if (passing < 0) {
      this.showError(this.errorPassingNegativeValue);
      return;
    }

    if (excellence > maxPoints) {
      this.showError(this.errorExcellenceMaxValue);
      return;
    }

    const minRange = (PASSING_GRADES.length - 1) * step;
    if (excellence - passing < minRange) {
      this.showError(
        this.errorRangeTooNarrowValue
          .replace("__min_range__", minRange)
          .replace("__grades__", PASSING_GRADES.length - 1)
          .replace("__step__", step),
      );
      return;
    }

    const config = this.computeBands(excellence, passing, maxPoints);
    this.renderPreview(config.bands);
    this.configFieldTarget.value = JSON.stringify(config);
    this.bandsPreviewTarget.classList.remove("d-none");
    this.clearDirty();
    this._refreshSubmit();
  }

  onStepChange() {
    if (this._isAutoTab()) {
      this.markDirty();
    }
    else {
      this._refreshSubmit();
    }
  }

  markDirty() {
    if (!this.configFieldTarget.value) return;

    this.submitButtonTarget.disabled = true;
    this.dirtyHintTarget.textContent = this.regenerateHintValue;
    this.dirtyHintTarget.classList.remove("d-none");
  }

  clearDirty() {
    this.dirtyHintTarget.classList.add("d-none");
  }

  _isAutoTab() {
    return document
      .querySelector("[data-bs-target='#two-point-tab']")
      ?.classList.contains("active") ?? true;
  }

  _refreshSubmit() {
    const configChanged
      = this.configFieldTarget.value !== (this._baselineConfig || "");
    const stepChanged
      = this.pointsStepInputTarget.value !== (this._baselineStep || "");
    this.submitButtonTarget.disabled = !(configChanged || stepChanged);
  }

  _onSubmit() {
    this._baselineConfig = this.configFieldTarget.value;
    this._baselineStep = this.pointsStepInputTarget.value;
    this.submitButtonTarget.disabled = true;
  }

  computeBands(excellence, passing, maxPoints) {
    const pointsStep = parseFloat(this.pointsStepInputTarget.value) || 1;
    const rawStep = (excellence - passing) / (PASSING_GRADES.length - 1);

    const bands = PASSING_GRADES.map((grade, i) => {
      const raw = passing + i * rawStep;
      const minPts
        = Math.round(raw / pointsStep) * pointsStep;
      return {
        min_points: minPts,
        grade: grade.toFixed(1),
      };
    });

    if (passing > 0) {
      bands.unshift({
        min_points: 0,
        grade: "5.0",
      });
    }

    return { bands };
  }

  renderPreview(bands, targetBody) {
    const tbody = targetBody || this.bandsBodyTarget;
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
        <td>\u2265\u00a0${band.min_points} pts</td>
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
      const failCount = total - passCount;
      const passRate = ((passCount / total) * 100).toFixed(1);
      const failRate = ((failCount / total) * 100).toFixed(1);
      const tfoot = document.createElement("tfoot");
      tfoot.classList.add("table-light");
      tfoot.innerHTML = `
        <tr>
          <th colspan="2">${this.passLabelValue}:</th>
          <th colspan="2" class="text-end">
            ${passRate}% (${passCount}/${total})
          </th>
        </tr>
        <tr>
          <th colspan="2">${this.failLabelValue}:</th>
          <th colspan="2" class="text-end">
            ${failRate}% (${failCount}/${total})
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

  disconnect() {
    if (this._boundMove) {
      document.removeEventListener("pointermove", this._boundMove);
      document.removeEventListener("pointerup", this._boundUp);
    }
    if (this._boundSubmit) {
      this.element
        .querySelector("form")
        ?.removeEventListener("submit", this._boundSubmit);
    }
  }

  initManualTab() {
    if (!this._manualInitialized) {
      this._manualInitialized = true;
      this._buildManualHistogram();
    }
    this._syncManualFromConfig();
  }

  syncAutoPreview() {
    const raw = this.configFieldTarget.value;
    if (!raw) return;

    try {
      const config = JSON.parse(raw);
      if (config.bands?.length > 0) {
        this.renderPreview(config.bands);
        this.bandsPreviewTarget.classList.remove("d-none");
        this.clearDirty();
        this._refreshSubmit();

        const band10 = config.bands.find(b => b.grade === "1.0");
        const band40 = config.bands.find(b => b.grade === "4.0");
        if (band10) this.excellenceInputTarget.value = band10.min_points;
        if (band40) this.passingInputTarget.value = band40.min_points;
      }
    }
    catch { /* no valid config */ }
  }

  _buildManualHistogram() {
    const container = this.manualBarsTarget;
    const maxPoints = this.maxPointsValue;
    if (maxPoints <= 0) return;

    const points = this.studentPointsValue
      .map(p => parseFloat(p));
    const binCount = Math.min(
      30, Math.max(10, Math.round(maxPoints / 4)),
    );
    const binWidth = Math.ceil(maxPoints / binCount);
    const bins = Array.from({ length: binCount }, (_, i) => ({
      low: i * binWidth,
      high: i === binCount - 1
        ? maxPoints
        : (i + 1) * binWidth - 1,
      count: 0,
    }));

    points.forEach((p) => {
      const idx = Math.min(
        Math.floor(p / binWidth), binCount - 1,
      );
      bins[idx].count++;
    });

    const maxCount = Math.max(...bins.map(b => b.count), 1);

    container.innerHTML = bins.map((bin) => {
      const pct = Math.round(
        (bin.count / maxCount) * 100,
      );
      const minH = bin.count > 0 ? 4 : 0;
      return `<div class="flex-fill rounded-top"
        style="height: ${pct}%; min-height: ${minH}px;
               background-color: #0d6efd;"
        title="${bin.low}\u2013${bin.high} pts: ${bin.count}"
        data-bs-toggle="tooltip"></div>`;
    }).join("");

    this._renderAxis(maxPoints);
  }

  _renderAxis(maxPoints) {
    const axis = this.manualAxisTarget;
    axis.innerHTML = "";

    const rawStep = maxPoints / 6;
    const magnitude = Math.pow(10, Math.floor(Math.log10(rawStep)));
    const step = Math.ceil(rawStep / magnitude) * magnitude;
    const ticks = [];
    for (let v = 0; v <= maxPoints; v += step) {
      ticks.push(v);
    }
    if (ticks[ticks.length - 1] < maxPoints) ticks.push(maxPoints);

    ticks.forEach((v) => {
      const pct = (v / maxPoints) * 100;
      const span = document.createElement("span");
      span.className = "text-muted";
      span.textContent = v;
      span.style.cssText = `
        position: absolute;
        font-size: 0.7rem;
        white-space: nowrap;
        ${
          pct === 0
            ? "left: 0;"
            : pct >= 100
              ? "right: 0;"
              : `left: ${pct}%; transform: translateX(-50%);`
        }
      `;
      axis.appendChild(span);
    });
  }

  _syncManualFromConfig() {
    let bands;
    const raw = this.configFieldTarget.value;
    if (raw) {
      try {
        const config = JSON.parse(raw);
        if (config.bands?.length > 0) bands = config.bands;
      }
      catch { /* use defaults */ }
    }

    if (!bands) {
      const max = this.maxPointsValue;
      const result = this.computeBands(
        Math.round(max * 0.9),
        Math.round(max * 0.5),
        max,
      );
      bands = result.bands;
    }

    this._placeMarkers(bands);
    this._updateManualConfig();
  }

  _placeMarkers(bands) {
    const container = this.manualHistogramContainerTarget;
    container
      .querySelectorAll(".manual-marker")
      .forEach(m => m.remove());

    const maxPoints = this.maxPointsValue;
    if (maxPoints <= 0) return;

    PASSING_GRADES.forEach((grade) => {
      const gs = grade.toFixed(1);
      const band = bands.find(b => b.grade === gs);
      if (!band) return;

      const pct = Math.min(
        Math.max(
          (band.min_points / maxPoints) * 100, 0,
        ),
        100,
      );
      const color = this._markerColor(gs);

      const el = document.createElement("div");
      el.className = "manual-marker";
      el.dataset.grade = gs;
      el.dataset.minPoints = band.min_points;
      Object.assign(el.style, {
        position: "absolute",
        left: `${pct}%`,
        top: "0",
        bottom: "0",
        width: "20px",
        transform: "translateX(-50%)",
        cursor: "ew-resize",
        zIndex: "10",
        touchAction: "none",
        userSelect: "none",
      });

      el.innerHTML = `
        <div style="position: absolute; left: 50%; top: 0;
                    height: 155px; width: 2px;
                    background: ${color}; opacity: 0.8;
                    transform: translateX(-50%);
                    box-shadow: 1px 0 0 rgba(255,255,255,0.85),
                                -1px 0 0 rgba(255,255,255,0.85);
                    pointer-events: none;"></div>
        <span data-pts-label style="
          position: absolute; top: 2px; left: 50%;
          transform: translateX(-50%);
          font-size: 0.6rem; color: ${color}; font-weight: bold;
          white-space: nowrap; background: rgba(255,255,255,0.85);
          border-radius: 2px; padding: 0 2px;
          pointer-events: none;">${band.min_points}</span>
        <span class="badge" style="
          position: absolute; bottom: 0; left: 50%;
          transform: translateX(-50%);
          font-size: 0.6rem; background: ${color};
          white-space: nowrap;
          pointer-events: none;">${gs}</span>
      `;

      el.addEventListener(
        "pointerdown", this._startDrag.bind(this),
      );
      container.appendChild(el);
    });
  }

  _markerColor(grade) {
    return GRADE_MARKER_COLOR[grade] || "#6c757d";
  }

  _startDrag(e) {
    e.preventDefault();
    this._dragMarker = e.currentTarget;
    this._dragRect
      = this.manualHistogramContainerTarget
        .getBoundingClientRect();

    this._boundMove = this._onPointerMove.bind(this);
    this._boundUp = this._endDrag.bind(this);
    document.addEventListener(
      "pointermove", this._boundMove,
    );
    document.addEventListener(
      "pointerup", this._boundUp,
    );
  }

  _onPointerMove(e) {
    this._moveMarkerTo(e.clientX);
  }

  _snapToStep(value) {
    const step = parseFloat(this.pointsStepInputTarget.value) || 1;
    return Math.round(value / step) * step;
  }

  _moveMarkerTo(clientX) {
    const rect = this._dragRect;
    const maxPoints = this.maxPointsValue;
    const step = parseFloat(this.pointsStepInputTarget.value) || 1;
    const rawPct
      = ((clientX - rect.left) / rect.width) * 100;
    let points = this._snapToStep(
      (Math.min(Math.max(rawPct, 0), 100) / 100) * maxPoints,
    );

    const grade = parseFloat(
      this._dragMarker.dataset.grade,
    );
    const idx = PASSING_GRADES.indexOf(grade);
    const markers
      = this.manualHistogramContainerTarget
        .querySelectorAll(".manual-marker");
    const byGrade = {};
    markers.forEach((m) => {
      byGrade[m.dataset.grade] = m;
    });

    if (idx > 0) {
      const prev
        = byGrade[PASSING_GRADES[idx - 1].toFixed(1)];
      if (prev) {
        points = Math.max(
          points,
          parseFloat(prev.dataset.minPoints) + step,
        );
      }
    }

    if (idx < PASSING_GRADES.length - 1) {
      const next
        = byGrade[PASSING_GRADES[idx + 1].toFixed(1)];
      if (next) {
        points = Math.min(
          points,
          parseFloat(next.dataset.minPoints) - step,
        );
      }
    }

    points = Math.max(points, 0);
    points = Math.min(points, maxPoints);
    points = this._snapToStep(points);

    const pct = (points / maxPoints) * 100;
    this._dragMarker.style.left = `${pct}%`;
    this._dragMarker.dataset.minPoints = points;
    const ptsLabel = this._dragMarker.querySelector("[data-pts-label]");
    if (ptsLabel) ptsLabel.textContent = points;
    this._updateManualConfig();
  }

  _endDrag() {
    document.removeEventListener(
      "pointermove", this._boundMove,
    );
    document.removeEventListener(
      "pointerup", this._boundUp,
    );
    this._dragMarker = null;
  }

  _updateManualConfig() {
    const markers
      = this.manualHistogramContainerTarget
        .querySelectorAll(".manual-marker");
    const bands = [];

    markers.forEach((m) => {
      bands.push({
        min_points: parseInt(m.dataset.minPoints, 10),
        grade: m.dataset.grade,
      });
    });

    const band40 = bands.find(b => b.grade === "4.0");
    if (band40 && band40.min_points > 0) {
      bands.push({ min_points: 0, grade: "5.0" });
    }

    this.configFieldTarget.value
      = JSON.stringify({ bands });
    this.renderPreview(
      bands, this.manualBandsBodyTarget,
    );
    this.manualPreviewTarget.classList.remove("d-none");
    this.clearDirty();
    this._refreshSubmit();
  }
}
