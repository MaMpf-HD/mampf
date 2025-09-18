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

  void main() {
    vec2 st = gl_FragCoord.xy / uResolution.xy; // normalize 0..1
    st = st * 2.0 - 1.0; // center at (0,0)
    st.x *= uResolution.x / uResolution.y; // fix aspect

    // Distance to pointer (also normalized to [-1,1])
    vec2 p = (uPointer / uResolution) * 2.0 - 1.0;
    float d = distance(st, p);

    // Interference pattern (waves + pointer effect)
    float wave = sin(10.0 * st.x + uTime * 0.8) *
                 cos(10.0 * st.y + uTime * 0.6);

    float ripple = sin(20.0 * d - uTime * 2.0);

    float intensity = 0.5 + 0.5 * (wave * 0.6 + ripple * 0.4);

    // Hue-like coloring
    vec3 color = vec3(
      0.4 + 0.4 * intensity,
      0.6 + 0.4 * sin(uTime + intensity * 3.14),
      0.8 + 0.2 * cos(uTime * 0.7 + intensity * 2.0)
    );

    gl_FragColor = vec4(color, 1.0);
  }
`;

export const backgroundSketch = (containerId) => {
  const sketch = (s) => {
    let shaderProgram;
    let pointer = { x: 0.5, y: 0.5 };

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
