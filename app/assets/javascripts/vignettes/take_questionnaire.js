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
    button.addEventListener("click", (e) => {
      const index = button.getAttribute("data-index");
      activeInfoSlideIndex = index;

      // Hide all info slides and the slide
      infoSlideContainers.forEach(container => container.style.display = "none");
      slideContainer.style.display = "none";
      // Make selected info slide visible
      document.getElementById(`info-slide-container-${index}`).style.display = "block";

      // Increase access count on selected info slide
      infoSlidesAccessCount[index] = (infoSlidesAccessCount[index] || 0) + 1;
      console.log("infoSlidesAccessCount", infoSlidesAccessCount);

      totalSlideTime += (Date.now() - SlideStartTime);
      SlideStartTime = null;

      InfoSlideStartTime = Date.now();
    });
  });

  closeInfoSlideButtons.forEach((button) => {
    button.addEventListener("click", (e) => {
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

  form.addEventListener("submit", (e) => {
    event.preventDefault();
  });

  $(document).on("submit", "#answer_form", (e) => {
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
