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
