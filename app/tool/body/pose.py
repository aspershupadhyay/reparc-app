"""Poses the MakeHuman body: arms down from its A-pose, by skinning.

Each bone moves by a rotation about a joint; each vertex follows its
bones by their skin weights (dual-quaternion blend, so the shoulder keeps
its volume instead of collapsing like a plain linear blend).
"""

import numpy as np


def rotation(axis, deg):
    axis = np.asarray(axis, dtype=np.float64)
    axis = axis / np.linalg.norm(axis)
    a = np.radians(deg)
    x, y, z = axis
    c, s, t = np.cos(a), np.sin(a), 1 - np.cos(a)
    return np.array(
        [
            [t * x * x + c, t * x * y - s * z, t * x * z + s * y],
            [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
            [t * x * z - s * y, t * y * z + s * x, t * z * z + c],
        ]
    )


def between(a, b):
    """The smallest rotation that turns direction [a] onto [b]."""
    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    axis = np.cross(a, b)
    s = np.linalg.norm(axis)
    if s < 1e-9:
        return np.eye(3)
    return rotation(axis, np.degrees(np.arctan2(s, np.dot(a, b))))


def _quat(m):
    """Unit quaternion (w, x, y, z) of a rotation matrix."""
    tr = np.trace(m)
    if tr > 0:
        s = np.sqrt(tr + 1.0) * 2
        return np.array([0.25 * s, (m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s])
    i = int(np.argmax(np.diag(m)))
    j, k = (i + 1) % 3, (i + 2) % 3
    s = np.sqrt(1.0 + m[i, i] - m[j, j] - m[k, k]) * 2
    q = np.zeros(4)
    q[0] = (m[k, j] - m[j, k]) / s
    q[1 + i] = 0.25 * s
    q[1 + j] = (m[j, i] + m[i, j]) / s
    q[1 + k] = (m[k, i] + m[i, k]) / s
    return q


def _qmul(a, b):
    w1, x1, y1, z1 = a
    w2, x2, y2, z2 = b
    return np.array(
        [
            w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
            w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
            w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
            w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
        ]
    )


class Rig:
    """Bone transforms as (R, t): x -> R x + t."""

    def __init__(self, base):
        self.base = base
        self.bones = base.bones
        self.xf = {name: (np.eye(3), np.zeros(3)) for name in self.bones}

    def descendants(self, name):
        out = [name]
        for b, info in self.bones.items():
            if info["parent"] == name:
                out += self.descendants(b)
        return out

    def turn(self, root, r, pivot):
        """Turns bone [root] and everything below it by [r] about [pivot]
        (a point in the current, already posed space)."""
        for b in self.descendants(root):
            R, t = self.xf[b]
            # x -> r (R x + t - pivot) + pivot
            self.xf[b] = (r @ R, r @ (t - pivot) + pivot)

    def skin(self, rest):
        """Posed copy of [rest] by the skin weights (dual quaternions)."""
        n = len(rest)
        wsum = np.zeros(n)
        q0 = np.zeros((n, 4))
        qe = np.zeros((n, 4))
        ref = {}
        for b, pairs in self.base.weights.items():
            R, t = self.xf.get(b, (np.eye(3), np.zeros(3)))
            q = _quat(R)
            # Dual part: 0.5 * (0, t) * q
            d = 0.5 * _qmul(np.array([0, *t]), q)
            ref[b] = (q, d)
            idx = np.array([p[0] for p in pairs], dtype=np.int64)
            w = np.array([p[1] for p in pairs])
            # Keep quaternions in one hemisphere so blends do not flip.
            sign = np.where(q0[idx] @ q < 0, -1.0, 1.0)
            sign = np.where(np.linalg.norm(q0[idx], axis=1) == 0, 1.0, sign)
            sw = (w * sign)[:, None]
            np.add.at(q0, idx, sw * q)
            np.add.at(qe, idx, sw * d)
            np.add.at(wsum, idx, w)
        out = rest.copy()
        moved = wsum > 0
        norm = np.linalg.norm(q0[moved], axis=1)[:, None]
        a = q0[moved] / norm
        e = qe[moved] / norm
        w, x, y, z = a.T
        Rm = np.stack(
            [
                np.stack([1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y)], -1),
                np.stack([2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x)], -1),
                np.stack([2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y)], -1),
            ],
            1,
        )
        # Translation from the dual part: t = 2 * e * conj(a)
        conj = a * np.array([1, -1, -1, -1])
        tq = np.array([_qmul(ei, ci) for ei, ci in zip(e, conj)]) * 2
        out[moved] = np.einsum("nij,nj->ni", Rm, rest[moved]) + tq[:, 1:]
        return out


def arms_down(base, verts, upper_deg, fore_deg, fore_forward_deg):
    """Lowers both arms so the upper arm hangs [upper_deg] out from
    straight down, and the forearm [fore_deg] out and [fore_forward_deg]
    forward. Returns posed vertices."""
    rig = Rig(base)
    for side, sx in (("L", 1.0), ("R", -1.0)):
        sh = base.joint(verts, f"upperarm01.{side}____head")
        el = base.joint(verts, f"lowerarm01.{side}____head")
        wr = base.joint(verts, f"wrist.{side}____head")
        a = np.radians(upper_deg)
        want = np.array([sx * np.sin(a), -np.cos(a), 0.0])
        r1 = between(el - sh, want)
        rig.turn(f"upperarm01.{side}", r1, sh)
        el2 = r1 @ (el - sh) + sh
        wr2 = r1 @ (wr - sh) + sh
        b = np.radians(fore_deg)
        f = np.radians(fore_forward_deg)
        want2 = np.array([sx * np.sin(b), -np.cos(b) * np.cos(f), np.sin(f)])
        r2 = between(wr2 - el2, want2)
        rig.turn(f"lowerarm01.{side}", r2, el2)
    return rig.skin(verts)
