const BLUR_PX = 10;
// A Gaussian blur fades out after about three standard deviations.
const BLUR_PADDING_PX = 3 * BLUR_PX;

/**
 * A large, blurred blob of color drifting across the landing page.
 *
 * Its look (size, gradient, blur, base shape) is drawn once into its own
 * canvas on creation. Per frame, only the individual `translate`, `rotate`
 * and `scale` properties change. The compositor then just moves a finished
 * texture around. A CSS `filter: blur()` instead would be re-applied to every
 * bubble on every frame, which is expensive, especially without a hardware GPU.
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
    const element = document.createElement("canvas");
    element.className = "floating-bubble";
    this.elementSize = Math.ceil(this.baseSize + 2 * BLUR_PADDING_PX);
    element.width = this.elementSize;
    element.height = this.elementSize;
    this.drawBlob(element);

    this.canvas.appendChild(element);
    return element;
  }

  /**
   * Draws the blurred blob: an asymmetric rounded square filled with a
   * radial gradient, equivalent to
   * `border-radius: 40% 45% 50% 42%` and
   * `radial-gradient(circle at 30% 30%, ...)` in CSS.
   *
   * Browsers without canvas filter support (Safari < 18) fall back to a
   * CSS blur.
   */
  drawBlob(element) {
    const ctx = element.getContext("2d");
    const size = this.baseSize;
    const offset = BLUR_PADDING_PX;

    if ("filter" in ctx) {
      ctx.filter = `blur(${BLUR_PX}px)`;
    }
    else {
      element.style.filter = `blur(${BLUR_PX}px)`;
    }

    // CSS gradients run to the farthest corner by default.
    const centerX = offset + 0.3 * size;
    const centerY = offset + 0.3 * size;
    const radius = Math.SQRT2 * 0.7 * size;
    const gradient = ctx.createRadialGradient(
      centerX, centerY, 0, centerX, centerY, radius,
    );
    gradient.addColorStop(0, `rgba(100, 150, 255, ${this.opacity * 0.8})`);
    gradient.addColorStop(1 / 3, `rgba(150, 100, 255, ${this.opacity * 0.5})`);
    gradient.addColorStop(2 / 3, `rgba(255, 100, 150, ${this.opacity * 0.3})`);
    // Fade to a transparent version of the last color, not to transparent
    // black, which would darken the edge.
    gradient.addColorStop(1, "rgba(255, 100, 150, 0)");

    ctx.beginPath();
    ctx.roundRect(offset, offset, size, size, [
      0.4 * size, 0.45 * size, 0.5 * size, 0.42 * size,
    ]);
    ctx.fillStyle = gradient;
    ctx.fill();
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

    const left = this.x - this.elementSize / 2;
    const top = this.y - this.elementSize / 2;
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
