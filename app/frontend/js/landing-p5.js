import p5 from "p5";

export const backgroundSketch = (containerId) => {
  const sketch = (s) => {
    let t = 0;

    s.setup = () => {
      const container = document.getElementById(containerId);
      s.createCanvas(s.windowWidth, s.windowHeight).parent(container);
      s.noFill();
      s.stroke(0, 255, 200, 150);
      s.strokeWeight(1.5);
    };

    s.windowResized = () => {
      const container = document.getElementById(containerId);
      s.resizeCanvas(container.offsetWidth, container.offsetHeight);
    };

    s.draw = () => {
      s.background(10, 10, 30, 20); // translucent background for trails
      s.translate(s.width / 2, s.height / 2);

      s.beginShape();
      for (let angle = 0; angle < s.TWO_PI; angle += 0.01) {
        let x = 200 * s.sin(3 * angle + t * 0.01);
        let y = 200 * s.cos(2 * angle + t * 0.01);
        s.vertex(x, y);
      }
      s.endShape(s.CLOSE);

      t++;
    };
  };

  return new p5(sketch);
};

$(document).on("turbo:load", function () {
  backgroundSketch("p5-background");
});
