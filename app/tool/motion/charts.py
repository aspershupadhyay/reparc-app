"""Surface charts for the muscle atlas: the trunk and each limb unwrapped
into flat coordinates in metres, so muscles can be drawn as 2D shapes.

Trunk: u = arc length around a vertical axis (0 at the front midline,
+ toward the figure's own side, so both sides share one drawing), v = height.
Limbs: u = arc length around the bone (0 at the front; + toward the outer
side), v = distance from the proximal joint along the bone.
"""
import numpy as np

ZC = 0.03          # trunk axis depth (m)
R_TRUNK = 0.14     # metres of arc per radian, trunk


def limb_frames(J):
    """Axis and reference directions for each limb segment and side."""
    F = {}
    for s, sx in (('L', 1.0), ('R', -1.0)):
        sh, el, wr = J[f'upperarm01.{s}____head'], J[f'lowerarm01.{s}____head'], J[f'wrist.{s}____head']
        hp, kn, an = J[f'upperleg01.{s}____head'], J[f'lowerleg01.{s}____head'], J[f'foot.{s}____head']
        fwd, lat = np.array([0, 0, 1.0]), np.array([sx, 0, 0.0])
        F[('upperarm', s)] = (sh, el, fwd, lat, 0.045)
        # Forearm in the bind pose: palm faces the thigh, thumb forward. Front (0) = palm side.
        F[('forearm', s)] = (el, wr, np.array([-sx, 0, 0.0]), np.array([0, 0, 1.0]), 0.04)
        F[('thigh', s)] = (hp, kn, fwd, lat, 0.075)
        F[('shin', s)] = (kn, an, fwd, lat, 0.055)
    return F


def limb_uv(p, frame):
    a, b, fwd, lat, r = frame
    ax = b - a
    L = np.linalg.norm(ax)
    ax = ax / L
    d = p - a
    t = d @ ax
    rad = d - np.outer(t, ax)
    f = fwd - ax * (fwd @ ax); f /= np.linalg.norm(f)
    l = lat - ax * (lat @ ax) - f * (lat @ f); l /= np.linalg.norm(l)
    th = np.arctan2(rad @ l, rad @ f)
    return np.stack([th * r, t], 1), L


def trunk_uv(p):
    side = np.where(p[:, 0] >= 0, 1.0, -1.0)
    th = np.arctan2(np.abs(p[:, 0]), p[:, 2] - ZC)
    return np.stack([th * R_TRUNK, p[:, 1]], 1), side


# Texture layout: one side only (the other mirrors). Each chart is a
# rectangle (x0, y0) in a square of SIDE metres; limb rectangles run a
# quarter turn past the back seam so triangles that cross it stay whole.
SIDE = 1.45
_P = {'upperarm': 2 * np.pi * 0.045, 'forearm': 2 * np.pi * 0.04, 'thigh': 2 * np.pi * 0.075, 'shin': 2 * np.pi * 0.055}
RECTS = {
    'thigh': (0.0, 0.0, (-_P['thigh'] / 2, 0.75 * _P['thigh']), (-0.12, 0.46)),
    'shin': (0.0, 0.6, (-_P['shin'] / 2, 0.75 * _P['shin']), (-0.05, 0.48)),
    'trunk': (0.61, 0.0, (0.0, 0.445), (0.74, 1.66)),
    'forearm': (0.61, 0.94, (-_P['forearm'] / 2, 0.75 * _P['forearm']), (-0.08, 0.31)),
    'upperarm': (1.075, 0.0, (-_P['upperarm'] / 2, 0.75 * _P['upperarm']), (-0.11, 0.30)),
}
BLANK = (1.42, 1.42)   # a spot with no muscle, for the head, hands, and feet


def period(chart):
    return _P.get(chart)


def to_tex(chart, uv):
    """Chart coordinates (metres) to texture coordinates (0..1, y down)."""
    x0, y0, (u0, _), (v0, _) = RECTS[chart]
    return np.stack([(x0 + uv[:, 0] - u0) / SIDE, (y0 + uv[:, 1] - v0) / SIDE], 1)


def chart_basis(chart, pos, J):
    """Chart coordinates and the 3D directions of +u and +v at each point."""
    n = len(pos)
    side = np.where(pos[:, 0] >= 0, 1.0, -1.0)
    if chart == 'trunk':
        uv, _ = trunk_uv(pos)
        rho = np.hypot(pos[:, 0], pos[:, 2] - ZC) + 1e-9
        eu = np.stack([(pos[:, 2] - ZC) / rho * side, np.zeros(n), -np.abs(pos[:, 0]) / rho], 1)
        ev = np.tile([0, 1.0, 0], (n, 1))
        return uv, eu, ev
    frames = limb_frames(J)
    uv = np.zeros((n, 2)); eu = np.zeros((n, 3)); ev = np.zeros((n, 3))
    for s, sx in (('L', 1.0), ('R', -1.0)):
        m = side == sx
        if not m.any():
            continue
        a, b, fwd, lat, r = frames[(chart, s)]
        uv[m], _ = limb_uv(pos[m], frames[(chart, s)])
        ax = (b - a) / np.linalg.norm(b - a)
        f = fwd - ax * (fwd @ ax); f /= np.linalg.norm(f)
        l = lat - ax * (lat @ ax) - f * (lat @ f); l /= np.linalg.norm(l)
        th = uv[m, 0] / r
        eu[m] = -np.sin(th)[:, None] * f + np.cos(th)[:, None] * l
        ev[m] = ax
    return uv, eu, ev
