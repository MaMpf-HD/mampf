export class NetworkGraph {
  /**
   * Renders a network of interconnected particles in an SVG canvas.
   * The connections between particles are dynamically created and faded based on
   * their proximity, using a spatial grid for efficient neighbor detection.
   */
  constructor(container, particles) {
    this.container = container;
    this.particles = particles;

    this.connectionDistance = 210;
    this.maxNumConnections = 25;
    this.fadeSpeed = 0.02;
    this.minOpacity = 0.15;
    this.maxOpacity = 0.65;

    this.frameCounter = 0;
    this.connections = new Map();

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

  updateConnections() {
    const numParticles = this.particles.length;
    if (numParticles === 0) return;

    const connectionLimit = this.maxNumConnections;
    const connectionDistance = this.connectionDistance;
    const connectionDistanceSq = connectionDistance * connectionDistance;

    const { positionsX, positionsY } = this._getParticlePositions(numParticles);
    const grid = this._buildSpatialGrid(positionsX, positionsY, connectionDistance);

    const seenConnections = new Set();
    let createdConnections = 0;

    for (let i = 0; i < numParticles; i++) {
      const gridX = Math.floor(positionsX[i] / connectionDistance);
      const gridY = Math.floor(positionsY[i] / connectionDistance);

      for (let offsetY = -1; offsetY <= 1; offsetY++) {
        for (let offsetX = -1; offsetX <= 1; offsetX++) {
          const cell = grid.get(`${gridX + offsetX},${gridY + offsetY}`);
          if (!cell) continue;

          for (const j of cell) {
            if (i >= j) continue;

            const key = `${i}-${j}`;
            if (seenConnections.has(key)) continue;

            const dx = positionsX[i] - positionsX[j];
            const dy = positionsY[i] - positionsY[j];
            const distSq = dx * dx + dy * dy;

            if (distSq < connectionDistanceSq) {
              this._createOrUpdateConnection(i, j, distSq, connectionDistanceSq, key);
              seenConnections.add(key);
              createdConnections++;
              if (createdConnections >= connectionLimit) {
                break;
              }
            }
          }
          if (createdConnections >= connectionLimit) break;
        }
        if (createdConnections >= connectionLimit) break;
      }
      if (createdConnections >= connectionLimit) break;
    }

    for (const [key, connection] of this.connections.entries()) {
      if (!seenConnections.has(key)) {
        connection.fadingIn = false;
        connection.fadingOut = true;
        connection.targetOpacity = 0;
      }
    }

    this.updateConnectionElements();
    this.cleanupConnections();
  }

  _getParticlePositions(numParticles) {
    const positionsX = new Float32Array(numParticles);
    const positionsY = new Float32Array(numParticles);
    for (let i = 0; i < numParticles; i++) {
      const p = this.particles[i];
      positionsX[i] = p.x;
      positionsY[i] = p.y;
    }
    return { positionsX, positionsY };
  }

  _buildSpatialGrid(positionsX, positionsY, cellSize) {
    const numParticles = positionsX.length;
    const grid = new Map();
    for (let i = 0; i < numParticles; i++) {
      const gridX = Math.floor(positionsX[i] / cellSize);
      const gridY = Math.floor(positionsY[i] / cellSize);
      const key = `${gridX},${gridY}`;
      let cell = grid.get(key);
      if (!cell) {
        cell = [];
        grid.set(key, cell);
      }
      cell.push(i);
    }
    return grid;
  }

  _createOrUpdateConnection(i, j, distSq, connectionDistanceSq, key) {
    const particle1 = this.particles[i];
    const particle2 = this.particles[j];
    if (!this.connections.has(key)) {
      const element = this.createConnectionElement();
      this.connections.set(key, {
        particle1,
        particle2,
        distSq,
        targetOpacity: this.calculateOpacityFromSq(distSq, connectionDistanceSq),
        currentOpacity: 0,
        element,
        fadingIn: true,
        fadingOut: false,
      });
    }
    else {
      const connection = this.connections.get(key);
      connection.distSq = distSq;
      connection.targetOpacity = this.calculateOpacityFromSq(distSq, connectionDistanceSq);
      connection.fadingIn = true;
      connection.fadingOut = false;
    }
  }

  calculateOpacity(distance) {
    const normalizedDistance = (this.connectionDistance - distance) / this.connectionDistance;
    return Math.max(this.minOpacity, normalizedDistance * this.maxOpacity);
  }

  calculateOpacityFromSq(distSq, maxDistSq) {
    const normalized = 1 - distSq / maxDistSq;
    return Math.max(this.minOpacity, normalized * this.maxOpacity);
  }

  createConnectionElement() {
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
    line.setAttribute("stroke-width", "2.5");
    line.setAttribute("stroke-linecap", "round");
    line.setAttribute("stroke", "rgb(100,200,255)");
    line.setAttribute("stroke-opacity", "0");
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

      const { particle1, particle2, element, currentOpacity } = connection;

      element.setAttribute("x1", particle1.x);
      element.setAttribute("y1", particle1.y);
      element.setAttribute("x2", particle2.x);
      element.setAttribute("y2", particle2.y);
      element.setAttribute("stroke-opacity", String(currentOpacity));

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
    this.frameCounter++;
    if (this.frameCounter > 50) {
      this.frameCounter = 0;
      this.updateConnections();
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
