import katex from "katex";

/**
 * Mix of formulas from various mathematical fields and related sciences,
 * e.g. including physics formulas.
 *
 * These formulas are randomly shown in the background of the login page.
 */
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
    String.raw`\frac{d}{dx} \left( e^{x^2} \right) = 2x e^{x^2}`,
    String.raw`\int_0^{\infty} x^{n-1}e^{-x} dx = \Gamma(n)`,
    String.raw`\frac{\partial}{\partial x}\left(\frac{\partial f}{\partial y}\right) = \frac{\partial}{\partial y}\left(\frac{\partial f}{\partial x}\right)`,
    String.raw`\oint_C \nabla f \cdot d\mathbf{r} = 0`,
    String.raw`\int_a^b f'(x) dx = f(b) - f(a)`,
  ],

  Analysis: [
    String.raw`\lim_{x \to a} f(x) = L`,
    String.raw`\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}`,
    String.raw`\sum_{n=0}^{\infty} \frac{x^n}{n!} = e^x`,
    String.raw`\lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n = e`,
    String.raw`\forall \varepsilon > 0, \exists \delta > 0 : |x-a| < \delta \Rightarrow |f(x)-L| < \varepsilon`,
    String.raw`\sum_{n=1}^{\infty} \frac{(-1)^{n-1}}{n} = \ln(2)`,
    String.raw`\int_{-\infty}^{\infty} \frac{\sin(x)}{x} dx = \pi`,
    String.raw`\limsup_{n \to \infty} a_n = \lim_{n \to \infty} \sup_{k \geq n} a_k`,
    String.raw`f \text{ continuous} \Leftrightarrow f^{-1}(U) \text{ open for all open } U`,
  ],

  LinearAlgebra: [
    String.raw`Ax = \lambda x`,
    String.raw`\det(A) = \prod_{i=1}^n \lambda_i`,
    String.raw`\langle v, w \rangle = v^T w`,
    String.raw`\operatorname{rank}(A) = \dim(\operatorname{Im} A)`,
    String.raw`\operatorname{Tr}(A) = \sum_{i=1}^n a_{ii}`,
    String.raw`\det(AB) = \det(A)\det(B)`,
    String.raw`A^T A \text{ positive semidefinite}`,
    String.raw`\dim(V) = \dim(\ker T) + \dim(\operatorname{Im} T)`,
    String.raw`\langle Av, w \rangle = \langle v, A^T w \rangle`,
    String.raw`\operatorname{Tr}(AB) = \operatorname{Tr}(BA)`,
    String.raw`\begin{pmatrix} a & b \\ c & d \end{pmatrix}`,
    String.raw`\begin{pmatrix} 1 & 0 \\ 0 & 1 \end{pmatrix} = I`,
    String.raw`\begin{pmatrix} \cos\theta & -\sin\theta \\ \sin\theta & \cos\theta \end{pmatrix}`,
  ],

  TopologyAndHomology: [
    String.raw`\pi_1(S^1) \cong \mathbb{Z}`,
    String.raw`H_n(X) = \ker \partial_n / \operatorname{im} \partial_{n+1}`,
    String.raw`\partial_n \circ \partial_{n+1} = 0`,
    String.raw`\chi(X) = \sum_{i=0}^n (-1)^i \dim H_i(X)`,
    String.raw`X \simeq Y \Rightarrow H_n(X) \cong H_n(Y)`,
    String.raw`\pi_1(X \times Y) \cong \pi_1(X) \times \pi_1(Y)`,
    String.raw`\begin{CD} 0 @>>> A @>>> B @>>> C @>>> 0 \end{CD}`,
    String.raw`\begin{CD} X @>f>> Y \\ @VVV @VVV \\ X' @>f'>> Y' \end{CD}`,
    String.raw`\begin{CD} A @>i>> B @>p>> C \\ @| @VVV @| \\ A @>>> D @>>> C \end{CD}`,
  ],

  AlgebraAndNumberTheory: [
    String.raw`a^2 + b^2 = c^2`,
    String.raw`x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}`,
    String.raw`\binom{n}{k} = \frac{n!}{k!(n-k)!}`,
    String.raw`\sum_{k=0}^n \binom{n}{k} = 2^n`,
    String.raw`a \equiv b \pmod{n} \Leftrightarrow n \mid (a-b)`,
    String.raw`\varphi(n) = n\prod_{p \mid n}\left(1 - \frac{1}{p}\right)`,
    String.raw`a^{\varphi(n)} \equiv 1 \pmod{n}`,
    String.raw`\gcd(a,b) \cdot \operatorname{lcm}(a,b) = ab`,
    String.raw`G/H \text{ group} \Leftrightarrow H \triangleleft G`,
    String.raw`|G| = |H| \cdot [G:H]`,
    String.raw`[K:F] = [K:E][E:F]`,
    String.raw`\mathbb{Z}[i] = \{a + bi : a,b \in \mathbb{Z}\}`,
  ],

  CategoryTheory: [
    String.raw`\operatorname{Hom}(X \times Y, Z) \cong \operatorname{Hom}(X, Z^Y)`,
    String.raw`F \dashv G \Leftrightarrow \operatorname{Hom}(FX, Y) \cong \operatorname{Hom}(X, GY)`,
    String.raw`\begin{CD} A @>f>> B \\ @VgVV @VVhV \\ C @>>k> D \end{CD}`,
    String.raw`\begin{CD} X \times Y @>p_1>> X \\ @Vp_2VV \\ Y \end{CD}`,
    String.raw`\begin{CD} F @>\eta>> GF \\ @| @VVG\varepsilon V \\ F @= F \end{CD}`,
    String.raw`\operatorname{colim}_i F_i \cong \lim_i G_i`,
    String.raw`(F \circ G)(X) = F(G(X))`,
  ],

  ComplexAnalysis: [
    String.raw`e^{i\theta} = \cos\theta + i\sin\theta`,
    String.raw`\oint_C f(z) dz = 2\pi i \sum \operatorname{Res}(f, z_k)`,
    String.raw`f \text{ holomorphic} \Rightarrow f \text{ analytic}`,
    String.raw`\oint_C \frac{dz}{z-a} = 2\pi i`,
    String.raw`|f(z)| \leq M \text{ bounded entire} \Rightarrow f \text{ constant}`,
    String.raw`f(z) = \sum_{n=0}^{\infty} \frac{f^{(n)}(a)}{n!}(z-a)^n`,
  ],

  DifferentialGeometry: [
    String.raw`\nabla_X Y - \nabla_Y X = [X,Y]`,
    String.raw`R(X,Y)Z = \nabla_X \nabla_Y Z - \nabla_Y \nabla_X Z - \nabla_{[X,Y]} Z`,
    String.raw`K = \frac{R_{1212}}{g_{11}g_{22} - g_{12}^2}`,
    String.raw`d(df) = 0`,
    String.raw`\int_M d\omega = \int_{\partial M} \omega`,
    String.raw`\begin{CD} TM @>d\pi>> M \\ @| @| \\ TM @>>p> M \end{CD}`,
  ],

  ProbabilityAndStats: [
    String.raw`P(A \cap B) = P(A|B)P(B)`,
    String.raw`E[X + Y] = E[X] + E[Y]`,
    String.raw`\operatorname{Var}(X) = E[X^2] - (E[X])^2`,
    String.raw`P(A \cup B) = P(A) + P(B) - P(A \cap B)`,
    String.raw`\operatorname{Cov}(X,Y) = E[XY] - E[X]E[Y]`,
    String.raw`X \perp Y \Rightarrow E[XY] = E[X]E[Y]`,
    String.raw`\varphi(t) = E[e^{itX}]`,
  ],

  FunctionalAnalysis: [
    String.raw`\|T\| = \sup_{\|x\|=1} \|Tx\|`,
    String.raw`\langle x, y \rangle \leq \|x\| \|y\|`,
    String.raw`\|x + y\| \leq \|x\| + \|y\|`,
    String.raw`X \text{ complete} \Leftrightarrow X \text{ Banach}`,
    String.raw`H \text{ Banach with inner product} \Leftrightarrow H \text{ Hilbert}`,
    String.raw`T^* : Y^* \to X^*`,
  ],

  SetTheoryAndLogic: [
    String.raw`|A| = |\mathcal{P}(A)| \Leftrightarrow \text{false}`,
    String.raw`\aleph_0 = |\mathbb{N}|`,
    String.raw`2^{\aleph_0} = |\mathbb{R}|`,
    String.raw`A \subseteq B \text{ and } B \subseteq A \Rightarrow A = B`,
    String.raw`\bigcup_{i \in I} A_i = \{x : \exists i \in I, x \in A_i\}`,
    String.raw`(P \Rightarrow Q) \Leftrightarrow (\neg Q \Rightarrow \neg P)`,
  ],

  Physics: [
    String.raw`E = mc^2`,
    String.raw`F = ma`,
    String.raw`e^{i\pi} + 1 = 0`,
    String.raw`\Delta x \Delta p \geq \frac{\hbar}{2}`,
    String.raw`\mathbf{F} = q(\mathbf{E} + \mathbf{v} \times \mathbf{B})`,
    String.raw`\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}`,
    String.raw`\nabla \cdot \mathbf{B} = 0`,
    String.raw`\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}`,
    String.raw`\nabla \times \mathbf{B} = \mu_0 \mathbf{J} + \mu_0 \epsilon_0 \frac{\partial \mathbf{E}}{\partial t}`,
    String.raw`i\hbar\frac{\partial}{\partial t}\Psi = \hat{H}\Psi`,
  ],
};

const mathFormulas = Object.values(mathFormulasByCategory).flat();
const usedFormulas = new Set();

export class MathParticle {
  static getAvailableCount() {
    return mathFormulas.length - usedFormulas.size;
  }

  static reset() {
    usedFormulas.clear();
  }

  constructor(canvas) {
    this.canvas = canvas;
    this.reset();
    this.formula = this.pickUnusedFormula();
    this.element = this.createElement();
    this.connections = [];

    this.lastUpdateTime = performance.now();
  }

  pickUnusedFormula() {
    const availableFormulas = mathFormulas.filter(f => !usedFormulas.has(f));
    if (availableFormulas.length === 0) {
      return mathFormulas[Math.floor(Math.random() * mathFormulas.length)];
    }
    const formula = availableFormulas[Math.floor(Math.random() * availableFormulas.length)];
    usedFormulas.add(formula);
    return formula;
  }

  reset() {
    this.x = Math.random() * window.innerWidth;
    this.y = Math.random() * window.innerHeight;
    this.vx = (Math.random() - 0.5) * 0.5;
    this.vy = (Math.random() - 0.5) * 0.5;
    this.size = Math.random() * 0.7 + 0.55;
    this.opacity = Math.random() * 0.7 + 0.3;
    this.baseRotation = (Math.random() - 0.5) * Math.PI * 0.4;
    this.rotationAmplitude = Math.PI * 0.22;
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
      katex.render(this.formula, div, { throwOnError: false, displayMode: true });
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
    if (this.formula) {
      usedFormulas.delete(this.formula);
    }
  }

  wrapAround(margin) {
    if (this.x < -margin) this.x = window.innerWidth + margin;
    if (this.x > window.innerWidth + margin) this.x = -margin;
    if (this.y < -margin) this.y = window.innerHeight + margin;
    if (this.y > window.innerHeight + margin) this.y = -margin;
  }
}
