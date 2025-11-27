const VIGNETTE_FORM_ID = "#vignettes-answer-form";
const CHECK_BOXES_ID = "input[type='checkbox'][name='vignettes_answer[option_ids][]']";
const TEXT_ANSWER_ID = "vignettes_answer_text";

function shouldRegisterVignette() {
  return $(VIGNETTE_FORM_ID).length > 0;
}

$(document).ready(function () {
  if (!shouldRegisterVignette()) {
    return;
  }

  $(VIGNETTE_FORM_ID).submit((event) => {
    return validateForm(event);
  });

  registerTextAnswerValidator();
  registerMultipleChoiceAnswerValidator();
  testFormValidityOnPreview();

  const stats = new VignetteSlideStatistics();
  registerStatisticsHandler(stats);
});

////////////////////////////////////////////////////////////////////////////////
// Validators
////////////////////////////////////////////////////////////////////////////////

function validateForm(event) {
  const form = document.querySelector(VIGNETTE_FORM_ID);
  const isValidFirstCheck = validateTextAnswer();

  if (isValidFirstCheck) {
    const checkboxes = $(form).find(CHECK_BOXES_ID);
    validateMultipleChoiceAnswer(checkboxes);
  }

  if (!form.reportValidity()) {
    event.preventDefault();
    return false;
  }

  return true;
}

function testFormValidityOnPreview() {
  const previewNext = $("#vignettes-next-slide-preview");
  if (previewNext.length === 0) return;

  previewNext.click((event) => {
    return validateForm(event);
  });
}

function registerTextAnswerValidator() {
  const textBody = document.getElementById(TEXT_ANSWER_ID);
  if (!textBody) {
    return;
  }
  $(textBody).on("input", () => {
    validateTextAnswer();
  });
}

function validateTextAnswer() {
  const textBody = document.getElementById(TEXT_ANSWER_ID);
  if (!textBody) {
    return true;
  }

  let isValid = false;

  const validityState = textBody.validity;
  if (validityState.tooShort) {
    const tooShortMessage = textBody.dataset.tooShortMessage;
    textBody.setCustomValidity(tooShortMessage);
  }
  else if (validityState.valueMissing) {
    const valueMissingMessage = textBody.dataset.valueMissingMessage;
    textBody.setCustomValidity(valueMissingMessage);
  }
  else {
    // render input valid, so that form will submit
    textBody.setCustomValidity("");
    isValid = true;
  }

  textBody.reportValidity();
  return isValid;
}

function registerMultipleChoiceAnswerValidator() {
  const checkboxes = document.querySelectorAll(CHECK_BOXES_ID);
  checkboxes.forEach((checkbox) => {
    $(checkbox).on("change", () => {
      validateMultipleChoiceAnswer(checkboxes);
    });
  });
}

function validateMultipleChoiceAnswer(checkboxes) {
  if (checkboxes.length === 0) {
    return true;
  }

  const isValid = Array.from(checkboxes).some(checkbox => checkbox.checked);

  // Use the last checkbox to set custom validity for the group
  const lastCheckbox = checkboxes[checkboxes.length - 1];
  if (!isValid) {
    lastCheckbox.setCustomValidity(lastCheckbox.dataset.messageAtLeastOne);
  }
  else {
    lastCheckbox.setCustomValidity("");
  }

  lastCheckbox.reportValidity();
  return isValid;
}

////////////////////////////////////////////////////////////////////////////////
// Statistics
////////////////////////////////////////////////////////////////////////////////

class VignetteSlideStatistics {
  slideAccessDate = Date.now();
  slideStartTime = new Date();
  slideTime = 0;
  totalSlideTime = 0;

  infoSlideAccessCounts = {};
  infoSlideStartTime = null;
  infoSlideTimes = {};
  infoSlideFirstAccessTimes = {};

  increaseInfoSlideAccessCount(id) {
    this.infoSlideAccessCounts[id] ??= 0;
    this.infoSlideAccessCounts[id]++;
  }

  checkInfoSlideFirstAccess(id) {
    if (!this.infoSlideFirstAccessTimes[id]) {
      this.infoSlideFirstAccessTimes[id] = Date.now() - this.slideAccessDate;
    }
  }

  setTotalSlideTime() {
    this.totalSlideTime = Date.now() - this.slideAccessDate;
  }

  freezeSlideTime() {
    if (this.slideStartTime === null) {
      console.error("Attempted to freeze slide time when it was already frozen");
      return;
    }
    this.slideTime += (Date.now() - this.slideStartTime);
    this.slideStartTime = null;
  }

  unfreezeSlideTime() {
    this.slideStartTime = Date.now();
  }

  startInfoSlideTimer() {
    this.infoSlideStartTime = Date.now();
  }

  stopInfoSlideTimer(id) {
    if (this.infoSlideStartTime === null) {
      console.error("Attempted to stop info slide timer when it was already stopped");
      return;
    }
    const timeOnInfoSlide = (Date.now() - this.infoSlideStartTime);
    this.infoSlideTimes[id] = (this.infoSlideTimes[id] || 0.0) + timeOnInfoSlide;
    this.infoSlideStartTime = null;
  }

  postProcessTimes() {
    for (const key in this.infoSlideTimes) {
      this.infoSlideTimes[key] = Math.floor(this.infoSlideTimes[key] / 1000);
    }
    for (const key in this.infoSlideFirstAccessTimes) {
      this.infoSlideFirstAccessTimes[key] = Math.floor(this.infoSlideFirstAccessTimes[key] / 1000);
    }
    this.slideTime = Math.floor(this.slideTime / 1000);
    this.totalSlideTime = Math.floor(this.totalSlideTime / 1000);
  }
};

function registerStatisticsHandler(stats) {
  // Info Slide - Opening
  const openInfoSlideButtons = $(".open-info-slide-btn");
  if (!openInfoSlideButtons) {
    return;
  }
  openInfoSlideButtons.each(function () {
    const id = $(this).attr("data-info-slide-id");
    $(this).click(() => {
      stats.freezeSlideTime();
      stats.checkInfoSlideFirstAccess(id);
      stats.increaseInfoSlideAccessCount(id);
      stats.startInfoSlideTimer();
    });
  });

  // Info Slide - Closing
  const infoSlideModals = $(".vignette-info-slide-modal");
  if (!infoSlideModals) {
    console.error("No info slide modals found");
    return;
  }
  infoSlideModals.each(function () {
    $(this).on("hidden.bs.modal", function () {
      const id = $(this).attr("data-info-slide-id");
      stats.stopInfoSlideTimer(id);
      stats.unfreezeSlideTime();
    });
  });

  // Form Submission
  $(VIGNETTE_FORM_ID).submit((e) => {
    if ($(VIGNETTE_FORM_ID).data("preview")) {
      e.preventDefault();
      return;
    }
    // Take rest of time into account
    if (stats.slideStartTime) {
      stats.freezeSlideTime();
    }

    stats.setTotalSlideTime();
    stats.postProcessTimes();

    // Transfer results to hidden form-fields
    const timeOnSlideField = $("#time-on-slide-field");
    const totalTimeOnSlideField = $("#total-time-on-slide-field");
    const timeOnInfoSlidesField = $("#time-on-info-slides-field");
    const infoSlidesAccessCountField = $("#info-slides-access-count-field");
    const infoSlideFirstAccessTimes = $("#info-slides-first-access-times-field");
    timeOnSlideField.val(stats.slideTime);
    totalTimeOnSlideField.val(stats.totalSlideTime);
    timeOnInfoSlidesField.val(JSON.stringify(stats.infoSlideTimes));
    infoSlidesAccessCountField.val(JSON.stringify(stats.infoSlideAccessCounts));
    infoSlideFirstAccessTimes.val(JSON.stringify(stats.infoSlideFirstAccessTimes));
  });
}
