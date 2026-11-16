/**
 * A large, blurred blob of color drifting across the landing page.
 *
 * Its look (size, gradient, blur, base shape) is set once on creation.
 * Per frame, only the individual `translate`, `rotate` and `scale` properties
 * change. The browser can apply those on the compositor without repainting
 * (and re-blurring) the bubble, which keeps the CPU load low.
 *
 * The shape "morphing" is done by a slight non-uniform scaling and rotation
 * of the asymmetric blob instead of animating its border-radius.
 */
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
    this.baseSize = Math.random() * 200 + 180;
    this.opacity = Math.random() * 0.15 + 0.1;
  }

  createElement() {
    const div = document.createElement("div");
    div.className = "floating-bubble";
    div.style.width = `${this.baseSize}px`;
    div.style.height = `${this.baseSize}px`;
    div.style.background = `radial-gradient(circle at 30% 30%,
      rgba(100, 150, 255, ${this.opacity * 0.8}),
      rgba(150, 100, 255, ${this.opacity * 0.5}),
      rgba(255, 100, 150, ${this.opacity * 0.3}),
      transparent)`;

    this.canvas.appendChild(div);
    return div;
  }

  noise(x) {
    return Math.sin(x * 0.5) * 0.6 + Math.sin(x * 1.3) * 0.3 + Math.sin(x * 2.7) * 0.2;
  }

  update() {
    this.x += this.vx;
    this.y += this.vy;

    // Wrap around screen edges
    if (this.x < -this.baseSize) this.x = window.innerWidth + this.baseSize;
    if (this.x > window.innerWidth + this.baseSize) this.x = -this.baseSize;
    if (this.y < -this.baseSize) this.y = window.innerHeight + this.baseSize;
    if (this.y > window.innerHeight + this.baseSize) this.y = -this.baseSize;

    const time = Date.now() * this.morphSpeed;

    const wobble1 = this.noise(time + this.noiseOffsetX) * 0.4;
    const wobble2 = this.noise(time * 1.7 + this.noiseOffsetY) * 0.2;
    const wobble3 = this.noise(time * 0.8 + this.noiseOffsetX * 2) * 0.4;
    const wobble4 = this.noise(time * 2.1 + this.noiseOffsetY * 1.5) * 0.6;

    const scaleX = 1 + wobble1 * 0.25 + wobble4 * 0.1;
    const scaleY = 1 + wobble3 * 0.25 + wobble4 * 0.1;
    const rotation = (wobble1 - wobble3 + wobble2) * 40;

    const left = this.x - this.baseSize / 2;
    const top = this.y - this.baseSize / 2;
    const style = this.element.style;
    style.translate = `${left.toFixed(2)}px ${top.toFixed(2)}px`;
    style.rotate = `${rotation.toFixed(2)}deg`;
    style.scale = `${scaleX.toFixed(3)} ${scaleY.toFixed(3)}`;
  }

  destroy() {
    if (this.element && this.element.parentNode) {
      this.element.parentNode.removeChild(this.element);
    }
  }
}
