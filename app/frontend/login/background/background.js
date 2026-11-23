import katex from "katex";
import { mathFormulas } from "./formulas.js";

// One element per this many pixels of viewport width
const FORMULA_COUNT_FACTOR = 150;
const BUBBLE_COUNT_FACTOR = 400;

/**
 * Fills the landing page background with drifting formulas and bubbles.
 *
 * JS only creates the elements once, with random positions and motion
 * parameters as CSS variables. The motion itself is a CSS animation of
 * `translate`, `rotate`, `scale` and `opacity` (see background.scss),
 * which the browser runs on the compositor: no JS, style recalculation,
 * layout or repaint per frame.
 */
function populateBackground() {
  const container = document.getElementById("landing-background");
  if (!container) return;

  // Turbo restores cached pages including the elements created here.
  container.replaceChildren();

  const bubbleCount = Math.floor(window.innerWidth / BUBBLE_COUNT_FACTOR) + 2;
  for (let i = 0; i < bubbleCount; i++) {
    container.appendChild(createBubble());
  }

  const formulaCount = Math.floor(window.innerWidth / FORMULA_COUNT_FACTOR);
  pickFormulas(formulaCount).forEach((formula) => {
    container.appendChild(createFormula(formula));
  });
}

/**
 * A large, soft blob of color. The gradient itself fades out towards the
 * edges, so the bubble needs no (expensive) blur filter.
 */
function createBubble() {
  const element = document.createElement("div");
  element.className = "floating-bubble";

  const width = random(220, 420);
  const driftDuration = random(50, 90);
  const morphDuration = random(15, 30);
  setVariables(element, {
    "left": `${random(0, 100)}%`,
    "top": `${random(0, 100)}%`,
    "width": `${width}px`,
    "height": `${width * random(0.75, 1.25)}px`,
    "dx": `${random(-15, 15)}vw`,
    "dy": `${random(-15, 15)}vh`,
    "drift-duration": `${driftDuration}s`,
    "drift-delay": `${-random(0, driftDuration)}s`,
    "morph-duration": `${morphDuration}s`,
    "morph-delay": `${-random(0, morphDuration)}s`,
  });

  return element;
}

function createFormula(formula) {
  const element = document.createElement("div");
  element.className = "math-particle";
  element.style.fontSize = `${random(0.55, 1.25)}rem`;
  element.style.opacity = random(0.3, 1);

  const baseRotation = random(-20, 20);
  const swayAmplitude = random(5, 15);
  const driftDuration = random(40, 70);
  const swayDuration = random(8, 16);
  setVariables(element, {
    "left": `${random(0, 100)}%`,
    "top": `${random(0, 100)}%`,
    "dx": `${random(-20, 20)}vw`,
    "dy": `${random(-20, 20)}vh`,
    "rotate-from": `${baseRotation - swayAmplitude}deg`,
    "rotate-to": `${baseRotation + swayAmplitude}deg`,
    "drift-duration": `${driftDuration}s`,
    "drift-delay": `${-random(0, driftDuration)}s`,
    "sway-duration": `${swayDuration}s`,
    "sway-delay": `${-random(0, swayDuration)}s`,
  });

  try {
    katex.render(formula, element, { throwOnError: false, displayMode: true });
  }
  catch (err) {
    console.error("Failed to render formula with KaTeX:", formula, err);
    element.textContent = formula;
  }

  return element;
}

/**
 * Returns `count` distinct formulas in random order (Fisher-Yates shuffle).
 */
function pickFormulas(count) {
  const formulas = [...mathFormulas];
  for (let i = formulas.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [formulas[i], formulas[j]] = [formulas[j], formulas[i]];
  }
  return formulas.slice(0, count);
}

function setVariables(element, variables) {
  for (const [name, value] of Object.entries(variables)) {
    element.style.setProperty(`--${name}`, value);
  }
}

function random(min, max) {
  return min + Math.random() * (max - min);
}

document.addEventListener("turbo:load", populateBackground);
