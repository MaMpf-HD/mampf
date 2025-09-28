import { FloatingBubble } from "./bubble.js";
import { MathParticle } from "./particle.js";

class MathBackground {
  constructor() {
    this.canvas = document.getElementById("landing-background");
    if (!this.canvas) return;

    this.particles = [];
    this.bubbles = [];
    this.connections = [];
    this.connectionDistance = 200;
    this.maxConnections = 80;

    this.init();
    this.createParticles();
    this.createBubbles();
    this.animate();

    window.addEventListener("resize", () => this.handleResize());
  }

  init() {
    // Create SVG for connections
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    this.svg.style.position = "absolute";
    this.svg.style.top = "0";
    this.svg.style.left = "0";
    this.svg.style.width = "100%";
    this.svg.style.height = "100%";
    this.svg.style.pointerEvents = "none";
    this.svg.style.zIndex = "0";
    this.canvas.appendChild(this.svg);
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

  updateConnections() {
    this.svg.innerHTML = "";
    this.connections = [];

    for (let i = 0; i < this.particles.length; i++) {
      for (let j = i + 1; j < this.particles.length; j++) {
        const distance = this.particles[i].getDistance(this.particles[j]);

        if (distance < this.connectionDistance && this.connections.length < this.maxConnections) {
          this.connections.push({
            p1: this.particles[i],
            p2: this.particles[j],
            distance: distance,
          });
        }
      }
    }

    this.connections.forEach((connection) => {
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
      const opacity = Math.max(0.4, (this.connectionDistance - connection.distance) / this.connectionDistance * 0.8);

      line.setAttribute("x1", connection.p1.x);
      line.setAttribute("y1", connection.p1.y);
      line.setAttribute("x2", connection.p2.x);
      line.setAttribute("y2", connection.p2.y);
      line.setAttribute("stroke", `rgba(100, 200, 255, ${opacity})`);
      line.setAttribute("stroke-width", "2.5");
      line.setAttribute("stroke-linecap", "round");

      this.svg.appendChild(line);
    });
  }

  animate() {
    this.particles.forEach(particle => particle.update());
    this.bubbles.forEach(bubble => bubble.update());
    this.updateConnections();

    requestAnimationFrame(() => this.animate());
  }

  handleResize() {
    this.svg.style.width = "100%";
    this.svg.style.height = "100%";

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
    if (this.svg && this.svg.parentNode) {
      this.svg.parentNode.removeChild(this.svg);
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new MathBackground();
});
