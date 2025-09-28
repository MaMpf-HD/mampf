import { FloatingBubble } from "./bubble.js";
import { NetworkGraph } from "./network.js";
import { MathParticle } from "./particle.js";

class MathBackground {
  constructor() {
    this.canvas = document.getElementById("landing-background");
    if (!this.canvas) return;

    this.particles = [];
    this.bubbles = [];

    this.init();
    this.createParticles();
    this.createBubbles();
    this.createNetwork();
    this.animate();

    window.addEventListener("resize", () => this.handleResize());
  }

  init() {
  }

  createParticles() {
    const particleCount = Math.floor(window.innerWidth / 25);

    for (let i = 0; i < particleCount; i++) {
      this.particles.push(new MathParticle(this.canvas));
    }
  }

  createBubbles() {
    const bubbleCount = Math.floor(window.innerWidth / 400) + 2;

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

  animate() {
    this.particles.forEach(particle => particle.update());
    this.bubbles.forEach(bubble => bubble.update());
    this.network.update();

    this.animationId = requestAnimationFrame(() => this.animate());
  }

  handleResize() {
    this.network.resize();

    const newParticleCount = Math.floor(window.innerWidth / 60);
    this.adjustArrayCount(this.particles, newParticleCount, () => new MathParticle(this.canvas));

    const newBubbleCount = Math.floor(window.innerWidth / 400) + 2;
    this.adjustArrayCount(this.bubbles, newBubbleCount, () => new FloatingBubble(this.canvas));
  }

  destroy() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }

    this.particles.forEach(particle => particle.destroy());
    this.particles = [];
    this.bubbles.forEach(bubble => bubble.destroy());
    this.bubbles = [];
    if (this.network) {
      this.network.destroy();
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new MathBackground();
});
