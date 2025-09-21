import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  progress = 0;
  animationFrame = null;
  targetProgress = 0;

  connect() {
    console.log("loading bar controller connected");
    setInterval(() => this.readAndUpdateProgress(), 200);
  }

  readAndUpdateProgress() {
    const bar = document.querySelector(".turbo-progress-bar");
    if (!bar) return;

    const width = bar.style.width;
    if (!width.endsWith("%")) return;
    this.targetProgress = parseFloat(width);
    console.log("progress:", this.targetProgress);
    this.animateProgress();
  }

  disconnect() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
  }

  animateProgress() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }

    const step = () => {
      const diff = this.targetProgress - this.progress;

      if (diff < 1.0) {
        this.setProgress(this.targetProgress);
        return;
      }

      let updateStep = 0.0;

      if (this.targetProgress >= 99.0) {
        console.log("100% REACHED in real life");
        const slowFactor = Math.max(1 - Math.exp(-40 * diff / 100), 0.1);
        updateStep = Math.min(diff * slowFactor, 0.3);
      }
      else {
        console.log(`not yet there, diff: ${diff}`);
        updateStep = Math.min(diff, 0.1);
      }

      console.log(`--> Update Step: ${updateStep.toFixed(2)}`);
      this.setProgress(this.progress + updateStep);
      this.animationFrame = requestAnimationFrame(step);
    };

    this.animationFrame = requestAnimationFrame(step);
  }

  setProgress(value) {
    this.progress = value;
    document.documentElement.style.setProperty("--login-progress", `${value}%`);
  }
}
