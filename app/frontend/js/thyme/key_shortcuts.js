/**
 * Adds general shortcuts for the thyme player.
 */
export function addGeneralShortcuts() {
  const video = document.getElementById("video");

  window.addEventListener("keydown", function (evt) {
    if (thymeAttributes.lockKeyListeners) {
      return;
    }
    const key = evt.key;
    if (key === " ") {
      if (video.paused) {
        video.play();
      }
      else {
        video.pause();
      }
    }
    else if (key === "ArrowRight") {
      $("#plus-ten").trigger("click");
    }
    else if (key === "ArrowLeft") {
      $("#minus-ten").trigger("click");
    }
    else if (key === "f") {
      $("#full-screen").trigger("click");
    }
    else if (key === "m") {
      $("#mute").trigger("click");
    }
    else if (key === "PageUp") {
      video.volume = Math.min(video.volume + 0.1, 1);
    }
    else if (key === "PageDown") {
      video.volume = Math.max(video.volume - 0.1, 0);
    }
  });
}

/**
 * Adds Thyme-player specific shortcuts.
 */
export function addPlayerShortcuts() {
  window.addEventListener("keydown", function (evt) {
    if (thymeAttributes.lockKeyListeners) {
      return;
    }
    const key = evt.key;
    if (key === "i") {
      $("#ia-active").trigger("click");
    }
    else if (key === "ArrowUp") {
      $("#next-chapter").trigger("click");
    }
    else if (key === "ArrowDown") {
      $("#previous-chapter").trigger("click");
    }

    // annotation-related shortcuts
    if (thymeAttributes.disableAnnotationKeyListeners) {
      return;
    }
    else if (key === "a") {
      $("#annotation-previous-button").trigger("click");
    }
    else if (key === "s") {
      $("#annotation-goto-button").trigger("click");
    }
    else if (key === "d") {
      $("#annotation-next-button").trigger("click");
    }
  });
}

/**
 * Adds Thyme feedback specific shortcuts.
 */
export function addFeedbackShortcuts() {
  window.addEventListener("keydown", function (evt) {
    if (thymeAttributes.lockKeyListeners || thymeAttributes.disableAnnotationKeyListeners) {
      return;
    }
    const key = evt.key;
    if (key === "q") {
      $("#annotation-category-mistake-switch").trigger("click");
    }
    else if (key === "w") {
      $("#annotation-category-content-switch").trigger("click");
    }
    else if (key === "e") {
      $("#annotation-category-presentation-switch").trigger("click");
    }
    else if (key === "r") {
      $("#annotation-category-note-switch").trigger("click");
    }
    else if (key === "a") {
      $("#annotation-previous-button").trigger("click");
    }
    else if (key === "s") {
      $("#annotation-goto-button").trigger("click");
    }
    else if (key === "d") {
      $("#annotation-next-button").trigger("click");
    }
  });
}
