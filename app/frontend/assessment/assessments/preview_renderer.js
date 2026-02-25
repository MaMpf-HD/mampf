import { GRADE_BADGE_CLASS, countPerBand } from "./grade_bands";

export function renderPreview(bands, tbody, { studentPoints, passLabel, failLabel }) {
  const table = tbody.closest("table");
  tbody.innerHTML = "";
  const existingTfoot = table.querySelector("tfoot");
  if (existingTfoot) existingTfoot.remove();

  const points = studentPoints.map(p => parseFloat(p));
  const total = points.length;

  const sorted = [...bands].sort(
    (a, b) => parseFloat(a.grade) - parseFloat(b.grade),
  );

  const counts = countPerBand(points, bands);
  const maxCount = total > 0
    ? Math.max(...sorted.map(b => counts[b.grade] || 0))
    : 0;

  sorted.forEach((band) => {
    const tr = document.createElement("tr");
    if (band.grade === "5.0") tr.classList.add("table-danger");

    const badgeClass = GRADE_BADGE_CLASS[band.grade] || "bg-secondary";
    const count = counts[band.grade] || 0;
    const pct = total > 0 ? ((count / total) * 100).toFixed(1) : "0.0";
    const barWidth = maxCount > 0
      ? Math.round((count / maxCount) * 100)
      : 0;
    const barColor = parseFloat(band.grade) <= 4.0
      ? "#198754"
      : "#dc3545";

    tr.innerHTML = `
      <td><span class="badge ${badgeClass}">${band.grade}</span></td>
      <td>\u2265\u00a0${band.min_points} pts</td>
      <td>
        <div class="d-flex align-items-center gap-2">
          <div style="flex: 1; height: 14px; background: #e9ecef;
                      border-radius: 3px; overflow: hidden;">
            <div style="width: ${barWidth}%; height: 100%;
                        background: ${barColor};"></div>
          </div>
          <span class="text-muted small" style="min-width: 20px;">
            ${count}
          </span>
        </div>
      </td>
      <td class="text-end">${pct}%</td>
    `;

    tbody.appendChild(tr);
  });

  if (total > 0) {
    const passCount = sorted
      .filter(b => parseFloat(b.grade) <= 4.0)
      .reduce((sum, b) => sum + (counts[b.grade] || 0), 0);
    const failCount = total - passCount;
    const passRate = ((passCount / total) * 100).toFixed(1);
    const failRate = ((failCount / total) * 100).toFixed(1);
    const tfoot = document.createElement("tfoot");
    tfoot.classList.add("table-light");
    tfoot.innerHTML = `
      <tr>
        <th colspan="2">${passLabel}:</th>
        <th colspan="2" class="text-end">
          ${passRate}% (${passCount}/${total})
        </th>
      </tr>
      <tr>
        <th colspan="2">${failLabel}:</th>
        <th colspan="2" class="text-end">
          ${failRate}% (${failCount}/${total})
        </th>
      </tr>
    `;
    table.appendChild(tfoot);
  }
}
