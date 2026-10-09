"""Builds the body map mesh, app/assets/body/body.bin, from MakeHuman's
CC0 base mesh.

    git clone --depth 1 https://github.com/makehumancommunity/makehuman.git
    python3 -I tool/body/build.py <makehuman>/makehuman/data

Steps: shape an athletic young man with MakeHuman's own sliders, lower
the arms, scale to metres, split quads into triangles, mark each muscle
region, bake soft shadows (ambient occlusion), and write one binary file
that body_model.dart reads. See README.md beside this file.
"""

import os
import struct
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import mh  # noqa: E402
import muscles  # noqa: E402
import pose  # noqa: E402
import refine  # noqa: E402

# Sliders, 0..1 as in MakeHuman. 0.5 is average.
MUSCLE = float(os.environ.get("MH_MUSCLE", 1.0))
WEIGHT = float(os.environ.get("MH_WEIGHT", 0.5))
PROPORTIONS = 1.0

# Pose, in degrees.
UPPER_ARM_OUT = 13
FOREARM_OUT = 15
FOREARM_FORWARD = 6

HEIGHT_M = 1.78

# Segments that get four times the detail: where the muscles are.
REFINE = {"trunk", "upperarm", "forearm", "thigh", "shin", "neck"}

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(APP, "assets", "body", "body.bin")


def triangulate(quads, pos):
    """Splits each quad along its shorter diagonal, so creases follow the
    surface instead of cutting across it."""
    q = np.array(quads)
    d02 = np.linalg.norm(pos[q[:, 0]] - pos[q[:, 2]], axis=1)
    d13 = np.linalg.norm(pos[q[:, 1]] - pos[q[:, 3]], axis=1)
    a = np.where(d02 <= d13)[0]
    b = np.where(d02 > d13)[0]
    t = np.concatenate(
        [
            q[a][:, [0, 1, 2]],
            q[a][:, [0, 2, 3]],
            q[b][:, [0, 1, 3]],
            q[b][:, [1, 2, 3]],
        ]
    )
    return t


def normals(pos, tri):
    fn = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    n = np.zeros_like(pos)
    for k in range(3):
        np.add.at(n, tri[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def body(data):
    """The posed body in metres: positions, triangles, and the joints."""
    base = mh.Base(data)
    v = mh.shaped(base, MUSCLE, WEIGHT, PROPORTIONS)
    v = pose.arms_down(base, v, UPPER_ARM_OUT, FOREARM_OUT, FOREARM_FORWARD)
    # The skeleton has no skin weights on its own markers, so joints are
    # read again from the posed vertices.
    quads = base.body_quads()
    used = np.array(sorted({i for f in quads for i in f}))
    remap = -np.ones(len(v), dtype=np.int64)
    remap[used] = np.arange(len(used))
    joints = {name: base.joint(v, name) for name in base.joint_verts}

    # Metres, feet on y = 0, centred left to right; z = 0 at the hips.
    lo = v[used, 1].min()
    hi = v[used, 1].max()
    s = HEIGHT_M / (hi - lo)
    hip = (joints["upperleg01.L____head"] + joints["upperleg01.R____head"]) / 2
    origin = np.array([0.0, lo, hip[2]])
    pos = (v[used] - origin) * s
    joints = {k: (j - origin) * s for k, j in joints.items()}
    quads = [[int(remap[i]) for i in q] for q in quads]
    weights = {b: [(remap[i], w) for i, w in pairs if remap[i] >= 0] for b, pairs in base.weights.items()}
    seg = muscles.segments(len(pos), weights)
    return pos, quads, seg, joints


def write(path, pos, nrm, label, weight, groove, ao, tri, anchors):
    """Little-endian. Header: magic 'RBDY', version, vertex count,
    triangle count, anchor count. Then per vertex: position (3 f32),
    normal (3 i8, x127), muscle (i8, -1 skin), muscle weight, groove, and
    shadow (u8 each, x255). Then triangles (3 u16 each) and their muscle
    (i8). Then anchors: muscle (i8), position (3 f32), and normal (3 f32)."""
    nv, nt = len(pos), len(tri)
    assert nv < 65536
    tri_label = muscles.triangle_labels(label, tri)
    with open(path, "wb") as f:
        f.write(b"RBDY")
        f.write(struct.pack("<IIII", 1, nv, nt, len(anchors)))
        f.write(pos.astype("<f4").tobytes())
        f.write(np.round(nrm * 127).astype(np.int8).tobytes())
        f.write(label.astype(np.int8).tobytes())
        for a in (weight, groove, ao):
            f.write(np.round(np.clip(a, 0, 1) * 255).astype(np.uint8).tobytes())
        f.write(tri.astype("<u2").tobytes())
        f.write(tri_label.astype(np.int8).tobytes())
        for m, p, n in anchors:
            f.write(struct.pack("<b6f", m, *p, *n))


def main():
    data = sys.argv[1]
    pos, quads, seg, joints = body(data)
    pos, seg, tri = refine.refine(pos, normals(pos, triangulate(quads, pos)), quads, seg, REFINE)
    nrm = normals(pos, tri)
    label, weight, groove = muscles.label(pos, nrm, tri, joints, seg)
    ao = muscles.occlusion(pos, nrm, tri)
    anchors = muscles.anchors(pos, nrm, label, (weight > 0.99) & (groove < 0.05))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    write(OUT, pos, nrm, label, weight, groove, ao, tri, anchors)
    if len(sys.argv) > 2:
        np.savez(
            sys.argv[2],
            pos=pos,
            nrm=nrm,
            tri=tri,
            col=muscles.preview_colors(label, weight, groove, ao),
            label=label,
        )
    print(f"{len(pos)} vertices, {len(tri)} triangles, {os.path.getsize(OUT) / 1024:.0f} KiB -> {OUT}")


if __name__ == "__main__":
    main()
