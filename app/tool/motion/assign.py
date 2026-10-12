"""Lays the atlas on the body: picks a muscle for each vertex, its depth
inside the muscle, and the fibre direction in 3D."""
import numpy as np

import atlas
import charts

# Shapes are drawn a little large so neighbours meet in one seam.
INFLATE = 0.008


def assign(pos, seg, J):
    n = len(pos)
    best = np.full(n, np.inf)
    second = np.full(n, np.inf)
    mid = np.full(n, -1)
    mid2 = np.full(n, -1)
    fib = np.zeros((n, 3))
    side = np.where(pos[:, 0] >= 0, 'L', 'R')
    sx = np.where(side == 'L', 1.0, -1.0)
    tuv, _ = charts.trunk_uv(pos)
    frames = charts.limb_frames(J)
    # Chart coordinates and basis vectors for every vertex and chart.
    uv = {'trunk': tuv}
    basis = {}
    rho = np.hypot(pos[:, 0], pos[:, 2] - charts.ZC) + 1e-9
    basis['trunk'] = (np.stack([(pos[:, 2] - charts.ZC) / rho * sx, np.zeros(n), -np.abs(pos[:, 0]) / rho], 1), np.tile([0, 1.0, 0], (n, 1)))
    for c in ('upperarm', 'forearm', 'thigh', 'shin'):
        u = np.zeros((n, 2)); e1 = np.zeros((n, 3)); e2 = np.zeros((n, 3))
        for s in 'LR':
            m = side == s
            a, b, fwd, lat, r = frames[(c, s)]
            u[m], _ = charts.limb_uv(pos[m], frames[(c, s)])
            ax = (b - a) / np.linalg.norm(b - a)
            f = fwd - ax * (fwd @ ax); f /= np.linalg.norm(f)
            l = lat - ax * (lat @ ax) - f * (lat @ f); l /= np.linalg.norm(l)
            th = u[m, 0] / r
            e1[m] = -np.sin(th)[:, None] * f + np.cos(th)[:, None] * l
            e2[m] = ax
        uv[c] = u; basis[c] = (e1, e2)
    sh = {s: J[f'upperarm01.{s}____head'] for s in 'LR'}
    for i, mu in enumerate(atlas.M):
        segs = mu['segs'] or atlas.CHART_SEGS[mu['chart']]
        ok = np.isin(seg, segs)
        if mu['chart'] == 'upperarm':
            near = np.array([np.linalg.norm(p - sh[s]) < 0.13 for p, s in zip(pos, side)])
            ok &= (seg == 'upperarm') | near
        idx = np.where(ok)[0]
        if not len(idx):
            continue
        d = mu['shape'](uv[mu['chart']][idx]) - INFLATE - mu['over']
        win = d < best[idx]
        beat2 = ~win & (d < second[idx])
        mid2[idx[win]] = mid[idx[win]]
        mid2[idx[beat2]] = i
        second[idx] = np.where(win, best[idx], np.minimum(second[idx], d))
        best[idx[win]] = d[win]
        mid[idx[win]] = i
    # Where two muscles overlap, the seam is halfway between them: depth is
    # the distance to the nearer of the muscle's own edge and that seam.
    inside = best < 0
    near = mid.copy()
    with np.errstate(invalid="ignore"):
        depth = np.where(inside, np.minimum(-best, (second - best) / 2), -best)
    depth = np.nan_to_num(depth, nan=0.0, posinf=1.0, neginf=-1.0)
    mid[~inside] = -1
    for i, mu in enumerate(atlas.M):
        idx = np.where(mid == i)[0]
        if not len(idx):
            continue
        p = uv[mu['chart']][idx]
        kind, v = mu['fiber']
        dvec = np.tile(np.array(v, float), (len(idx), 1)) if kind == 'along' else np.array(v, float) - p
        dvec /= np.linalg.norm(dvec, axis=1, keepdims=True) + 1e-9
        e1, e2 = basis[mu['chart']]
        f3 = dvec[:, :1] * e1[idx] + dvec[:, 1:] * e2[idx]
        fib[idx] = f3 / (np.linalg.norm(f3, axis=1, keepdims=True) + 1e-9)
    return mid, depth, fib, side, uv, near, mid2
