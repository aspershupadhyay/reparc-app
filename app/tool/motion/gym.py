"""Builds the RepArc gym model from the rigged base body (export.py with
BASE_CACHE): subdivides the mesh, lays the muscle atlas on it, carves each
muscle as a rounded belly with grooves between them, and writes one JSON
file the Motion Lab page reads.

    BASE_CACHE=/tmp/base.npz python3 -I tool/motion/export.py <mh data> /tmp/body.json
    python3 -I tool/motion/gym.py /tmp/base.npz /tmp/gym.json

Per vertex it stores the muscle, how far inside the muscle the point is
(the page uses it to keep volume when a muscle shortens), the fibre
direction, and a cavity term for shading.
"""
import base64
import json
import os
import sys

import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
sys.path.insert(0, os.path.join(os.path.dirname(here), 'body'))
import assign  # noqa: E402
import atlas  # noqa: E402
import charts  # noqa: E402
import muscles  # noqa: E402

GROOVE = 0.004   # depth of the groove between muscles (m)
SKIN_SEGS = ('trunk', 'neck', 'upperarm', 'forearm', 'thigh', 'shin')


def normals(pos, tri):
    fn = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    n = np.zeros_like(pos)
    for k in range(3):
        np.add.at(n, tri[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def subdivide(pos, nrm, tri, attrs):
    """Each triangle into four. New points sit on the curved surface through
    the corners (Phong); attributes in [attrs] are averaged."""
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e.sort(1)
    uniq, inv = np.unique(e, axis=0, return_inverse=True)
    a, b = uniq[:, 0], uniq[:, 1]
    m = (pos[a] + pos[b]) / 2
    proj = lambda q, p, n: q - ((q - p) * n).sum(1, keepdims=True) * n
    m = 0.25 * m + 0.75 * (proj(m, pos[a], nrm[a]) + proj(m, pos[b], nrm[b])) / 2
    n0 = len(pos)
    newpos = np.concatenate([pos, m])
    out = {k: np.concatenate([v, (v[a] + v[b]) / 2]) for k, v in attrs.items()}
    nt = len(tri)
    mab, mbc, mca = (inv[:nt] + n0, inv[nt:2 * nt] + n0, inv[2 * nt:] + n0)
    t0, t1, t2 = tri[:, 0], tri[:, 1], tri[:, 2]
    newtri = np.concatenate([np.stack([t0, mab, mca], 1), np.stack([mab, t1, mbc], 1), np.stack([mca, mbc, t2], 1), np.stack([mab, mbc, mca], 1)])
    return newpos, newtri, out


def neighbours(n, tri):
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    e = np.unique(e, axis=0)
    deg = np.bincount(e[:, 0], minlength=n)
    return e, deg


def smooth(val, e, deg, it=2):
    for _ in range(it):
        s = np.zeros_like(val)
        np.add.at(s, e[:, 0], val[e[:, 1]])
        val = 0.5 * val + 0.5 * s / np.maximum(deg, 1)[:, None] if val.ndim > 1 else 0.5 * val + 0.5 * s / np.maximum(deg, 1)
    return val


def main(base_path, out):
    d = np.load(base_path)
    J = {k: np.array(v) for k, v in json.loads(str(d['joints'])).items()}
    bones = json.loads(str(d['bones']))
    pos, tri, W, seg = d['pos'], d['tri'], d['W'], d['seg']
    segs = sorted(set(seg))
    segid = np.array([segs.index(s) for s in seg], float)
    nrm = normals(pos, tri)
    ao0 = muscles.occlusion(pos, nrm, tri, dirs=96)
    pos, tri, A = subdivide(pos, nrm, tri, {'W': W, 'seg': segid[:, None], 'ao': ao0[:, None]})
    W, ao = A['W'], A['ao'][:, 0]
    seg = np.array([segs[int(round(i))] if abs(i - round(i)) < 1e-6 else None for i in A['seg'][:, 0]], dtype=object)
    # Midpoints between two segments: take either neighbour's segment.
    e, deg = neighbours(len(pos), tri)
    for _ in range(2):
        miss = np.array([s is None for s in seg])
        if not miss.any():
            break
        for v, w in e[miss[e[:, 0]]]:
            if seg[v] is None and seg[w] is not None:
                seg[v] = seg[w]
    nrm = normals(pos, tri)
    print('subdivided:', len(pos), 'vertices', len(tri), 'triangles')

    mid, depth, fib, side, _, near_id, mid2 = assign.assign(pos, seg, J)
    # Belly shape: rounded from the edge in to a plateau; grooves at edges.
    maxd = np.zeros(len(atlas.M))
    for i in range(len(atlas.M)):
        sel = mid == i
        if sel.any():
            maxd[i] = depth[sel].max()
    H = np.array([m['height'] for m in atlas.M]) * 1.7
    tendon = np.array([m['kind'] == 'tendon' for m in atlas.M])
    off = np.zeros(len(pos))
    amp = np.zeros(len(pos))
    edge = np.zeros(len(pos))
    ins = mid >= 0
    R = np.clip(maxd[mid[ins]] * 0.75, 0.006, 0.03)
    s = np.clip(depth[ins] / R, 0, 1)
    belly = s * (2 - s)
    soft = np.array([0.3 if atlas.faint(a, b) else 1.0 for a, b in zip(mid[ins], mid2[ins])])
    # Between heads of one muscle the belly does not drop to the seam.
    belly = np.where(soft < 1, np.maximum(belly, 0.75), belly)
    off[ins] = H[mid[ins]] * belly - GROOVE * soft * (1 - s) ** 2 * np.where(tendon[mid[ins]], 0.5, 1.0)
    amp[ins] = np.where(tendon[mid[ins]], 0, belly)
    edge[ins] = (1 - s) ** 2
    out_d = -depth  # outside distance for points not in a muscle
    near = (~ins) & np.isin(seg, SKIN_SEGS)
    off[near] = -GROOVE * np.exp(-np.clip(out_d[near], 0, None) / 0.005)
    edge[near] = np.exp(-np.clip(out_d[near], 0, None) / 0.005)
    off = smooth(off, e, deg, 1)
    # RELIEF=0 keeps the smooth body (painted model: the form comes from the painting).
    off *= float(os.environ.get('RELIEF', '1'))
    pos = pos + nrm * off[:, None]
    nrm = normals(pos, tri)
    # Cavity: concave points darken, convex ones lighten (mean curvature).
    s_ = np.zeros_like(pos); np.add.at(s_, e[:, 0], pos[e[:, 1]])
    lap = s_ / np.maximum(deg, 1)[:, None] - pos
    el = np.linalg.norm(pos[e[:, 0]] - pos[e[:, 1]], axis=1)
    elen = np.bincount(e[:, 0], el, len(pos)) / np.maximum(deg, 1)
    curv = (lap * nrm).sum(1) / np.maximum(elen ** 2, 1e-8)
    cav = smooth(np.clip(curv * 0.004, -1, 1), e, deg, 1)

    # Muscle table, both sides. Global id = 2 * atlas index + (0 left, 1 right).
    def mirror(att):
        bone, key, off_ = att
        return (bone[:-1] + 'R' if bone.endswith('L') else bone, key.replace('.L_', '.R_'), (-off_[0], off_[1], off_[2]))
    table = []
    for m in atlas.M:
        for sd in 'LR':
            at = m['attach']
            if at and sd == 'R':
                at = tuple(mirror(a) for a in at)
            table.append({'name': m['name'], 'side': sd, 'cat': m['cat'], 'kind': m['kind'], 'height': m['height'],
                          'attach': [{'bone': b, 'at': [round(float(x), 5) for x in (J[k] + np.array(o))]} for b, k, o in at] if at else None})
    # Every point near a muscle takes that muscle's id (colour); 'edge' and
    # 'amp' say whether it is in the belly or in the groove beside it.
    has = near_id >= 0
    gid = np.where(has & (ins | near), near_id * 2 + (side == 'R'), 65535).astype(np.uint16)

    # ---- Texture coordinates. Each triangle takes one chart; points on a
    # chart border or on a limb's back seam are split into copies.
    vchart = np.array(['none'] * len(pos), dtype=object)
    cover = has & (ins | near)
    vchart[cover] = [atlas.M[i]['chart'] for i in near_id[cover]]
    tchart = []
    for t in tri:
        cs = [vchart[v] for v in t if vchart[v] != 'none']
        tchart.append(max(set(cs), key=cs.count) if cs else 'none')
    tchart = np.array(tchart, dtype=object)
    cuv = {}; cbasis = {}
    for c in ('trunk', 'upperarm', 'forearm', 'thigh', 'shin'):
        uvc, eu, ev = charts.chart_basis(c, pos, J)
        cuv[c] = uvc; cbasis[c] = (eu, ev)
    key_to_new = {}; src = []; uvs = []; tans = []
    newtri = np.zeros_like(tri)
    for ti, (t, c) in enumerate(zip(tri, tchart)):
        if c == 'none':
            for k, v in enumerate(t):
                kk = (v, 'none', 0)
                if kk not in key_to_new:
                    key_to_new[kk] = len(src); src.append(v); uvs.append((charts.BLANK[0] / charts.SIDE, charts.BLANK[1] / charts.SIDE)); tans.append((1.0, 0, 0, 1.0))
                newtri[ti, k] = key_to_new[kk]
            continue
        us = cuv[c][t, 0].copy()
        P = charts.period(c)
        shift = np.zeros(3)
        if P is not None and us.max() - us.min() > P / 2:
            shift = np.where(us < 0, P, 0.0)
        for k, v in enumerate(t):
            kk = (v, c, int(shift[k] > 0))
            if kk not in key_to_new:
                key_to_new[kk] = len(src); src.append(v)
                uvp = np.array([[cuv[c][v, 0] + shift[k], cuv[c][v, 1]]])
                uvs.append(tuple(charts.to_tex(c, uvp)[0]))
                eu, ev = cbasis[c][0][v], cbasis[c][1][v]
                w = 1.0 if np.dot(np.cross(nrm[v], eu), ev) >= 0 else -1.0
                tans.append((eu[0], eu[1], eu[2], w))
            newtri[ti, k] = key_to_new[kk]
    src = np.array(src)
    print('texture seams split:', len(pos), '->', len(src), 'vertices')
    pos, nrm, W, ao, cav, amp, gid = pos[src], nrm[src], W[src], ao[src], cav[src], amp[src], gid[src]
    tri = newtri
    uvs = np.array(uvs, '<f4'); tans = np.array(tans, '<f4')

    idx = np.argsort(-W, axis=1)[:, :4]
    w4 = np.take_along_axis(W, idx, 1)
    w4 /= np.maximum(w4.sum(1, keepdims=True), 1e-9)
    wq = np.round(w4 * 255).astype(np.int32); wq[:, 0] += 255 - wq.sum(1)
    b64 = lambda a: base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
    q8 = lambda a: np.round(np.clip(a, 0, 1) * 255).astype(np.uint8)
    data = {
        'version': 4, 'nv': len(pos), 'nt': len(tri), 'bones': [{'name': n, 'parent': p, 'pos': [round(float(x), 5) for x in J[k]]} for n, p, k in bones],
        'extra': {k: [round(float(x), 5) for x in J[k]] for k in ['wrist.L____tail', 'wrist.R____tail', 'foot.L____tail', 'foot.R____tail', 'head____tail', 'spine01____head', 'neck01____head'] + [f'finger{n}-3.{s}____tail' for n in range(1, 6) for s in 'LR']},
        'muscles': table, 'cats': muscles.NAMES, 'atlas': [{'name': m['name'], 'cat': m['cat'], 'kind': m['kind']} for m in atlas.M],
        'pos': b64(pos.astype('<f4')), 'nrm': b64(np.round(nrm * 127).astype(np.int8)),
        'skinIndex': b64(idx.astype(np.uint8)), 'skinWeight': b64(wq.astype(np.uint8)),
        'index': b64(tri.astype('<u4')), 'mid': b64(gid.astype('<u2')),
        'amp': b64(q8(amp)), 'ao': b64(q8(ao)), 'cav': b64(np.round(cav * 127).astype(np.int8)),
        'uv': b64(np.round(uvs * 65535).astype('<u2')), 'tangent': b64(np.round(tans * 127).astype(np.int8)),
    }
    json.dump(data, open(out, 'w'))
    print('muscle points:', ins.mean().round(3), 'json KB', os.path.getsize(out) // 1024)





if __name__ == '__main__':
    main(*sys.argv[1:3])
