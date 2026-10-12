"""Paint the gym model from a 2D illustration (projection painting).

The body icons look good because they are paintings. This script gives the 3D
model the same look:

1. `paint.py views model.json outdir` poses the body (arms and legs spread so
   every surface faces a camera) and renders four orthographic grey "clay"
   views (front, back, right side, left side) in a 2x2 sheet: `sheet_in.png`.
2. An image model repaints that sheet in the icons' style, keeping every
   outline in place (see README, "Painted model").
3. `paint.py project model.json painted.png outdir out.json` lines each
   painted panel up with our silhouette (affine ECC on the masks), then for
   every vertex stores where it lands in each panel (`puv`), how much each view
   should count (`pw`: facing^3, zero where hidden), and a fallback colour
   (`pc`) for the few points no view sees. The page samples the painting per
   pixel with these, so the paint keeps its full detail and moves with the skin.

Orthographic projection is affine, so a panel coordinate interpolates exactly
across a triangle; that is why per-vertex `puv` is enough.
"""
import base64
import json
import os
import sys

import cv2
import numpy as np

ORDER = ['front', 'back', 'right', 'left']   # grid cells: top left, top right, bottom left, bottom right
# Sheet layout and pose, set with PAINT_LAYOUT="cols,rows,panel_w,panel_h,arm_deg,leg_deg".
# The current painting (2026-10-12) is 4x1 panels of 896x1536 in the bind pose: the image
# model kept that framing. A 2x2 sheet with spread limbs came back zoomed in and unusable.
_L = [float(v) for v in os.environ.get('PAINT_LAYOUT', '4,1,896,1536,0,0').split(',')]
GRID = (int(_L[0]), int(_L[1]))               # columns, rows
PANEL = (int(_L[2]), int(_L[3]))              # panel width, height (px) in sheet_in.png
SPREAD_ARM, SPREAD_LEG = _L[4], _L[5]         # degrees added to the bind pose for painting
# View axes: (screen right, screen up, toward the camera). "right" is the body's right side.
VIEWS = {
    'front': ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
    'back': ((-1, 0, 0), (0, 1, 0), (0, 0, -1)),
    'right': ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),
    'left': ((0, 0, -1), (0, 1, 0), (1, 0, 0)),
}
VIEWS = {k: tuple(np.array(a, float) for a in v) for k, v in VIEWS.items()}


def load(path):
    d = json.load(open(path))
    f = lambda k, t: np.frombuffer(base64.b64decode(d[k]), t)
    pos = f('pos', '<f4').reshape(-1, 3).astype(np.float64)
    nrm = f('nrm', np.int8).reshape(-1, 3) / 127.0
    tri = f('index', '<u4').reshape(-1, 3).astype(np.int64)
    return d, pos, nrm, tri


def rot(axis, deg):
    a = np.radians(deg)
    x, y, z = np.asarray(axis, float) / np.linalg.norm(axis)
    K = np.array([[0, -z, y], [z, 0, -x], [-y, x, 0]])
    return np.eye(3) + np.sin(a) * K + (1 - np.cos(a)) * K @ K


def paint_pose(d, pos, nrm):
    """Linear blend skinning of the bind mesh with the arms and legs spread."""
    bones = d['bones']
    names = [b['name'] for b in bones]
    par = {b['name']: b['parent'] for b in bones}
    head = {b['name']: np.array(b['pos']) for b in bones}
    local = {'uarmL': rot((0, 0, 1), SPREAD_ARM), 'uarmR': rot((0, 0, 1), -SPREAD_ARM),
             'thighL': rot((0, 0, 1), SPREAD_LEG), 'thighR': rot((0, 0, 1), -SPREAD_LEG)}
    M = {}

    def world(n):
        if n not in M:
            Rp, tp = world(par[n]) if par[n] else (np.eye(3), np.zeros(3))
            R = local.get(n, np.eye(3))
            M[n] = (Rp @ R, Rp @ (head[n] - R @ head[n]) + tp)
        return M[n]
    Rs = np.stack([world(n)[0] for n in names])
    ts = np.stack([world(n)[1] for n in names])
    si = np.frombuffer(base64.b64decode(d['skinIndex']), np.uint8).reshape(-1, 4).astype(int)
    sw = np.frombuffer(base64.b64decode(d['skinWeight']), np.uint8).reshape(-1, 4) / 255.0
    P, N = np.zeros_like(pos), np.zeros_like(nrm)
    for k in range(4):
        R, t = Rs[si[:, k]], ts[si[:, k]]
        P += sw[:, k:k + 1] * (np.einsum('nij,nj->ni', R, pos) + t)
        N += sw[:, k:k + 1] * np.einsum('nij,nj->ni', R, nrm)
    return P, N / (np.linalg.norm(N, axis=1, keepdims=True) + 1e-9)


def framing(pos, H, margin=0.04):
    lo, hi = pos.min(0), pos.max(0)
    return (lo[1] + hi[1]) / 2, H * (1 - 2 * margin) / (hi[1] - lo[1])


def project(pos, view, W, H, cy, scale):
    r, u, c = VIEWS[view]
    return W / 2 + (pos @ r) * scale, H / 2 - ((pos @ u) - cy) * scale, pos @ c


def render(pos, tri, view, W, H, cy, scale, n=9):
    """Z-buffer by splatting barycentric samples (triangles are a few px wide)."""
    x, y, z = project(pos, view, W, H, cy, scale)
    a, b = np.meshgrid(np.linspace(0, 1, n), np.linspace(0, 1, n))
    keep = (a + b) <= 1
    a, b = a[keep], b[keep]
    depth = np.full(H * W, -1e9)
    fid = np.full(H * W, -1, np.int64)
    bary = np.zeros((H * W, 3))
    for s in range(0, len(tri), 20000):
        t = tri[s:s + 20000]
        lerp = lambda q: q[t[:, 0], None] * a + q[t[:, 1], None] * b + q[t[:, 2], None] * (1 - a - b)
        px, py, pz = lerp(x), lerp(y), lerp(z)
        ix, iy = np.round(px).astype(np.int64), np.round(py).astype(np.int64)
        ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
        pid, zz = (iy * W + ix)[ok], pz[ok]
        ti = np.broadcast_to(np.arange(s, s + len(t))[:, None], px.shape)[ok]
        A, B = np.broadcast_to(a, px.shape)[ok], np.broadcast_to(b, px.shape)[ok]
        o = np.argsort(zz)
        pid, zz, ti, A, B = pid[o], zz[o], ti[o], A[o], B[o]
        m = zz > depth[pid]
        pid, zz, ti, A, B = pid[m], zz[m], ti[m], A[m], B[m]
        u_, last = np.unique(pid[::-1], return_index=True)
        last = len(pid) - 1 - last
        depth[u_], fid[u_] = zz[last], ti[last]
        bary[u_] = np.stack([A[last], B[last], 1 - A[last] - B[last]], 1)
    return depth.reshape(H, W), fid.reshape(H, W), bary.reshape(H, W, 3)


def cell(k):
    W, H = PANEL
    return (k % GRID[0]) * W, (k // GRID[0]) * H


def views(model, outdir):
    d, pos, nrm, tri = load(model)
    pos, nrm = paint_pose(d, pos, nrm)
    W, H = PANEL
    cy, scale = framing(pos, H)
    ao = np.frombuffer(base64.b64decode(d['ao']), np.uint8) / 255.0
    sheet = np.full((H * GRID[1], W * GRID[0], 3), 255, np.uint8)
    for k, v in enumerate(ORDER):
        depth, fid, bary = render(pos, tri, v, W, H, cy, scale)
        hit = fid >= 0
        t = tri[np.maximum(fid, 0)]
        N = (nrm[t] * bary[..., None]).sum(2)
        N /= np.linalg.norm(N, axis=-1, keepdims=True) + 1e-9
        A = (ao[t] * bary).sum(2)
        r, u, c = VIEWS[v]
        L = -0.45 * r + 0.6 * u + 0.66 * c
        L /= np.linalg.norm(L)
        shade = (0.35 + 0.55 * np.clip(N @ L, 0, 1) + 0.1 * (N @ u + 1) / 2) * (0.55 + 0.45 * A)
        shade -= 0.12 * (1 - np.clip(N @ c, 0, 1)) ** 2
        g = np.where(hit, np.clip(shade * 215, 0, 255), 255).astype(np.uint8)
        g = cv2.bilateralFilter(cv2.medianBlur(g, 5), 9, 30, 9)  # hide mesh moire; the painter adds detail
        g[~hit] = 255
        x0, y0 = cell(k)
        sheet[y0:y0 + H, x0:x0 + W] = g[..., None]
        np.save(os.path.join(outdir, f'mask_{v}.npy'), hit)
    cv2.imwrite(os.path.join(outdir, 'sheet_in.png'), sheet)


def register(paint, mask):
    """Affine map from our panel pixels to the painting (ECC on blurred silhouettes)."""
    pm = (cv2.cvtColor(paint, cv2.COLOR_BGR2GRAY) < 245).astype(np.uint8)
    pm = cv2.morphologyEx(pm, cv2.MORPH_OPEN, np.ones((5, 5)))
    a = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), 6)
    b = cv2.GaussianBlur(pm.astype(np.float32), (0, 0), 6)
    warp = np.eye(2, 3, dtype=np.float32)
    crit = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 300, 1e-7)
    _, warp = cv2.findTransformECC(a, b, warp, cv2.MOTION_AFFINE, crit, None, 5)
    al = cv2.warpAffine(pm, warp, mask.shape[::-1], flags=cv2.INTER_NEAREST | cv2.WARP_INVERSE_MAP) > 0
    return warp.astype(np.float64), (al & mask).sum() / (al | mask).sum()


def sample(img, x, y):
    out = []
    for i in range(0, len(x), 30000):  # remap needs < 32767 per side
        out.append(cv2.remap(img, x[i:i + 30000, None].astype(np.float32), y[i:i + 30000, None].astype(np.float32),
                             cv2.INTER_LINEAR, borderValue=(255, 255, 255)).reshape(-1, 3))
    return np.concatenate(out).astype(np.float64)


def fill(vc, ok, tri, iters=200):
    """Diffuse colour from painted vertices into unpainted ones over the mesh."""
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    vc, ok = vc.copy(), ok.astype(np.float64)
    for _ in range(iters):
        s = np.zeros_like(vc)
        np.add.at(s, e[:, 0], vc[e[:, 1]] * ok[e[:, 1], None])
        cnt = np.bincount(e[:, 0], ok[e[:, 1]], len(vc))
        new = (cnt > 0) & (ok == 0)
        if not new.any():
            break
        vc[new] = s[new] / cnt[new, None]
        ok[new] = 1
    return vc


def relax(vc, free, tri, iters=60):
    """Smooth the filled colours so unseen patches read as plain muscle, not smudges."""
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    deg = np.bincount(e[:, 0], minlength=len(vc))[:, None]
    for _ in range(iters):
        s = np.zeros_like(vc)
        np.add.at(s, e[:, 0], vc[e[:, 1]])
        vc[free] = (s / np.maximum(deg, 1))[free]
    return vc


def project_paint(model, painted, outdir, out):
    d, pos0, nrm0, tri = load(model)
    pos, nrm = paint_pose(d, pos0, nrm0)
    W, H = PANEL
    SW, SH = W * GRID[0], H * GRID[1]
    cy, scale = framing(pos, H)
    img = cv2.imread(painted)
    img = cv2.resize(img, (SW, SH), interpolation=cv2.INTER_AREA)
    puv = np.zeros((len(pos), len(ORDER), 2))
    wts = np.zeros((len(pos), len(ORDER)))
    cols = np.zeros((len(pos), len(ORDER), 3))
    for k, v in enumerate(ORDER):
        x0, y0 = cell(k)
        panel = img[y0:y0 + H, x0:x0 + W]
        mask = np.load(os.path.join(outdir, f'mask_{v}.npy'))
        warp, iou = register(panel, mask)
        print(f'{v}: silhouette overlap after alignment {iou:.3f}')
        depth, fid, bary = render(pos, tri, v, W, H, cy, scale)
        x, y, z = project(pos, v, W, H, cy, scale)
        px = warp[0, 0] * x + warp[0, 1] * y + warp[0, 2]
        py = warp[1, 0] * x + warp[1, 1] * y + warp[1, 2]
        ix, iy = np.clip(np.round(x).astype(int), 0, W - 1), np.clip(np.round(y).astype(int), 0, H - 1)
        zb = cv2.dilate(depth.astype(np.float32), np.ones((3, 3)))
        vis = z >= zb[iy, ix] - 0.004
        # Paintings draw a dark outline at the silhouette: fade a view out near its own edge.
        # Same near an occlusion edge (an arm in front of the chest): the painted arm
        # outline is never exactly where ours is.
        dz = np.maximum(np.abs(np.diff(depth, axis=0, prepend=depth[:1])), np.abs(np.diff(depth, axis=1, prepend=depth[:, :1])))
        cut = (~mask) | (dz > 0.02)
        inside = cv2.distanceTransform((~cut).astype(np.uint8), cv2.DIST_L2, 5)
        edge = np.clip((inside[iy, ix] - 3) / 12, 0, 1)
        wts[:, k] = np.clip(nrm @ VIEWS[v][2], 0, 1) ** 3 * vis * edge
        puv[:, k] = np.stack([(px + x0) / SW, (py + y0) / SH], 1)
        cols[:, k] = sample(panel, px, py)
    s = wts.sum(1)
    vc = (cols * wts[..., None]).sum(1) / np.maximum(s, 1e-6)[:, None]
    seen = s > 1e-3
    print(f'points seen by no view: {(~seen).sum()} of {len(pos)} (colour filled from neighbours)')
    vc = fill(vc, seen, tri)
    vc = relax(vc, ~seen, tri)
    wn = wts / np.maximum(wts.max(1, keepdims=True), 1e-6)  # page renormalises; keep the u8 range
    b64 = lambda a: base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
    d['paint'] = {'views': ORDER,
                  'puv': b64(np.round(np.clip(puv.reshape(len(pos), -1), 0, 1) * 65535).astype('<u2')),
                  'pw': b64(np.round(wn * 255).astype(np.uint8)),
                  'pc': b64(np.clip(vc[:, ::-1], 0, 255).round().astype(np.uint8))}  # BGR -> RGB
    json.dump(d, open(out, 'w'))
    full = cv2.imread(painted)  # keep the painting's own detail; 4096 px is the safe WebGL texture limit
    k = min(1.0, 4096 / max(full.shape[:2]))
    full = cv2.resize(full, (round(full.shape[1] * k), round(full.shape[0] * k)), interpolation=cv2.INTER_AREA)
    cv2.imwrite(os.path.join(outdir, 'paint.webp'), full, [cv2.IMWRITE_WEBP_QUALITY, 90])
    np.save(os.path.join(outdir, 'vc.npy'), vc)


if __name__ == '__main__':
    if sys.argv[1] == 'views':
        views(*sys.argv[2:4])
    else:
        project_paint(*sys.argv[2:6])
