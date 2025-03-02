var VIGNETTE_FORM_ID = "#vignettes-answer-form";
function shouldRegisterVignette() {
  return $(VIGNETTE_FORM_ID).length > 0;
}

$(document).on("turbolinks:load", () => {
  if (!shouldRegisterVignette()) {
    return;
  }

  registerSubmitHandler();
  registerTextAnswerValidator();

  const stats = new VignetteSlideStatistics();
  registerStatisticsHandler(stats);
});

function registerSubmitHandler() {
  $(VIGNETTE_FORM_ID).submit((event) => {
    let isValid = false;
    isValid = validateTextAnswer();

    if (!isValid) {
      event.preventDefault();
      return false;
    }
  });
}

////////////////////////////////////////////////////////////////////////////////
// Text Answer Fields
////////////////////////////////////////////////////////////////////////////////
var TEXT_ANSWER_ID = "vignettes_answer_text";

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

////////////////////////////////////////////////////////////////////////////////
// Statistics
////////////////////////////////////////////////////////////////////////////////

class VignetteSlideStatistics {
  slideStartTime = new Date();
  totalSlideTime = 0;

  infoSlideAccessCounts = {};
  infoSlideStartTime = null;
  infoSlideTimes = {};

  increaseInfoSlideAccessCount(index) {
    this.infoSlideAccessCounts[index] ??= 0;
    this.infoSlideAccessCounts[index]++;
  }

  freezeSlideTime() {
    if (this.slideStartTime === null) {
      console.error("Attempted to freeze slide time when it was already frozen");
      return;
    }
    this.totalSlideTime += (Date.now() - this.slideStartTime);
    this.slideStartTime = null;
  }

  unfreezeSlideTime() {
    this.slideStartTime = Date.now();
  }

  startInfoSlideTimer() {
    this.infoSlideStartTime = Date.now();
  }

  stopInfoSlideTimer(index) {
    if (this.infoSlideStartTime === null) {
      console.error("Attempted to stop info slide timer when it was already stopped");
      return;
    }
    const timeOnInfoSlide = (Date.now() - this.infoSlideStartTime);
    this.infoSlideTimes[index] = (this.infoSlideTimes[index] || 0.0) + timeOnInfoSlide;
    this.infoSlideStartTime = null;
  }

  postProcessTimes() {
    for (let key in this.infoSlideTimes) {
      this.infoSlideTimes[key] = Math.floor(this.infoSlideTimes[key] / 1000);
    }
    this.totalSlideTime = Math.floor(this.totalSlideTime / 1000);
  }
}

function registerStatisticsHandler(stats) {
  // Info Slide - Opening
  const openInfoSlideButtons = $(".open-info-slide-btn");
  if (!openInfoSlideButtons) {
    return;
  }
  openInfoSlideButtons.each(function () {
    const index = $(this).attr("data-info-slide-index");
    $(this).click(() => {
      stats.freezeSlideTime();
      stats.increaseInfoSlideAccessCount(index);
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
      const index = $(this).attr("data-info-slide-index");
      stats.stopInfoSlideTimer(index);
      stats.unfreezeSlideTime();
    });
  });

  // Form Submission
  $(VIGNETTE_FORM_ID).submit(() => {
    // Take rest of time into account
    if (stats.slideStartTime) {
      stats.freezeSlideTime();
    }

    stats.postProcessTimes();

    // Transfer results to hidden form-fields
    const timeOnSlideField = $("#time-on-slide-field");
    const timeOnInfoSlidesField = $("#time-on-info-slides-field");
    const infoSlidesAccessCountField = $("#info-slides-access-count-field");
    timeOnSlideField.val(stats.totalSlideTime);
    timeOnInfoSlidesField.val(JSON.stringify(stats.infoSlideTimes));
    infoSlidesAccessCountField.val(JSON.stringify(stats.infoSlideAccessCounts));
  });
}
