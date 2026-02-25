export const PASSING_GRADES = [
  4.0, 3.7, 3.3, 3.0, 2.7, 2.3, 2.0, 1.7, 1.3, 1.0,
];

export const GRADE_BADGE_CLASS = {
  "1.0": "bg-success",
  "1.3": "bg-success",
  "1.7": "bg-success",
  "2.0": "bg-primary",
  "2.3": "bg-primary",
  "2.7": "bg-primary",
  "3.0": "bg-warning text-dark",
  "3.3": "bg-warning text-dark",
  "3.7": "bg-warning text-dark",
  "4.0": "bg-warning text-dark",
  "5.0": "bg-danger",
};

export const GRADE_MARKER_COLOR = {
  "1.0": "#198754",
  "1.3": "#198754",
  "1.7": "#198754",
  "2.0": "#223e62",
  "2.3": "#223e62",
  "2.7": "#223e62",
  "3.0": "#ffc107",
  "3.3": "#ffc107",
  "3.7": "#ffc107",
  "4.0": "#dc3545",
};

export function computeBands(excellence, passing, pointsStep = 1) {
  const rawStep = (excellence - passing) / (PASSING_GRADES.length - 1);

  const bands = PASSING_GRADES.map((grade, i) => {
    const raw = passing + i * rawStep;
    const minPts = Math.round(raw / pointsStep) * pointsStep;
    return { min_points: minPts, grade: grade.toFixed(1) };
  });

  if (passing > 0) {
    bands.unshift({ min_points: 0, grade: "5.0" });
  }

  return { bands };
}

export function countPerBand(points, allBands) {
  const descending = [...allBands].sort(
    (a, b) => b.min_points - a.min_points,
  );
  const result = {};
  allBands.forEach((b) => {
    result[b.grade] = 0;
  });

  points.forEach((p) => {
    const band = descending.find(b => p >= b.min_points);
    if (band) result[band.grade]++;
  });

  return result;
}
