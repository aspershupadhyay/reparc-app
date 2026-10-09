"""Reads the MakeHuman base mesh, its shape targets, and its skeleton.

MakeHuman's assets (base mesh, targets, skeleton, and weights) are CC0
since September 2020. See app/assets/licenses/makehuman-CC0.txt.
"""

import json
import os

import numpy as np


class Base:
    """The hm08 base mesh: vertices, body faces (quads), and joints."""

    def __init__(self, data):
        self.data = data
        verts, faces, groups = [], [], []
        group = None
        with open(os.path.join(data, "3dobjs", "base.obj")) as f:
            for line in f:
                if line.startswith("v "):
                    verts.append([float(x) for x in line.split()[1:4]])
                elif line.startswith("g "):
                    group = line.split()[1]
                elif line.startswith("f "):
                    idx = [int(p.split("/")[0]) - 1 for p in line.split()[1:]]
                    faces.append(idx)
                    groups.append(group)
        self.verts = np.array(verts, dtype=np.float64)
        self.faces = faces
        self.groups = groups
        skel = json.load(open(os.path.join(data, "rigs", "default.mhskel")))
        self.bones = skel["bones"]
        self.joint_verts = skel["joints"]
        self.weights = json.load(open(os.path.join(data, "rigs", "default_weights.mhw")))["weights"]

    def body_quads(self):
        """Faces of the skin only: no eyes, teeth, helpers, or joint cubes."""
        return [f for f, g in zip(self.faces, self.groups) if g == "body"]

    def target(self, name, weight):
        """Vertex offsets of one target file, times [weight]."""
        out = np.zeros_like(self.verts)
        if weight == 0:
            return out
        with open(os.path.join(self.data, "targets", name + ".target")) as f:
            for line in f:
                if not line.strip() or line.startswith("#"):
                    continue
                i, x, y, z = line.split()
                out[int(i)] = (float(x), float(y), float(z))
        return out * weight

    def joint(self, verts, name):
        """A joint is the middle of its marker vertices."""
        return verts[self.joint_verts[name]].mean(axis=0)


def _three(v):
    """Weights of the min, average, and max targets for a 0..1 slider."""
    if v < 0.5:
        return {"min": 1 - 2 * v, "average": 2 * v, "max": 0.0}
    return {"min": 0.0, "average": 1 - (v - 0.5) * 2, "max": (v - 0.5) * 2}


def shaped(base, muscle, weight, proportions):
    """The base mesh as a young adult man with the given sliders (0..1),
    the same way MakeHuman's macro sliders mix their targets."""
    v = base.verts.copy()
    mus, wei = _three(muscle), _three(weight)
    for mk, mw in mus.items():
        for wk, ww in wei.items():
            w = mw * ww
            if w == 0:
                continue
            v += base.target(f"macrodetails/universal-male-young-{mk}muscle-{wk}weight", w)
            v += base.target(
                f"macrodetails/proportions/male-young-{mk}muscle-{wk}weight-idealproportions", w * proportions
            )
    # Ethnic mix: MakeHuman's default is an even third each.
    for race in ("african", "asian", "caucasian"):
        v += base.target(f"macrodetails/{race}-male-young", 1 / 3)
    return v
