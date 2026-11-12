import { FloatingBubble } from "./bubble.js";
import { NetworkGraph } from "./network.js";
import { MathParticle } from "./particle.js";

class MathBackground {
  PARTICLES_COUNT_FACTOR = 150;
  BUBBLE_COUNT_FACTOR = 400;

  constructor() {
    this.canvas = document.getElementById("landing-background");
    if (!this.canvas) return;

    this.particles = [];
    this.bubbles = [];

    this.createParticles();
    this.createBubbles();
    this.createNetwork();

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.renderFrame();
    }
    else {
      this.animate();
    }

    this.resizeHandler = () => this.handleResize();
    window.addEventListener("resize", this.resizeHandler);
  }

  createParticles() {
    const desiredCount = Math.floor(window.innerWidth / this.PARTICLES_COUNT_FACTOR);
    const particleCount = Math.min(desiredCount, MathParticle.getAvailableCount());

    for (let i = 0; i < particleCount; i++) {
      this.particles.push(new MathParticle(this.canvas));
    }
  }

  createBubbles() {
    const bubbleCount = Math.floor(window.innerWidth / this.BUBBLE_COUNT_FACTOR) + 2;

    for (let i = 0; i < bubbleCount; i++) {
      this.bubbles.push(new FloatingBubble(this.canvas));
    }
  }

  createNetwork() {
    this.network = new NetworkGraph(this.canvas, this.particles);
  }

  adjustArrayCount(arr, desiredCount, factory) {
    const current = arr.length;
    if (desiredCount > current) {
      for (let i = current; i < desiredCount; i++) {
        arr.push(factory());
      }
    }
    else if (desiredCount < current) {
      for (let i = current - 1; i >= desiredCount; i--) {
        if (arr[i] && typeof arr[i].destroy === "function") arr[i].destroy();
        arr.splice(i, 1);
      }
    }
  }

  renderFrame() {
    this.particles.forEach(particle => particle.update());
    this.bubbles.forEach(bubble => bubble.update());
    this.network.update();
  }

  animate() {
    this.renderFrame();
    this.animationId = requestAnimationFrame(() => this.animate());
  }

  handleResize() {
    this.network.resize();

    const desiredParticleCount = Math.floor(window.innerWidth / this.PARTICLES_COUNT_FACTOR);
    const newParticleCount = Math.min(desiredParticleCount, MathParticle.getAvailableCount() + this.particles.length);
    this.adjustArrayCount(this.particles, newParticleCount, () => new MathParticle(this.canvas));

    const newBubbleCount = Math.floor(window.innerWidth / this.BUBBLE_COUNT_FACTOR) + 2;
    this.adjustArrayCount(this.bubbles, newBubbleCount, () => new FloatingBubble(this.canvas));
  }

  destroy() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }
    window.removeEventListener("resize", this.resizeHandler);

    this.particles?.forEach(particle => particle.destroy());
    this.particles = [];
    this.bubbles?.forEach(bubble => bubble.destroy());
    this.bubbles = [];
    if (this.network) {
      this.network.destroy();
    }
  }
}

let mathBackground = null;

/**
 * Turbo swaps the body on navigation, so the previous background has to be
 * torn down. Otherwise, its animation loop would keep running on detached
 * elements and the loops would pile up with every visited page.
 */
document.addEventListener("turbo:load", () => {
  mathBackground?.destroy();
  mathBackground = new MathBackground();
});
