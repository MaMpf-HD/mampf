import { PASSING_GRADES, GRADE_MARKER_COLOR } from "./grade_bands";

export function buildHistogramBars(container, maxPoints, studentPoints) {
  if (maxPoints <= 0) return;

  const points = studentPoints.map(p => parseFloat(p));
  const binCount = Math.min(30, Math.max(10, Math.round(maxPoints / 4)));
  const binWidth = Math.ceil(maxPoints / binCount);
  const bins = Array.from({ length: binCount }, (_, i) => ({
    low: i * binWidth,
    high: i === binCount - 1 ? maxPoints : (i + 1) * binWidth - 1,
    count: 0,
  }));

  points.forEach((p) => {
    const idx = Math.min(Math.floor(p / binWidth), binCount - 1);
    bins[idx].count++;
  });

  const maxCount = Math.max(...bins.map(b => b.count), 1);

  container.innerHTML = bins.map((bin) => {
    const pct = Math.round((bin.count / maxCount) * 100);
    const minH = bin.count > 0 ? 4 : 0;
    return `<div class="flex-fill rounded-top"
      style="height: ${pct}%; min-height: ${minH}px;
             background-color: #0d6efd;"
      title="${bin.low}\u2013${bin.high} pts: ${bin.count}"
      data-bs-toggle="tooltip"></div>`;
  }).join("");
}

export function renderAxis(axisEl, maxPoints) {
  axisEl.innerHTML = "";
  if (maxPoints <= 0) return;

  const rawStep = maxPoints / 6;
  const magnitude = Math.pow(10, Math.floor(Math.log10(rawStep)));
  const step = Math.ceil(rawStep / magnitude) * magnitude;
  const ticks = [];
  for (let v = 0; v <= maxPoints; v += step) {
    ticks.push(v);
  }
  if (ticks[ticks.length - 1] < maxPoints) ticks.push(maxPoints);

  ticks.forEach((v) => {
    const pct = (v / maxPoints) * 100;
    const span = document.createElement("span");
    span.className = "text-muted";
    span.textContent = v;
    span.style.cssText = `
      position: absolute;
      font-size: 0.7rem;
      white-space: nowrap;
      ${
        pct === 0
          ? "left: 0;"
          : pct >= 100
            ? "right: 0;"
            : `left: ${pct}%; transform: translateX(-50%);`
      }
    `;
    axisEl.appendChild(span);
  });
}

function markerColor(grade) {
  return GRADE_MARKER_COLOR[grade] || "#6c757d";
}

export function placeMarkers(container, bands, maxPoints, onDragStart) {
  container.querySelectorAll(".manual-marker").forEach(m => m.remove());
  if (maxPoints <= 0) return;

  PASSING_GRADES.forEach((grade) => {
    const gs = grade.toFixed(1);
    const band = bands.find(b => b.grade === gs);
    if (!band) return;

    const pct = Math.min(
      Math.max((band.min_points / maxPoints) * 100, 0), 100,
    );
    const color = markerColor(gs);

    const el = document.createElement("div");
    el.className = "manual-marker";
    el.dataset.grade = gs;
    el.dataset.minPoints = band.min_points;
    Object.assign(el.style, {
      position: "absolute",
      left: `${pct}%`,
      top: "0",
      bottom: "0",
      width: "20px",
      transform: "translateX(-50%)",
      cursor: "ew-resize",
      zIndex: "10",
      touchAction: "none",
      userSelect: "none",
    });

    el.innerHTML = `
      <div style="position: absolute; left: 50%; top: 0;
                  height: 155px; width: 2px;
                  background: ${color}; opacity: 0.8;
                  transform: translateX(-50%);
                  box-shadow: 1px 0 0 rgba(255,255,255,0.85),
                              -1px 0 0 rgba(255,255,255,0.85);
                  pointer-events: none;"></div>
      <span data-pts-label style="
        position: absolute; top: 2px; left: 50%;
        transform: translateX(-50%);
        font-size: 0.6rem; color: ${color}; font-weight: bold;
        white-space: nowrap; background: rgba(255,255,255,0.85);
        border-radius: 2px; padding: 0 2px;
        pointer-events: none;">${band.min_points}</span>
      <span class="badge" style="
        position: absolute; bottom: 0; left: 50%;
        transform: translateX(-50%);
        font-size: 0.6rem; background: ${color};
        white-space: nowrap;
        pointer-events: none;">${gs}</span>
    `;

    el.addEventListener("pointerdown", onDragStart);
    container.appendChild(el);
  });
}

export function moveMarkerTo(
  marker, clientX, dragRect, maxPoints, step, container,
) {
  const rawPct = ((clientX - dragRect.left) / dragRect.width) * 100;
  const snap = v => Math.round(v / step) * step;
  let points = snap(
    (Math.min(Math.max(rawPct, 0), 100) / 100) * maxPoints,
  );

  const grade = parseFloat(marker.dataset.grade);
  const idx = PASSING_GRADES.indexOf(grade);
  const markers = container.querySelectorAll(".manual-marker");
  const byGrade = {};
  markers.forEach((m) => {
    byGrade[m.dataset.grade] = m;
  });

  if (idx > 0) {
    const prev = byGrade[PASSING_GRADES[idx - 1].toFixed(1)];
    if (prev) {
      points = Math.max(
        points, parseFloat(prev.dataset.minPoints) + step,
      );
    }
  }

  if (idx < PASSING_GRADES.length - 1) {
    const next = byGrade[PASSING_GRADES[idx + 1].toFixed(1)];
    if (next) {
      points = Math.min(
        points, parseFloat(next.dataset.minPoints) - step,
      );
    }
  }

  points = Math.max(points, 0);
  points = Math.min(points, maxPoints);
  points = snap(points);

  const pct = (points / maxPoints) * 100;
  marker.style.left = `${pct}%`;
  marker.dataset.minPoints = points;
  const ptsLabel = marker.querySelector("[data-pts-label]");
  if (ptsLabel) ptsLabel.textContent = points;
}

export function readMarkersAsBands(container) {
  const markers = container.querySelectorAll(".manual-marker");
  const bands = [];

  markers.forEach((m) => {
    bands.push({
      min_points: parseFloat(m.dataset.minPoints),
      grade: m.dataset.grade,
    });
  });

  const band40 = bands.find(b => b.grade === "4.0");
  if (band40 && band40.min_points > 0) {
    bands.push({ min_points: 0, grade: "5.0" });
  }

  return bands;
}
