export class FloatingBubble {
  constructor(canvas) {
    this.canvas = canvas;
    this.reset();
    this.element = this.createElement();
    this.noiseOffsetX = Math.random() * 1000;
    this.noiseOffsetY = Math.random() * 1000;
    this.morphSpeed = Math.random() * 0.001 + 0.0005;
  }

  reset() {
    this.x = Math.random() * window.innerWidth;
    this.y = Math.random() * window.innerHeight;
    this.vx = (Math.random() - 0.5) * 0.2;
    this.vy = (Math.random() - 0.5) * 0.2;
    this.baseSize = Math.random() * 200 + 100;
    this.opacity = Math.random() * 0.15 + 0.2;
  }

  createElement() {
    const div = document.createElement("div");
    div.className = "floating-bubble";
    div.style.position = "absolute";
    div.style.pointerEvents = "none";
    div.style.zIndex = "0";

    this.canvas.appendChild(div);
    return div;
  }

  noise(x) {
    return Math.sin(x * 0.5) * 0.5 + Math.sin(x * 1.3) * 0.3 + Math.sin(x * 2.7) * 0.2;
  }

  update() {
    this.x += this.vx;
    this.y += this.vy;

    const time = Date.now() * this.morphSpeed;

    const wobble1 = this.noise(time + this.noiseOffsetX) * 0.3;
    const wobble2 = this.noise(time * 1.7 + this.noiseOffsetY) * 0.2;
    const wobble3 = this.noise(time * 0.8 + this.noiseOffsetX * 2) * 0.4;
    const wobble4 = this.noise(time * 2.1 + this.noiseOffsetY * 1.5) * 1.6;

    const r1 = 40 + wobble1 * 30; // top-left
    const r2 = 45 + wobble2 * 25; // top-right
    const r3 = 50 + wobble3 * 35; // bottom-right
    const r4 = 42 + wobble4 * 28; // bottom-left

    // Wrap around screen edges
    if (this.x < -this.baseSize) this.x = window.innerWidth + this.baseSize;
    if (this.x > window.innerWidth + this.baseSize) this.x = -this.baseSize;
    if (this.y < -this.baseSize) this.y = window.innerHeight + this.baseSize;
    if (this.y > window.innerHeight + this.baseSize) this.y = -this.baseSize;

    const gradientX = 30 + wobble1 * 20;
    const gradientY = 30 + wobble2 * 20;

    this.element.style.left = `${this.x - this.baseSize / 2}px`;
    this.element.style.top = `${this.y - this.baseSize / 2}px`;
    this.element.style.width = `${this.baseSize}px`;
    this.element.style.height = `${this.baseSize}px`;
    this.element.style.borderRadius = `${r1}% ${r2}% ${r3}% ${r4}%`;
    this.element.style.background = `radial-gradient(circle at ${gradientX}% ${gradientY}%, 
      rgba(100, 150, 255, ${this.opacity * 0.8}), 
      rgba(150, 100, 255, ${this.opacity * 0.5}), 
      rgba(255, 100, 150, ${this.opacity * 0.3}), 
      transparent)`;
    this.element.style.filter = `blur(${8 + wobble3 * 4}px)`;
    this.element.style.transform = `scale(${1 + wobble4 * 0.1}) rotate(${time * 10}deg)`;
  }

  destroy() {
    if (this.element && this.element.parentNode) {
      this.element.parentNode.removeChild(this.element);
    }
  }
}
