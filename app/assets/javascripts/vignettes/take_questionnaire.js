document.addEventListener("turbolinks:load", () => {
  const showInfoSlideBtn = document.getElementById("info-slide-button");
  const closeInfoSlideBtn = document.getElementById("close-info-slide-button");
  const infoSlideContainer = document.getElementById("info-slide-container");
  const slideContainer = document.getElementById("current-slide-container");

  const timeOnSlideField = document.getElementById("time-on-slide-field");
  const timeOnInfoSlideField = document.getElementById("time-on-info-slide-field");

  const form = document.querySelector("form");

  let SlideStartTime = new Date();
  let InfoSlideStartTime = null;

  // Time in seconds
  let totalSlideTime = 0;
  let totalInfoSlideTime = 0;

  showInfoSlideBtn?.addEventListener("click", (e) => {
    infoSlideContainer.style.display = "block";
    slideContainer.style.display = "none";

    totalSlideTime += (Date.now() - SlideStartTime);
    SlideStartTime = null;

    InfoSlideStartTime = Date.now();
  });

  closeInfoSlideBtn?.addEventListener("click", (e) => {
    infoSlideContainer.style.display = "none";
    slideContainer.style.display = "block";

    totalInfoSlideTime += (Date.now() - InfoSlideStartTime);
    InfoSlideStartTime = null;

    SlideStartTime = Date.now();
  });

  form.addEventListener("submit", (e) => {
    event.preventDefault();
  });

  $(document).on("submit", "#answer_form", (e) => {
    if (SlideStartTime) {
      totalSlideTime += (Date.now() - SlideStartTime);
    }
    else if (InfoSlideStartTime) {
      totalInfoSlideTime += (Date.now() - InfoSlideStartTime);
    }
    timeOnSlideField.value = Math.floor(totalSlideTime / 1000);
    timeOnInfoSlideField.value = Math.floor(totalInfoSlideTime / 1000);
  });
});
