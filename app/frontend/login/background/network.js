export class NetworkGraph {
  /**
   * Renders a network of interconnected particles on a single 2D canvas.
   * The connections between particles are dynamically created and faded based on
   * their proximity, using a spatial grid for efficient neighbor detection.
   *
   * Drawing all lines on one canvas is much cheaper than moving many SVG
   * elements that each carry their own CSS filter and animation. The glow is
   * a wider, faint stroke below each line, the pulse is computed per frame.
   */
  constructor(container, particles) {
    this.container = container;
    this.particles = particles;

    this.connectionDistance = 210;
    this.maxNumConnections = 25;
    this.fadeSpeed = 0.02;
    this.minOpacity = 0.15;
    this.maxOpacity = 0.65;
    this.pulseDurationMs = 3000;

    this.frameCounter = 0;
    this.connections = new Map();

    this.init();
  }

  init() {
    this.canvasElement = document.createElement("canvas");
    this.canvasElement.className = "network-canvas";
    this.container.appendChild(this.canvasElement);
    this.ctx = this.canvasElement.getContext("2d");
    this.resize();
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

    this.updateConnectionOpacities();
    this.cleanupConnections();
    this.draw();
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
      this.connections.set(key, {
        particle1,
        particle2,
        distSq,
        targetOpacity: this.calculateOpacityFromSq(distSq, connectionDistanceSq),
        currentOpacity: 0,
        createdAt: performance.now(),
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

  updateConnectionOpacities() {
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
    }
  }

  /**
   * Pulses the opacity between 0.6 and 1.0 over `pulseDurationMs`,
   * starting at 0.6 when the connection is created.
   */
  pulseFactor(connection, now) {
    const phase = ((now - connection.createdAt) / this.pulseDurationMs) * 2 * Math.PI;
    return 0.8 - 0.2 * Math.cos(phase);
  }

  draw() {
    const ctx = this.ctx;
    ctx.clearRect(0, 0, this.width, this.height);

    const now = performance.now();
    for (const connection of this.connections.values()) {
      if (connection.currentOpacity <= 0.001) continue;

      const { particle1, particle2 } = connection;
      const alpha = connection.currentOpacity * this.pulseFactor(connection, now);

      ctx.beginPath();
      ctx.moveTo(particle1.x, particle1.y);
      ctx.lineTo(particle2.x, particle2.y);

      // Glow
      ctx.globalAlpha = alpha * 0.25;
      ctx.lineWidth = 8;
      ctx.stroke();

      // Core line
      ctx.globalAlpha = alpha;
      ctx.lineWidth = 2.5;
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  cleanupConnections() {
    for (const [key, connection] of this.connections.entries()) {
      if (connection.fadingOut && connection.currentOpacity <= 0.001) {
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
      this.updateConnectionOpacities();
      this.draw();
    }
  }

  /**
   * Matches the canvas resolution to its displayed size (capped at 2x pixel
   * density, which is sharp enough for thin lines).
   */
  resize() {
    if (!this.canvasElement) return;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.width = this.container.clientWidth;
    this.height = this.container.clientHeight;
    this.canvasElement.width = Math.round(this.width * dpr);
    this.canvasElement.height = Math.round(this.height * dpr);

    // Changing the canvas size resets the context state.
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.ctx.lineCap = "round";
    this.ctx.strokeStyle = "rgb(100, 200, 255)";
  }

  destroy() {
    this.connections.clear();

    if (this.canvasElement && this.canvasElement.parentNode) {
      this.canvasElement.parentNode.removeChild(this.canvasElement);
    }
  }
}
