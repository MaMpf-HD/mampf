$(document).on("turbolinks:load", () => {
  if (!shouldRegisterVignette()) {
    return;
  }
  registerTextAnswerValidator();
});

var VIGNETTE_FORM_ID = "#vignettes-answer-form";

function shouldRegisterVignette() {
  return $(VIGNETTE_FORM_ID).length > 0;
}

////////////////////////////////////////////////////////////////////////////////
// Text Answer Fields
////////////////////////////////////////////////////////////////////////////////
var TEXT_ANSWER_ID = "vignettes_answer_text";

function registerTextAnswerValidator() {
  const textBody = document.getElementById(TEXT_ANSWER_ID);
  textBody.addEventListener("input", () => {
    validateTextAnswer();
  });
}

function validateTextAnswer() {
  const textBody = document.getElementById(TEXT_ANSWER_ID);

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
  }

  textBody.reportValidity();
}

////////////////////////////////////////////////////////////////////////////////
// TODO
////////////////////////////////////////////////////////////////////////////////

document.addEventListener("turbolinks:load", () => {
  const infoSlideButtons = document.querySelectorAll(".info-slide-button");
  const closeInfoSlideButtons = document.querySelectorAll(".close-info-slide-button");
  const infoSlideContainers = document.querySelectorAll(".info-slide-container");
  const slideContainer = document.getElementById("current-slide-container");

  const timeOnSlideField = document.getElementById("time-on-slide-field");
  const timeOnInfoSlidesField = document.getElementById("time-on-info-slides-field");
  const infoSlidesAccessCountField = document.getElementById("info-slides-access-count-field");

  const form = document.querySelector("form");

  let SlideStartTime = new Date();
  let InfoSlideStartTime = null;

  var activeInfoSlideIndex = null;

  // Time in seconds
  let totalSlideTime = 0;
  let infoSlideTimes = {};

  let infoSlidesAccessCount = {};

  infoSlideButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const index = button.getAttribute("data-index");
      activeInfoSlideIndex = index;

      // Hide all info slides and the slide
      infoSlideContainers.forEach(container => container.style.display = "none");
      slideContainer.style.display = "none";
      // Make selected info slide visible
      document.getElementById(`info-slide-container-${index}`).style.display = "block";

      // Increase access count on selected info slide
      infoSlidesAccessCount[index] = (infoSlidesAccessCount[index] || 0) + 1;

      totalSlideTime += (Date.now() - SlideStartTime);
      SlideStartTime = null;

      InfoSlideStartTime = Date.now();
    });
  });

  closeInfoSlideButtons.forEach((button) => {
    button.addEventListener("click", () => {
      activeInfoSlideIndex = null;
      const index = button.getAttribute("data-index");
      document.getElementById(`info-slide-container-${index}`).style.display = "none";
      slideContainer.style.display = "block";

      const timeSpentOnInfoSlide = (Date.now() - InfoSlideStartTime);
      infoSlideTimes[index] = (timeSpentOnInfoSlide[index] || 0) + timeSpentOnInfoSlide;
      InfoSlideStartTime = null;

      SlideStartTime = Date.now();
    });
  });

  form.addEventListener("submit", () => {
    event.preventDefault();
  });

  $(document).on("submit", VIGNETTE_FORM_ID, () => {
    if (SlideStartTime) {
      totalSlideTime += (Date.now() - SlideStartTime);
    }
    else if (activeInfoSlideIndex) {
      infoSlideTimes[activeInfoSlideIndex] += (Date.now() - InfoSlideStartTime);
    }
    for (let key in infoSlideTimes) {
      infoSlideTimes[key] = Math.floor(infoSlideTimes[key] / 1000);
    }
    timeOnSlideField.value = Math.floor(totalSlideTime / 1000);
    timeOnInfoSlidesField.value = JSON.stringify(infoSlideTimes);
    infoSlidesAccessCountField.value = JSON.stringify(infoSlidesAccessCount);
  });
});
