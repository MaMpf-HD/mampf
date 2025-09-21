const POSITION_ID = "loginViewTransitionClick";

/**
 * Stores the click position in sessionStorage.
 */
document.addEventListener("click", function (event) {
  sessionStorage.setItem(POSITION_ID, JSON.stringify({
    x: event.clientX,
    y: event.clientY,
  }));
});
