"""Sculpts the painted muscles into the surface, so the body has real relief.

The painting (paint.py) gives every muscle its look, but the surface under it
is the smooth MakeHuman body: bellies and grooves are only painted, so the
outline stays plain and the scene light never falls on a real belly. This
step moves the base mesh so each painted muscle rises as a belly and sinks
into a groove at its painted edge:

1. Part per point: the muscle part map (`label.png`, snapped to the painted
   muscle edges) at each point's texture position, cleaned by a majority
   filter on the surface. Heads of one muscle (atlas.FAINT_GROUPS) count as
   one belly with a faint line between them.
2. Depth: the distance over the surface from the part's edge (Dijkstra).
3. Belly: h = H * s * (2 - s), with s = depth / (0.6 * the part's largest
   depth), so a belly is full across its middle and falls to its edge. H is
   the part's belly height from the atlas (atlas.mus `height`) times GAIN.
   A groove of GROOVE metres (less between heads of one muscle) sits on
   every edge. Tendons and bare skin stay where they are.
4. The heights are smoothed on the surface, and each point moves along its
   normal. Copies a UV seam makes move together.

Only `pos` and `nrm` change in model.json; the page and glb.py subdivide the
sculpted base mesh as before, and the textures are unchanged.

    python3 -I tool/motion/sculpt.py /tmp/paint-out    # rewrites /tmp/paint-out/model.json

Run it once, after paint.py build and before build.py and glb.py. It keeps
the unsculpted model as model-smooth.json and always starts from that, so a
second run does not sculpt twice.
"""
import base64
import json
import os
import shutil
import sys

import cv2
import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import atlas  # noqa: E402
import paint  # noqa: E402

GAIN = 1.8       # times the atlas belly height
GROOVE = 0.0025  # metres, at the edge between two muscles
FAINT = 0.3      # groove between heads of one muscle, times GROOVE
GROOVE_W = 0.009 # metres, groove half-width
FULL = 0.6       # a belly is full from this part of the part's largest depth
SMOOTH = 3       # surface smoothing steps for the heights


def main(outdir):
    src = os.path.join(outdir, 'model-smooth.json')
    dst = os.path.join(outdir, 'model.json')
    if not os.path.exists(src):
        shutil.copy(dst, src)
    data = json.load(open(src))
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
    pos = dec('pos', '<f4').reshape(nv, 3).astype(np.float64)
    tri = dec('index', '<u2').reshape(-1, 3).astype(np.int64)
    uv = dec('uv', '<u2').reshape(nv, 2) / 65535.0
    orig = dec('orig', '<u2').astype(np.int64)
    # One node per surface point (the copies a UV seam makes share one).
    key = np.unique(orig, return_inverse=True)[1].reshape(-1)
    nn = key.max() + 1
    rep = np.zeros(nn, np.int64); rep[key] = np.arange(nv)
    P = pos[rep]
    T = key[tri]
    e = np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]])
    e = np.unique(np.sort(e, 1), axis=0)
    a, b = e[:, 0], e[:, 1]
    elen = np.linalg.norm(P[a] - P[b], axis=1)

    # 1. Part per point, from the painted part map.
    L = cv2.imread(os.path.join(outdir, 'label.png'), cv2.IMREAD_UNCHANGED)
    tex = L.shape[0]
    ix = np.clip((uv[:, 0] * tex).astype(int), 0, tex - 1)
    iy = np.clip((uv[:, 1] * tex).astype(int), 0, tex - 1)
    lab = L[iy, ix].astype(np.int64)[rep]
    names = [m['name'] for m in data['atlas']]
    nl = len(names) + 1  # last = none
    lab = np.where(lab < len(names), lab, nl - 1)
    for _ in range(2):  # majority over each point and its neighbours
        votes = np.zeros((nn, nl))
        np.add.at(votes, (np.arange(nn), lab), 1.5)
        np.add.at(votes, (a, lab[b]), 1)
        np.add.at(votes, (b, lab[a]), 1)
        lab = votes.argmax(1)
    side = (P[:, 0] < 0).astype(np.int64)
    part = lab * 2 + side
    group = {n: n.split(',')[0] if n.split(',')[0] in atlas.FAINT_GROUPS else n for n in names}
    gid = {g: i for i, g in enumerate(sorted(set(group.values())))}
    grp = np.array([gid[group[n]] for n in names] + [len(gid)])[lab] * 2 + side
    height = {(m['name'], m['side']): m['height'] for m in data['muscles']}
    kind = [m['kind'] for m in data['atlas']]
    H = np.array([height.get((names[l], 'LR'[s]), 0.0) if l < len(names) and kind[l] == 'muscle' else 0.0
                  for l, s in zip(lab, side)])

    # 2. Distance from the edge of each muscle (whole groups) and of each part.
    def depth(region):
        edge = np.zeros(nn, bool)
        cut = region[a] != region[b]
        edge[a[cut]] = edge[b[cut]] = True
        # Edges between regions are cut, so a path stays inside its region.
        keep = ~cut
        G = coo_matrix((elen[keep], (a[keep], b[keep])), shape=(nn, nn)).tocsr()
        return dijkstra(G, directed=False, indices=np.flatnonzero(edge), min_only=True)
    dg = depth(grp)
    dp = depth(part)
    full = np.zeros(nn)
    for g in np.unique(grp):
        m = grp == g
        full[m] = FULL * dg[m].max()
    s = np.clip(dg / np.maximum(full, 1e-6), 0, 1)
    h = GAIN * H * s * (2 - s)
    # 3. Grooves: full between muscles, faint between heads of one muscle.
    gauss = lambda d: np.exp(-(d / GROOVE_W) ** 2)
    h -= GROOVE * gauss(dg)
    h -= FAINT * GROOVE * gauss(dp) * (dp < dg - 1e-9)
    h[lab == nl - 1] = np.minimum(h[lab == nl - 1], 0)
    # 4. Smooth on the surface (each point with its neighbours' mean).
    deg = np.bincount(a, minlength=nn) + np.bincount(b, minlength=nn)
    for _ in range(SMOOTH):
        acc = np.bincount(a, h[b], nn) + np.bincount(b, h[a], nn)
        h = 0.5 * h + 0.5 * acc / np.maximum(deg, 1)
    n = paint.normals(P, T)
    P2 = P + h[:, None] * n
    pos2 = P2[key]
    nrm2 = paint.normals(pos2, tri, key, nn)
    print(f'sculpt: belly up to {h.max() * 1000:.1f} mm, groove down to {h.min() * 1000:.1f} mm, '
          f'mean {h.mean() * 1000:.2f} mm, points on a muscle {(H > 0).mean():.2f}')
    b64 = lambda x: base64.b64encode(np.ascontiguousarray(x).tobytes()).decode()
    data['pos'] = b64(pos2.astype('<f4'))
    data['nrm'] = b64(np.round(nrm2 * 127).astype(np.int8))
    data['sculpted'] = {'gain': GAIN, 'groove': GROOVE}
    json.dump(data, open(dst, 'w'))
    np.save(os.path.join(outdir, 'sculpt-height.npy'), h)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
