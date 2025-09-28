import katex from "katex";

const mathFormulas = [
  "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}",
  // Maxwell's equations (differential form)
  "\\nabla \\cdot \\mathbf{E} = \\frac{\\rho}{\\epsilon_0}",
  "\\nabla \\cdot \\mathbf{B} = 0",
  "\\nabla \\times \\mathbf{E} = -\\frac{\\partial \\mathbf{B}}{\\partial t}",
  "\\nabla \\times \\mathbf{B} = \\mu_0 \\mathbf{J} + \\mu_0 \\epsilon_0 \\frac{\\partial \\mathbf{E}}{\\partial t}",
  // Maxwell's equations (integral form)
  "\\oint_{S} \\mathbf{E} \\cdot d\\mathbf{A} = \\frac{Q_{\\text{enc}}}{\\epsilon_0}",
  "\\oint_{S} \\mathbf{B} \\cdot d\\mathbf{A} = 0",
  "\\oint_{C} \\mathbf{E} \\cdot d\\mathbf{l} = -\\frac{d\\Phi_B}{dt}",
  "\\oint_{C} \\mathbf{B} \\cdot d\\mathbf{l} = \\mu_0 I_{\\text{enc}} + \\mu_0 \\epsilon_0 \\frac{d\\Phi_E}{dt}",
  "e^{i\\pi} + 1 = 0",
  "\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}",
  "\\frac{d}{dx}[\\sin(x)] = \\cos(x)",
  "\\lim_{x \\to 0} \\frac{\\sin(x)}{x} = 1",
  "\\nabla \\cdot \\mathbf{E} = \\frac{\\rho}{\\epsilon_0}",
  "F = ma",
  "\\Delta x \\Delta p \\geq \\frac{\\hbar}{2}",
  "\\sum_{k=0}^{n} \\binom{n}{k} = 2^n",
  "\\int_0^1 x^n dx = \\frac{1}{n+1}",
  "\\pi = 4\\sum_{n=0}^{\\infty} \\frac{(-1)^n}{2n+1}",
  "\\mathbf{F} = q(\\mathbf{E} + \\mathbf{v} \\times \\mathbf{B})",
  "\\zeta(2) = \\sum_{n=1}^{\\infty} \\frac{1}{n^2}",
  "\\sin^2(x) + \\cos^2(x) = 1",
  "\\log_a(xy) = \\log_a(x) + \\log_a(y)",
  "\\frac{d}{dx}[e^x] = e^x",
  "\\int e^x dx = e^x + C",
  "a^2 + b^2 = c^2",
  "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}",
  "\\sum_{n=0}^{\\infty} \\frac{x^n}{n!} = e^x",
  "\\oint \\mathbf{E} \\cdot d\\mathbf{l} = -\\frac{d\\Phi_B}{dt}",
  "\\nabla^2 \\phi = 4\\pi G \\rho",
  "\\frac{\\partial u}{\\partial t} = \\alpha \\nabla^2 u",
  "\\mathbf{J} = \\sigma \\mathbf{E}",
  "\\vec{\\nabla} \\times \\vec{B} = \\mu_0 \\vec{J}",
  "\\int_{-\\infty}^{\\infty} \\frac{\\sin(x)}{x} dx = \\pi",
  "\\Gamma(n) = (n-1)!",
  "\\det(AB) = \\det(A)\\det(B)",
  "\\text{tr}(A + B) = \\text{tr}(A) + \\text{tr}(B)",
  "\\|\\mathbf{u} + \\mathbf{v}\\| \\leq \\|\\mathbf{u}\\| + \\|\\mathbf{v}\\|",
  "\\int_0^{2\\pi} \\sin^2(x) dx = \\pi",
  "\\lim_{n \\to \\infty} \\left(1 + \\frac{1}{n}\\right)^n = e",
  "\\sum_{n=0}^{\\infty} \\frac{(-1)^n x^{2n+1}}{(2n+1)!} = \\sin(x)",
  "\\cos(A + B) = \\cos A \\cos B - \\sin A \\sin B",
  "\\frac{d}{dx}[\\ln(x)] = \\frac{1}{x}",
  "\\int \\frac{1}{x} dx = \\ln|x| + C",
  "\\binom{n}{k} = \\frac{n!}{k!(n-k)!}",
  "P(A \\cap B) = P(A|B)P(B)",
  "E[X + Y] = E[X] + E[Y]",
  "\\text{Var}(X) = E[X^2] - (E[X])^2",
  "\\alpha", "\\beta", "\\gamma", "\\delta", "\\epsilon", "\\zeta", "\\eta", "\\theta", "\\iota", "\\kappa", "\\lambda", "\\mu", "\\nu", "\\xi", "\\pi", "\\rho", "\\sigma", "\\tau", "\\upsilon", "\\phi", "\\chi", "\\psi", "\\omega",
  "\\Gamma", "\\Delta", "\\Theta", "\\Lambda", "\\Xi", "\\Pi", "\\Sigma", "\\Phi", "\\Psi", "\\Omega",
  "\\infty", "\\partial", "\\nabla", "\\sum", "\\prod", "\\int", "\\oint", "\\iint", "\\iiint",
  "\\forall", "\\exists", "\\nexists", "\\in", "\\notin", "\\ni", "\\subset", "\\subseteq", "\\supset", "\\supseteq", "\\cup", "\\cap", "\\setminus",
  "\\Rightarrow", "\\Leftarrow", "\\Leftrightarrow", "\\equiv", "\\approx", "\\sim", "\\simeq", "\\cong", "\\neq", "\\leq", "\\geq", "\\ll", "\\gg",
  "\\pm", "\\mp", "\\times", "\\div", "\\cdot", "\\ast", "\\star", "\\circ", "\\bullet", "\\diamond", "\\triangle", "\\square",
];

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
