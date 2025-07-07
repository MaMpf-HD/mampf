// BSD-3-Clause licensed by Craig S. Kaplan
// adapted from: https://github.com/isohedral/hatviz

// This file is mostly code that will get replaced anyways since
// the monotiles will probably not stay on the front screen forever.
// Having to properly use modules here and import/export the respective variables
// would be overkill. This is mostly external code from the monotile project.
// It works as intended and is pretty much unrelated to the rest of our code base.
// For these reasons, we disable some ESLint rules for this file.

export const r3 = 1.7320508075688772;
export const hr3 = 0.8660254037844386;
export const ident = [1, 0, 0, 0, 1, 0];

export function pt(x, y) {
  return { x: x, y: y };
}

export function hexPt(x, y) {
  return pt(x + 0.5 * y, hr3 * y);
}

// Affine matrix inverse
export function inv(T) {
  const det = T[0] * T[4] - T[1] * T[3];
  return [T[4] / det, -T[1] / det, (T[1] * T[5] - T[2] * T[4]) / det,
    -T[3] / det, T[0] / det, (T[2] * T[3] - T[0] * T[5]) / det];
}

// Affine matrix multiply
export function mul(A, B) {
  return [A[0] * B[0] + A[1] * B[3],
    A[0] * B[1] + A[1] * B[4],
    A[0] * B[2] + A[1] * B[5] + A[2],

    A[3] * B[0] + A[4] * B[3],
    A[3] * B[1] + A[4] * B[4],
    A[3] * B[2] + A[4] * B[5] + A[5]];
}

export function padd(p, q) {
  return { x: p.x + q.x, y: p.y + q.y };
}

export function psub(p, q) {
  return { x: p.x - q.x, y: p.y - q.y };
}

// Rotation matrix
export function trot(ang) {
  const c = Math.cos(ang);
  const s = Math.sin(ang);
  return [c, -s, 0, s, c, 0];
}

// Translation matrix
export function ttrans(tx, ty) {
  return [1, 0, tx, 0, 1, ty];
}

export function rotAbout(p, ang) {
  return mul(ttrans(p.x, p.y),
    mul(trot(ang), ttrans(-p.x, -p.y)));
}

// Matrix * point
export function transPt(M, P) {
  return pt(M[0] * P.x + M[1] * P.y + M[2], M[3] * P.x + M[4] * P.y + M[5]);
}

// Match unit interval to line segment p->q
export function matchSeg(p, q) {
  return [q.x - p.x, p.y - q.y, p.x, q.y - p.y, q.x - p.x, p.y];
}

// Match line segment p1->q1 to line segment p2->q2
export function matchTwo(p1, q1, p2, q2) {
  return mul(matchSeg(p2, q2), inv(matchSeg(p1, q1)));
}

// Intersect two lines defined by segments p1->q1 and p2->q2
export function intersect(p1, q1, p2, q2) {
  const d = (q2.y - p2.y) * (q1.x - p1.x) - (q2.x - p2.x) * (q1.y - p1.y);
  const uA = ((q2.x - p2.x) * (p1.y - p2.y) - (q2.y - p2.y) * (p1.x - p2.x)) / d;
  return pt(p1.x + uA * (q1.x - p1.x), p1.y + uA * (q1.y - p1.y));
}

export const hat_outline = [
  hexPt(0, 0), hexPt(-1, -1), hexPt(0, -2), hexPt(2, -2),
  hexPt(2, -1), hexPt(4, -2), hexPt(5, -1), hexPt(4, 0),
  hexPt(3, 0), hexPt(2, 2), hexPt(0, 3), hexPt(0, 2),
  hexPt(-1, 2),
];
