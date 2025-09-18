import p5 from "p5";

// Vertex shader (pass-through)
const vert = `
  attribute vec3 aPosition;
  void main() {
    gl_Position = vec4(aPosition, 1.0);
  }
`;

// Fragment shader (mathy interference)
const frag = `
  precision mediump float;
  uniform float uTime;
  uniform vec2 uResolution;
  uniform vec2 uPointer;
  uniform float uSeed;

  // Helper for soft circles
  float softCircle(vec2 uv, vec2 center, float radius, float edge) {
    float d = length(uv - center);
    return smoothstep(radius, radius - edge, d);
  }

  void main() {
  vec2 st = gl_FragCoord.xy / uResolution.xy; // normalize 0..1
  st = st * 2.0 - 1.0; // center at (0,0)
  st.x *= uResolution.x / uResolution.y; // fix aspect

  // Use uSeed to randomize initial state
  float seed = uSeed;

  // Animate blob centers (randomized phase)
  vec2 c1 = vec2(0.5 * sin(uTime * 0.4 + seed), 0.5 * cos(uTime * 0.3 + seed * 1.1));
  vec2 c2 = vec2(0.7 * cos(uTime * 0.2 + seed * 2.3), 0.7 * sin(uTime * 0.5 + seed * 0.7));
  vec2 c3 = vec2(0.3 * sin(uTime * 0.6 + 1.0 + seed * 1.7), 0.3 * cos(uTime * 0.7 + 2.0 + seed * 2.1));

  // Blob radii (randomized phase)
  float r1 = 0.6 + 0.1 * sin(uTime * 0.5 + seed * 0.5);
  float r2 = 0.4 + 0.1 * cos(uTime * 0.3 + seed * 1.3);
  float r3 = 0.3 + 0.05 * sin(uTime * 0.7 + seed * 2.7);

  // Soft blobs
  float b1 = softCircle(st, c1, r1, 0.2);
  float b2 = softCircle(st, c2, r2, 0.15);
  float b3 = softCircle(st, c3, r3, 0.12);

  // Combine blobs
  float blobs = b1 + b2 * 0.8 + b3 * 0.6;

  // Background gradient
  float grad = 0.5 + 0.5 * st.y;

  // Color palette (randomized phase)
  vec3 base = mix(vec3(0.18, 0.22, 0.32), vec3(0.32, 0.38, 0.48), grad);
  vec3 accent = vec3(0.7 + 0.2 * sin(uTime + seed), 0.5 + 0.2 * cos(uTime * 0.7 + seed * 1.5), 0.6 + 0.1 * sin(uTime * 0.3 + seed * 2.2));

  vec3 color = base + accent * blobs * 0.5;

  // Subtle vignette
  float vignette = smoothstep(1.2, 0.7, 0.7 * length(st));
  color *= vignette;

  gl_FragColor = vec4(color, 1.0);
  }
`;

export const backgroundSketch = (containerId) => {
  const sketch = (s) => {
    let shaderProgram;
    let pointer = { x: 0.5, y: 0.5 };

    const seed = Math.random() * 1000.0;

    s.setup = () => {
      const container = document.getElementById(containerId);
      s.createCanvas(container.offsetWidth, container.offsetHeight, s.WEBGL).parent(container);
      s.pixelDensity(1); // Prevents high-DPI issues
      shaderProgram = s.createShader(vert, frag);
      s.noStroke();
      s.frameRate(30);
    };

    s.windowResized = () => {
      const container = document.getElementById(containerId);
      s.resizeCanvas(container.offsetWidth, container.offsetHeight);
    };

    s.mouseMoved = () => {
      pointer.x = s.mouseX;
      pointer.y = s.mouseY;
    };

    s.draw = () => {
      s.shader(shaderProgram);
      shaderProgram.setUniform("uTime", s.millis() / 1000.0);
      shaderProgram.setUniform("uResolution", [s.width, s.height]);
      shaderProgram.setUniform("uPointer", [pointer.x, pointer.y]);
      shaderProgram.setUniform("uSeed", seed);

      // Draw a full screen quad
      s.beginShape(s.TRIANGLE_STRIP);
      s.vertex(-s.width / 2, -s.height / 2);
      s.vertex(s.width / 2, -s.height / 2);
      s.vertex(-s.width / 2, s.height / 2);
      s.vertex(s.width / 2, s.height / 2);
      s.endShape();
    };
  };

  return new p5(sketch);
};

$(document).on("turbo:load", function () {
  backgroundSketch("p5-background");
});
