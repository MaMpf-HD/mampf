import p5 from "p5";

export const backgroundSketch = (containerId) => {
  const sketch = (s) => {
    // Grid settings
    const GRID_SPACING = 48;
    let t = 0;

    function getPointer() {
      if (s.mouseX >= 0 && s.mouseY >= 0 && s.mouseX < s.width && s.mouseY < s.height) {
        return { x: s.mouseX, y: s.mouseY };
      }
      else {
        return { x: s.width / 2, y: s.height / 2 };
      }
    }

    s.setup = () => {
      const container = document.getElementById(containerId);
      s.createCanvas(s.windowWidth, s.windowHeight).parent(container);
      s.noStroke();
    };

    s.windowResized = () => {
      const container = document.getElementById(containerId);
      s.resizeCanvas(container.offsetWidth, container.offsetHeight);
    };

    s.draw = () => {
      s.background(12, 14, 32, 22); // calm, dark background
      let pointer = getPointer();
      let phaseX = (pointer.x / s.width) * s.TWO_PI;
      let phaseY = (pointer.y / s.height) * s.TWO_PI;

      // Draw grid of circles with math-inspired movement
      for (let x = GRID_SPACING / 2; x < s.width; x += GRID_SPACING) {
        for (let y = GRID_SPACING / 2; y < s.height; y += GRID_SPACING) {
          // Abstract movement: combine sine/cosine and noise
          let wave = s.sin(t * 0.012 + x * 0.02 + phaseX) * s.cos(t * 0.008 + y * 0.018 + phaseY);
          let noiseVal = s.noise(x * 0.01, y * 0.01, t * 0.003);
          let r = 12 + 10 * wave * noiseVal;
          let col = s.color(120 + 60 * wave, 180 + 40 * noiseVal, 220, 110 + 60 * Math.abs(wave));
          s.fill(col);
          s.ellipse(x, y, r, r);
        }
      }
      t += 1;
    };
  };

  return new p5(sketch);
};

$(document).on("turbo:load", function () {
  backgroundSketch("p5-background");
});
