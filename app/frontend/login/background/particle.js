import katex from "katex";

const mathFormulasByCategory = {
  Calculus: [
    String.raw`\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}`,
    String.raw`\frac{d}{dx}[\sin(x)] = \cos(x)`,
    String.raw`\lim_{x \to 0} \frac{\sin(x)}{x} = 1`,
    String.raw`\int_0^1 x^n dx = \frac{1}{n+1}`,
    String.raw`\int e^x dx = e^x + C`,
    String.raw`\frac{d}{dx}[e^x] = e^x`,
    String.raw`\frac{d}{dx}[\ln(x)] = \frac{1}{x}`,
    String.raw`\int \frac{1}{x} dx = \ln|x| + C`,
    String.raw`\int_a^b f(x)\,dx`,
    String.raw`\frac{d}{dx} \left( e^{x^2} \right) = 2x e^{x^2}`,
  ],

  Analysis: [
    String.raw`\lim_{x \to a} f(x) = L`,
    String.raw`\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}`,
    String.raw`\sum_{n=0}^{\infty} \frac{x^n}{n!} = e^x`,
    String.raw`\lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n = e`,
    String.raw`\forall \varepsilon > 0, \exists N \in \mathbb{N} : \forall n > N, |a_n - a| < \varepsilon`,
  ],

  LinearAlgebra: [
    String.raw`Ax = \lambda x`,
    String.raw`\det(A) = \prod_{i=1}^n \lambda_i`,
    String.raw`\langle v, w \rangle = v^T w`,
    String.raw`\operatorname{rank}(A) = \dim(\operatorname{Im} A)`,
    String.raw`\text{Tr}(A) = \sum_{i=1}^n a_{ii}`,
  ],

  TopologyAndHomology: [
    String.raw`\pi_1(S^1) \cong \mathbb{Z}`,
    String.raw`H_n(X) = \ker \partial_n / \operatorname{im} \partial_{n+1}`,
    String.raw`\partial_{n} \circ \partial_{n+1} = 0`,
  ],

  Physics: [
    String.raw`F = ma`,
    String.raw`e^{i\pi} + 1 = 0`,
    String.raw`\Delta x \Delta p \geq \frac{\hbar}{2}`,
    String.raw`\mathbf{F} = q(\mathbf{E} + \mathbf{v} \times \mathbf{B})`,
    String.raw`\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}`,
    String.raw`\nabla \cdot \mathbf{B} = 0`,
    String.raw`\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}`,
    String.raw`\nabla \times \mathbf{B} = \mu_0 \mathbf{J} + \mu_0 \epsilon_0 \frac{\partial \mathbf{E}}{\partial t}`,
    String.raw`\oint_{S} \mathbf{E} \cdot d\mathbf{A} = \frac{Q_{\text{enc}}}{\epsilon_0}`,
    String.raw`\oint_{C} \mathbf{E} \cdot d\mathbf{l} = -\frac{d\Phi_B}{dt}`,
  ],

  ProbabilityAndStats: [
    String.raw`P(A \cap B) = P(A|B)P(B)`,
    String.raw`E[X + Y] = E[X] + E[Y]`,
    String.raw`\text{Var}(X) = E[X^2] - (E[X])^2`,
  ],

  AlgebraAndNumberTheory: [
    String.raw`a^2 + b^2 = c^2`,
    String.raw`x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}`,
    String.raw`\binom{n}{k} = \frac{n!}{k!(n-k)!}`,
    String.raw`\sum_{k=0}^n \binom{n}{k} = 2^n`,
    String.raw`\pi = 4\sum_{n=0}^{\infty} \frac{(-1)^n}{2n+1}`,
  ],

  OperatorsAndSymbols: [
    String.raw`\infty`,
    String.raw`\partial`,
    String.raw`\nabla`,
    String.raw`\sum`,
    String.raw`\prod`,
    String.raw`\int`,
    String.raw`\oint`,
    String.raw`\forall`,
    String.raw`\exists`,
    String.raw`\in`,
    String.raw`\subset`,
    String.raw`\cup`,
    String.raw`\cap`,
    String.raw`\Rightarrow`,
    String.raw`\Leftrightarrow`,
    String.raw`\pm`,
    String.raw`\times`,
    String.raw`\cdot`,
  ],

  Misc: [
    String.raw`E = mc^2`,
    String.raw`\int_{-\infty}^{\infty} \frac{\sin(x)}{x} dx = \pi`,
    String.raw`\Gamma(n) = (n-1)!`,
    String.raw`\det(AB) = \det(A)\det(B)`,
    String.raw`\|\mathbf{u} + \mathbf{v}\| \leq \|\mathbf{u}\| + \|\mathbf{v}\|`,
    String.raw`\oint_C f(z) dz = 0`,
  ],
};

const mathFormulas = Object.values(mathFormulasByCategory).flat();

export class MathParticle {
  constructor(canvas) {
    this.canvas = canvas;
    this.reset();
    this.formula = mathFormulas[Math.floor(Math.random() * mathFormulas.length)];
    this.element = this.createElement();
    this.connections = [];

    this.lastUpdateTime = performance.now();
  }

  reset() {
    this.x = Math.random() * window.innerWidth;
    this.y = Math.random() * window.innerHeight;
    this.vx = (Math.random() - 0.5) * 0.5;
    this.vy = (Math.random() - 0.5) * 0.5;
    this.size = Math.random() * 0.9 + 0.6;
    this.opacity = Math.random() * 0.7 + 0.3;
    this.baseRotation = (Math.random() - 0.5) * Math.PI * 0.5;
    this.rotationAmplitude = Math.PI * 0.3;
    this.rotationSpeed = (Math.random() - 0.5) * 0.005;
    this.rotationTime = Math.random() * Math.PI * 2;
    this.lastTransform = "";
  }

  createElement() {
    const div = document.createElement("div");
    div.className = "math-particle";
    div.style.position = "absolute";
    div.style.pointerEvents = "none";
    div.style.zIndex = "1";
    div.style.color = "rgba(255, 255, 255, 0.9)";
    div.style.fontSize = `${this.size}rem`;
    div.style.opacity = this.opacity;
    div.style.textShadow = "0 0 10px rgba(255, 255, 255, 0.3)";

    div.style.willChange = "transform";
    div.style.backfaceVisibility = "hidden";
    div.style.perspective = "1000px";

    div.style.left = "0";
    div.style.top = "0";
    div.style.transformOrigin = "center center";

    try {
      katex.render(this.formula, div, { throwOnError: false, displayMode: false });
    }
    catch {
      div.textContent = this.formula;
    }

    this.canvas.appendChild(div);
    return div;
  }

  update() {
    const currentTime = performance.now();
    const deltaTime = currentTime - this.lastUpdateTime;
    this.lastUpdateTime = currentTime;
    const timeMultiplier = Math.min(deltaTime / 16.67, 2);
    this.x += this.vx * timeMultiplier;
    this.y += this.vy * timeMultiplier;
    this.rotationTime += this.rotationSpeed * timeMultiplier;
    this.rotation = this.baseRotation + Math.sin(this.rotationTime) * this.rotationAmplitude;
    this.wrapAround(200);
    const roundedX = Math.round(this.x * 100) / 100;
    const roundedY = Math.round(this.y * 100) / 100;
    const roundedRotation = Math.round(this.rotation * 1000) / 1000;
    const newTransform = `translate3d(${roundedX}px, ${roundedY}px, 0) rotate(${roundedRotation}rad) translate(-50%, -50%)`;
    if (newTransform !== this.lastTransform) {
      this.element.style.transform = newTransform;
      this.lastTransform = newTransform;
    }
  }

  getDistance(other) {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  destroy() {
    if (this.element && this.element.parentNode) {
      this.element.parentNode.removeChild(this.element);
    }
  }

  wrapAround(margin) {
    if (this.x < -margin) this.x = window.innerWidth + margin;
    if (this.x > window.innerWidth + margin) this.x = -margin;
    if (this.y < -margin) this.y = window.innerHeight + margin;
    if (this.y > window.innerHeight + margin) this.y = -margin;
  }
}
