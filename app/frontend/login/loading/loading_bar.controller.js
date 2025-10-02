import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.startProgressOnceProgressBarExists();
  }

  startProgressOnceProgressBarExists() {
    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType !== Node.ELEMENT_NODE) {
            continue;
          }

          if (node.classList && node.classList.contains("turbo-progress-bar")) {
            observer.disconnect();
            this.startProgress();
          }
        }
      }
    });

    observer.observe(document.documentElement, { childList: true, subtree: false });
  }

  disconnect() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
  }

  startProgress() {
    const styleObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        this.targetProgress = parseFloat(mutation.target.style.width);
        if (this.targetProgress >= 100) {
          styleObserver.disconnect();
          cancelAnimationFrame(this.animationFrame);
          this.animateToCompletion();
        }
      }
    });

    const target = document.getElementsByClassName("turbo-progress-bar")[0];
    styleObserver.observe(target, { attributes: true, attributeFilter: ["style"] });

    this.progress = 0;
    const step = () => {
      this.progress += 0.02 + Math.random() * 0.2;
      this.updateProgressInUI(this.progress);
      this.animationFrame = requestAnimationFrame(step);
    };
    this.animationFrame = requestAnimationFrame(step);
  }

  animateToCompletion() {
    const step = () => {
      const diff = Math.min(15, 100 - this.progress);
      const cap = Math.max(0.02, 1 - Math.exp(-10 * Math.pow(diff / 100, 2)));
      this.progress += 0.09 * diff * cap;

      if (this.progress >= 100) {
        this.progress = 100;
        this.updateProgressInUI(this.progress);
        return;
      }

      this.updateProgressInUI(this.progress);
      this.animationFrame = requestAnimationFrame(step);
    };

    this.animationFrame = requestAnimationFrame(step);
  }

  updateProgressInUI(value) {
    document.documentElement.style.setProperty("--login-progress", `${value}%`);
  }
}
