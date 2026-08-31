import { Component } from "~/js/thyme/components/component";

export class SubtitleButton extends Component {
  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    const tracks = video.textTracks;
    let subtitleTrack = null;
    for (let i = 0; i < tracks.length; i++) {
      if (tracks[i].kind === "subtitles" || tracks[i].kind === "captions") {
        subtitleTrack = tracks[i];
        break;
      }
    }

    if (!subtitleTrack) {
      element.style.display = "none";
      return;
    }

    // Use custom subtitle container
    subtitleTrack.mode = "hidden";

    let container = document.getElementById("custom-subtitle-container");
    if (!container) {
      container = document.createElement("div");
      container.id = "custom-subtitle-container";
      container.className = "thyme-custom-subtitles";
      container.setAttribute("role", "status");
      container.setAttribute("aria-live", "polite");
      container.setAttribute("aria-atomic", "true");
      document.getElementById("hypervideo-container").appendChild(container);
    }

    let subtitlesEnabled = false;
    let lastText = "";

    const updateSubtitles = () => {
      if (!subtitlesEnabled) {
        if (lastText !== "") {
          lastText = "";
          container.replaceChildren();
        }
        return;
      }

      let text = "";
      if (subtitleTrack.activeCues && subtitleTrack.activeCues.length > 0) {
        for (let i = 0; i < subtitleTrack.activeCues.length; i++) {
          text += subtitleTrack.activeCues[i].text + "\n";
        }
      }
      text = text.trim();

      if (text === lastText) {
        return;
      }
      lastText = text;

      container.replaceChildren();
      if (!text) {
        return;
      }

      const span = document.createElement("span");
      span.textContent = text;
      container.appendChild(span);
    };

    const setEnabled = (enabled) => {
      element.classList.toggle("bi-badge-cc-fill", enabled);
      element.classList.toggle("bi-badge-cc", !enabled);
      element.style.color = enabled ? "#282828ff" : "";
      element.setAttribute("aria-pressed", String(enabled));
    };

    element.addEventListener("click", function () {
      subtitlesEnabled = !subtitlesEnabled;
      setEnabled(subtitlesEnabled);
      updateSubtitles();
    });

    subtitleTrack.addEventListener("cuechange", updateSubtitles);
    video.addEventListener("timeupdate", updateSubtitles);

    setEnabled(false);
  }
}
