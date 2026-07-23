import { Controller } from "@hotwired/stimulus";
import { PASSING_GRADES, computeBands } from "./grade_bands";
import { renderPreview } from "./preview_renderer";
import {
  buildHistogramBars, renderAxis, placeMarkers,
  moveMarkerTo, readMarkersAsBands,
} from "./manual_histogram";

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
    "anchorInput",
    "anchorTypeInput",
    "anchorHint",
    "deltaInput",
    "derivedInput",
    "derivedHint",
    "anchorDeltaBandsPreview",
    "anchorDeltaBandsBody",
    "anchorDeltaErrorAlert",
    "pointsStepRow",
    "derivedError",
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
        this._renderPreview(config.bands);
        this.bandsPreviewTarget.classList.remove("d-none");
      }
    }
    catch { /* ignore invalid pre-populated JSON */ }
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

    const config = computeBands(excellence, passing, step);
    this._renderPreview(config.bands);
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

  showError(message) {
    this.errorAlertTarget.textContent = message;
    this.errorAlertTarget.classList.remove("d-none");
    this.bandsPreviewTarget.classList.add("d-none");
    this.submitButtonTarget.disabled = true;
  }

  hideError() {
    this.errorAlertTarget.classList.add("d-none");
  }

  syncAutoPreview() {
    this.pointsStepRowTarget.classList.remove("d-none");
    const raw = this.configFieldTarget.value;
    if (!raw) return;

    try {
      const config = JSON.parse(raw);
      if (config.bands?.length > 0) {
        this._renderPreview(config.bands);
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

  onAnchorTypeChange() {
    const type = this._anchorType();
    const isPassingAnchor = type === "passing";
    this.anchorHintTarget.textContent = isPassingAnchor
      ? this.element.dataset.anchorHintPassing
      : this.element.dataset.anchorHintExcellence;
    this.derivedHintTarget.textContent = isPassingAnchor
      ? this.element.dataset.derivedHintExcellence
      : this.element.dataset.derivedHintPassing;
    this._updateDerivedField();
    this.markDirty();
  }

  onAnchorDeltaChange() {
    this._updateDerivedField();
    this.markDirty();
  }

  syncAnchorDeltaPreview() {
    this.pointsStepRowTarget.classList.add("d-none");
    this._updateDerivedField();
    const raw = this.configFieldTarget.value;
    if (!raw) return;
    try {
      const config = JSON.parse(raw);
      if (config.bands?.length > 0) {
        this._renderPreview(config.bands, this.anchorDeltaBandsBodyTarget);
        this.anchorDeltaBandsPreviewTarget.classList.remove("d-none");
        this.clearDirty();
        this._refreshSubmit();
      }
    }
    catch { /* no valid config */ }
  }

  generateFromDelta() {
    this._hideAnchorDeltaError();

    const anchor = parseFloat(this.anchorInputTarget.value);
    const delta = parseFloat(this.deltaInputTarget.value);
    const step = parseFloat(this.pointsStepInputTarget.value) || 1;
    const maxPoints = this.maxPointsValue;
    const type = this._anchorType();

    if (isNaN(anchor) || isNaN(delta)) {
      this._showAnchorDeltaError(this.errorInvalidNumbersValue);
      return;
    }

    if (delta <= 0) {
      this._showAnchorDeltaError(this.errorInvalidNumbersValue);
      return;
    }

    const minRange = (PASSING_GRADES.length - 1) * step;
    const derived = type === "passing"
      ? anchor + (PASSING_GRADES.length - 1) * delta
      : anchor - (PASSING_GRADES.length - 1) * delta;
    const excellence = type === "passing" ? derived : anchor;
    const passing = type === "passing" ? anchor : derived;

    if (passing < 0) {
      this._showAnchorDeltaError(this.errorPassingNegativeValue);
      return;
    }

    if (excellence > maxPoints) {
      this._showAnchorDeltaError(this.errorExcellenceMaxValue);
      return;
    }

    if (excellence - passing < minRange) {
      this._showAnchorDeltaError(
        this.errorRangeTooNarrowValue
          .replace("__min_range__", minRange)
          .replace("__grades__", PASSING_GRADES.length - 1)
          .replace("__step__", step),
      );
      return;
    }

    const config = computeBands(excellence, passing, step);
    this._renderPreview(config.bands, this.anchorDeltaBandsBodyTarget);
    this.configFieldTarget.value = JSON.stringify(config);
    this.anchorDeltaBandsPreviewTarget.classList.remove("d-none");
    this.clearDirty();
    this._refreshSubmit();
  }

  initManualTab() {
    this.pointsStepRowTarget.classList.remove("d-none");
    if (!this._manualInitialized) {
      this._manualInitialized = true;
      buildHistogramBars(
        this.manualBarsTarget,
        this.maxPointsValue,
        this.studentPointsValue,
      );
      renderAxis(this.manualAxisTarget, this.maxPointsValue);
    }
    this._syncManualFromConfig();
  }

  _renderPreview(bands, targetBody) {
    renderPreview(bands, targetBody || this.bandsBodyTarget, {
      studentPoints: this.studentPointsValue,
      passLabel: this.passLabelValue,
      failLabel: this.failLabelValue,
    });
  }

  _isAutoTab() {
    const target = this.element
      .querySelector(".nav-link.active")
      ?.getAttribute("data-bs-target");
    return target === "#two-point-tab" || target === "#anchor-delta-tab";
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

  _anchorType() {
    return this.anchorTypeInputTargets.find(r => r.checked)?.value || "passing";
  }

  _updateDerivedField() {
    const anchor = parseFloat(this.anchorInputTarget.value);
    const delta = parseFloat(this.deltaInputTarget.value);
    if (isNaN(anchor) || isNaN(delta) || delta <= 0) {
      this.derivedInputTarget.value = "";
      this.derivedInputTarget.classList.remove("is-invalid", "is-valid");
      return;
    }
    const derived = this._anchorType() === "passing"
      ? anchor + (PASSING_GRADES.length - 1) * delta
      : anchor - (PASSING_GRADES.length - 1) * delta;
    this.derivedInputTarget.value = parseFloat(derived.toFixed(4));

    const tooHigh = derived > this.maxPointsValue;
    const tooLow = derived < 0;
    const outOfBounds = tooHigh || tooLow;
    this.derivedInputTarget.classList.toggle("is-invalid", outOfBounds);
    this.derivedInputTarget.classList.toggle("is-valid", !outOfBounds);

    if (outOfBounds) {
      const msg = tooHigh
        ? this.errorExcellenceMaxValue
        : this.errorPassingNegativeValue;
      this.derivedErrorTarget.textContent = msg;
    }
  }

  _showAnchorDeltaError(message) {
    this.anchorDeltaErrorAlertTarget.textContent = message;
    this.anchorDeltaErrorAlertTarget.classList.remove("d-none");
    this.anchorDeltaBandsPreviewTarget.classList.add("d-none");
    this.submitButtonTarget.disabled = true;
  }

  _hideAnchorDeltaError() {
    this.anchorDeltaErrorAlertTarget.classList.add("d-none");
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
      const step = parseFloat(this.pointsStepInputTarget.value) || 1;
      const result = computeBands(
        Math.round(max * 0.9), Math.round(max * 0.5), step,
      );
      bands = result.bands;
    }

    placeMarkers(
      this.manualHistogramContainerTarget,
      bands,
      this.maxPointsValue,
      this._startDrag.bind(this),
    );
    this._updateManualConfig();
  }

  _startDrag(e) {
    e.preventDefault();
    this._dragMarker = e.currentTarget;
    this._dragRect
      = this.manualHistogramContainerTarget.getBoundingClientRect();

    this._boundMove = this._onPointerMove.bind(this);
    this._boundUp = this._endDrag.bind(this);
    document.addEventListener("pointermove", this._boundMove);
    document.addEventListener("pointerup", this._boundUp);
  }

  _onPointerMove(e) {
    const step = parseFloat(this.pointsStepInputTarget.value) || 1;
    moveMarkerTo(
      this._dragMarker, e.clientX, this._dragRect,
      this.maxPointsValue, step,
      this.manualHistogramContainerTarget,
    );
    this._updateManualConfig();
  }

  _endDrag() {
    document.removeEventListener("pointermove", this._boundMove);
    document.removeEventListener("pointerup", this._boundUp);
    this._dragMarker = null;
  }

  _updateManualConfig() {
    const bands = readMarkersAsBands(this.manualHistogramContainerTarget);
    this.configFieldTarget.value = JSON.stringify({ bands });
    this._renderPreview(bands, this.manualBandsBodyTarget);
    this.manualPreviewTarget.classList.remove("d-none");
    this.clearDirty();
    this._refreshSubmit();
  }
}
