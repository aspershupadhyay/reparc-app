"""Bakes the gym model's detail textures from the muscle atlas, straight
from the exact muscle shapes (no mesh in between), so edges are crisp.

    python3 -I tool/motion/bake.py /tmp/gym-tex  [size]

Writes, for the layout in charts.RECTS (one side; the other mirrors):
- id.png      muscle (atlas index) per texel, 255 for none. Sample with
              nearest filtering; the page colours each muscle from it.
- detail.webp R: fibre streaks, G: tendon, B: seam (groove) darkness.
- normal.webp tangent-space normal map (x along +u, y along +v) from a
              height field: seams as fine grooves, fibres as fine ridges.

Fibres use line integral convolution (Cabral and Leedom, 1993): white
noise is averaged along each muscle's fibre direction, which draws long
thin streaks that follow the fibres, like the lines in an anatomy plate.
"""
import os
import sys

import numpy as np
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import assign  # noqa: E402
import atlas  # noqa: E402
import charts  # noqa: E402

SEAM_W = 0.0011       # half-width of a seam groove (m)
SEAM_D = 0.0007       # seam groove depth (m)
FIBRE_D = 0.00012     # fibre ridge height (m)
LIC_STEPS = 14


def main(out, res=2048):
    os.makedirs(out, exist_ok=True)
    texel = charts.SIDE / res
    ids = np.full((res, res), 255, np.uint8)
    depth = np.full((res, res), 1.0, np.float32)     # distance inside (+) or outside (-)
    dirs = np.zeros((res, res, 2), np.float32)
    tendon = np.zeros((res, res), np.float32)
    seamk = np.ones((res, res), np.float32)       # 0.3 between heads of one muscle
    for c, (x0, y0, (u0, u1), (v0, v1)) in charts.RECTS.items():
        X0, X1 = int(x0 / texel), int(np.ceil((x0 + u1 - u0) / texel))
        Y0, Y1 = int(y0 / texel), int(np.ceil((y0 + v1 - v0) / texel))
        xs, ys = np.meshgrid(np.arange(X0, X1), np.arange(Y0, Y1))
        p = np.stack([u0 + (xs.ravel() + 0.5) * texel - x0, v0 + (ys.ravel() + 0.5) * texel - y0], 1)
        best = np.full(len(p), np.inf); second = np.full(len(p), np.inf); mid = np.full(len(p), -1); mid2 = np.full(len(p), -1)
        for i, m in enumerate(atlas.M):
            if m['chart'] != c:
                continue
            d = m['shape'](p) - assign.INFLATE - m['over']
            win = d < best
            beat2 = ~win & (d < second)
            mid2 = np.where(win, mid, np.where(beat2, i, mid2))
            second = np.where(win, best, np.minimum(second, d))
            best = np.where(win, d, best); mid = np.where(win, i, mid)
        inside = best < 0
        with np.errstate(invalid='ignore'):
            dep = np.where(inside, np.minimum(-best, (second - best) / 2), -best)
        dep = np.nan_to_num(dep, nan=-1.0, posinf=1.0, neginf=-1.0)
        fd = np.zeros((len(p), 2))
        for i in np.unique(mid[inside]):
            sel = inside & (mid == i)
            kind, v = atlas.M[i]['fiber']
            vec = np.tile(np.array(v, float), (sel.sum(), 1)) if kind == 'along' else np.array(v, float) - p[sel]
            fd[sel] = vec / (np.linalg.norm(vec, axis=1, keepdims=True) + 1e-9)
        soft = np.array([0.3 if atlas.faint(a, b) else 1.0 for a, b in zip(mid, mid2)])
        sl = (slice(Y0, Y1), slice(X0, X1))
        shape = xs.shape
        ids[sl] = np.where(inside, mid, 255).reshape(shape)
        depth[sl] = dep.reshape(shape)
        seamk[sl] = soft.reshape(shape)
        dirs[sl] = fd.reshape(shape + (2,))
        tendon[sl] = np.array([atlas.M[i]['kind'] == 'tendon' if i >= 0 else False for i in mid]).reshape(shape) * inside.reshape(shape)
        print(c, 'texels', len(p))
    # Fibres: line integral convolution of white noise along the fibre field.
    rng = np.random.default_rng(7)
    noise = rng.random((res, res)).astype(np.float32)
    acc = noise.copy(); wsum = np.ones_like(noise)
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32)
    for sgn in (1.0, -1.0):
        px, py = xx + 0.5, yy + 0.5
        for k in range(1, LIC_STEPS + 1):
            ix = np.clip(px.astype(np.int32), 0, res - 1); iy = np.clip(py.astype(np.int32), 0, res - 1)
            d = dirs[iy, ix]
            px = px + sgn * d[..., 0]; py = py + sgn * d[..., 1]
            ix = np.clip(px.astype(np.int32), 0, res - 1); iy = np.clip(py.astype(np.int32), 0, res - 1)
            w = np.exp(-(k / (LIC_STEPS * 0.6)) ** 2)
            acc += w * noise[iy, ix]; wsum += w
    lic = acc / wsum
    lic = np.clip((lic - lic.mean()) / (lic.std() * 2.5) + 0.5, 0, 1)
    muscle = (ids != 255) & (tendon < 0.5)
    fade = np.clip(depth / 0.003, 0, 1)                      # fibres fade into the seams
    seam = np.exp(-(np.abs(depth) / SEAM_W) ** 2) * ((ids != 255) | (np.abs(depth) < 0.004)) * seamk
    height = -SEAM_D * seam + FIBRE_D * (lic - 0.5) * 2 * (muscle * fade + 0.3 * tendon)
    gy, gx = np.gradient(height, texel)
    nrm = np.stack([-gx, -gy, np.ones_like(gx)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    Image.fromarray(ids).save(os.path.join(out, 'id.png'), optimize=True)
    det = np.stack([lic * (muscle * fade + 0.5 * tendon), tendon, seam, np.ones_like(seam)], -1)
    Image.fromarray((det * 255).astype(np.uint8)).convert('RGB').save(os.path.join(out, 'detail.webp'), quality=88, method=6)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8)).save(os.path.join(out, 'normal.webp'), quality=92, method=6)
    for f in ('id.png', 'detail.webp', 'normal.webp'):
        print(f, os.path.getsize(os.path.join(out, f)) // 1024, 'KB')


if __name__ == '__main__':
    main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 2048)
