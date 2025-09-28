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
    // Basic initialization
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
    this.network = new NetworkGraph(this.canvas, this.particles, {
      connectionDistance: 200,
      maxConnections: 80,
      fadeSpeed: 0.02,
      minOpacity: 0.4,
      maxOpacity: 0.8,
    });
  }

  animate() {
    this.particles.forEach(particle => particle.update());
    this.bubbles.forEach(bubble => bubble.update());
    this.network.update();

    requestAnimationFrame(() => this.animate());
  }

  handleResize() {
    this.network.resize();

    const newParticleCount = Math.floor(window.innerWidth / 60);
    const currentCount = this.particles.length;

    if (newParticleCount > currentCount) {
      for (let i = currentCount; i < newParticleCount; i++) {
        this.particles.push(new MathParticle(this.canvas));
      }
    }
    else if (newParticleCount < currentCount) {
      for (let i = currentCount - 1; i >= newParticleCount; i--) {
        this.particles[i].destroy();
        this.particles.splice(i, 1);
      }
    }

    const newBubbleCount = Math.floor(window.innerWidth / 400) + 2;
    const currentBubbleCount = this.bubbles.length;

    if (newBubbleCount > currentBubbleCount) {
      for (let i = currentBubbleCount; i < newBubbleCount; i++) {
        this.bubbles.push(new FloatingBubble(this.canvas));
      }
    }
    else if (newBubbleCount < currentBubbleCount) {
      for (let i = currentBubbleCount - 1; i >= newBubbleCount; i--) {
        this.bubbles[i].destroy();
        this.bubbles.splice(i, 1);
      }
    }
  }

  destroy() {
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
