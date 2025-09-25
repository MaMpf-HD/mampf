import { Controller } from "@hotwired/stimulus";

const AUTO_DISMISS_TIMEOUT = 6000;

/**
 * Handles flash messages auto-dismissal with a progress bar.
 */
export default class extends Controller {
  static targets = ["alert"];

  connect() {
    this.observeAlerts();
  }

  observeAlerts() {
    this.setupAllAlertsInitially();

    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType !== Node.ELEMENT_NODE) return;

          if (node.classList.contains("alert")) {
            this.setupAutoDismiss(node);
          }
          else {
            node.querySelectorAll(".alert").forEach(alert => this.setupAutoDismiss(alert));
          }
        });
      });
    });
    this.observer.observe(this.element, { childList: true, subtree: false });
  }

  setupAllAlertsInitially() {
    this.element.querySelectorAll(".alert").forEach(alert => this.setupAutoDismiss(alert));
  }

  setupAutoDismiss(alert) {
    if (alert.dataset.autoDismiss) return;
    alert.dataset.autoDismiss = "true";

    alert.style.position = "relative";
    const bar = this.createProgressBar();
    alert.prepend(bar);

    let start = Date.now();
    let elapsed = 0;
    let paused = false;
    let animationFrameId;

    const updateBar = () => {
      if (paused) {
        animationFrameId = requestAnimationFrame(updateBar);
        return;
      }
      elapsed = Date.now() - start;
      let percent = Math.min(100, (elapsed / AUTO_DISMISS_TIMEOUT) * 100);
      bar.style.width = percent + "%";
      if (elapsed < AUTO_DISMISS_TIMEOUT) {
        animationFrameId = requestAnimationFrame(updateBar);
      }
      else {
        closeAlert();
      }
    };

    const closeAlert = () => {
      if (alert.classList.contains("show")) {
        alert.classList.remove("show");
        alert.classList.add("hide");
        setTimeout(() => alert.remove(), 500);
      }
      else {
        alert.remove();
      }
      cancelAnimationFrame(animationFrameId);
    };

    const pauseTimer = () => {
      if (!paused) {
        paused = true;
        cancelAnimationFrame(animationFrameId);
      }
    };

    const resumeTimer = () => {
      if (paused) {
        paused = false;
        start = Date.now() - elapsed;
        animationFrameId = requestAnimationFrame(updateBar);
      }
    };

    alert.addEventListener("mouseenter", pauseTimer);
    alert.addEventListener("focusin", pauseTimer);
    alert.addEventListener("mouseleave", resumeTimer);
    alert.addEventListener("focusout", resumeTimer);
    animationFrameId = requestAnimationFrame(updateBar);
  }

  createProgressBar() {
    const bar = document.createElement("div");
    bar.style.position = "absolute";
    bar.style.top = "0";
    bar.style.left = "0";
    bar.style.height = "4px";
    bar.style.width = "0%";
    bar.style.background = "rgba(0,0,0,0.15)";
    bar.style.transition = "width 0.2s linear";
    bar.style.zIndex = "2";
    return bar;
  }
}
