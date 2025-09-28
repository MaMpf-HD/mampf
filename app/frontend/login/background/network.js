export class NetworkGraph {
  constructor(container, particles) {
    this.container = container;
    this.particles = particles;

    this.connectionDistance = 200;
    this.maxConnections = 80;
    this.fadeSpeed = 0.02;
    this.minOpacity = 0.2;
    this.maxOpacity = 0.6;

    this.connections = new Map();
    this.connectionId = 0;

    this.lastConnectionUpdate = 0;
    this.connectionUpdateInterval = 33;

    this.init();
  }

  init() {
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    this.svg.style.position = "absolute";
    this.svg.style.top = "0";
    this.svg.style.left = "0";
    this.svg.style.width = "100%";
    this.svg.style.height = "100%";
    this.svg.style.pointerEvents = "none";
    this.svg.style.zIndex = "0";
    this.container.appendChild(this.svg);
  }

  setSvgSize() {
    if (!this.svg) return;
    this.svg.style.width = "100%";
    this.svg.style.height = "100%";
  }

  getConnectionKey(p1, p2) {
    const id1 = this.particles.indexOf(p1);
    const id2 = this.particles.indexOf(p2);
    return id1 < id2 ? `${id1}-${id2}` : `${id2}-${id1}`;
  }

  updateConnections() {
    const activeConnections = new Set();

    for (let i = 0; i < this.particles.length; i++) {
      for (let j = i + 1; j < this.particles.length; j++) {
        const p1 = this.particles[i];
        const p2 = this.particles[j];
        const distance = p1.getDistance(p2);
        const key = this.getConnectionKey(p1, p2);

        if (distance < this.connectionDistance && activeConnections.size < this.maxConnections) {
          activeConnections.add(key);

          if (!this.connections.has(key)) {
            this.connections.set(key, {
              p1,
              p2,
              distance,
              targetOpacity: this.calculateOpacity(distance),
              currentOpacity: 0, // Start faded out
              element: this.createConnectionElement(),
              fadingIn: true,
              fadingOut: false,
            });
          }
          else {
            const connection = this.connections.get(key);
            connection.distance = distance;
            connection.targetOpacity = this.calculateOpacity(distance);
            connection.fadingIn = true;
            connection.fadingOut = false;
          }
        }
      }
    }

    for (const [key, connection] of this.connections.entries()) {
      if (!activeConnections.has(key)) {
        connection.fadingIn = false;
        connection.fadingOut = true;
        connection.targetOpacity = 0;
      }
    }

    this.updateConnectionElements();
    this.cleanupConnections();
  }

  calculateOpacity(distance) {
    const normalizedDistance = (this.connectionDistance - distance) / this.connectionDistance;
    return Math.max(this.minOpacity, normalizedDistance * this.maxOpacity);
  }

  createConnectionElement() {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
    line.setAttribute("stroke-width", "2.5");
    line.setAttribute("stroke-linecap", "round");
    this.svg.appendChild(line);
    return line;
  }

  updateConnectionElements() {
    for (const connection of this.connections.values()) {
      if (connection.fadingIn && connection.currentOpacity < connection.targetOpacity) {
        connection.currentOpacity = Math.min(
          connection.targetOpacity,
          connection.currentOpacity + this.fadeSpeed,
        );
      }
      else if (connection.fadingOut && connection.currentOpacity > connection.targetOpacity) {
        connection.currentOpacity = Math.max(
          connection.targetOpacity,
          connection.currentOpacity - this.fadeSpeed,
        );
      }

      const { p1, p2, element, currentOpacity } = connection;

      element.setAttribute("x1", p1.x);
      element.setAttribute("y1", p1.y);
      element.setAttribute("x2", p2.x);
      element.setAttribute("y2", p2.y);
      element.setAttribute("stroke", `rgba(100, 200, 255, ${currentOpacity})`);

      element.style.display = currentOpacity <= 0.001 ? "none" : "block";
    }
  }

  cleanupConnections() {
    for (const [key, connection] of this.connections.entries()) {
      if (connection.fadingOut && connection.currentOpacity <= 0.001) {
        if (connection.element && connection.element.parentNode) {
          connection.element.parentNode.removeChild(connection.element);
        }
        this.connections.delete(key);
      }
    }
  }

  update() {
    const now = performance.now();
    if (now - this.lastConnectionUpdate > this.connectionUpdateInterval) {
      this.updateConnections();
      this.lastConnectionUpdate = now;
    }
    else {
      this.updateConnectionElements();
    }
  }

  resize() {
    this.setSvgSize();
  }

  destroy() {
    for (const connection of this.connections.values()) {
      if (connection.element && connection.element.parentNode) {
        connection.element.parentNode.removeChild(connection.element);
      }
    }
    this.connections.clear();

    if (this.svg && this.svg.parentNode) {
      this.svg.parentNode.removeChild(this.svg);
    }
  }
}
