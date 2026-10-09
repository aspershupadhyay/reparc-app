"""Renders a built body mesh to PNG from several angles, for a visual check.

    python3 -I tool/body/preview.py <mesh.npz> <out-prefix>

A small z-buffer rasteriser with the same lighting idea as the app, so
problems in the mesh, muscle regions, or baked shading show up before
they reach a phone.
"""

import sys

import numpy as np
from PIL import Image


def render(pos, nrm, col, tri, yaw, size=(600, 1000), pitch=5.0, bg=(28, 32, 36)):
    w, h = size
    y, p = np.radians(yaw), np.radians(pitch)
    ry = np.array([[np.cos(y), 0, -np.sin(y)], [0, 1, 0], [np.sin(y), 0, np.cos(y)]])
    rx = np.array([[1, 0, 0], [0, np.cos(p), -np.sin(p)], [0, np.sin(p), np.cos(p)]])
    r = rx @ ry
    c = (pos - np.array([0, 0.9, 0])) @ r.T
    n = nrm @ r.T
    cam = 3.4
    k = cam / (cam - c[:, 2])
    s = h * 0.95 / 1.85
    sx = w / 2 + c[:, 0] * k * s
    sy = h / 2 - c[:, 1] * k * s
    key = np.array([-0.45, 0.55, 0.70])
    key /= np.linalg.norm(key)
    fill = np.array([0.65, 0.05, 0.45])
    fill /= np.linalg.norm(fill)
    diff = np.clip(n @ key, 0, 1)
    soft = np.clip(n @ fill, 0, 1)
    rim = 0.35 * (1 - np.clip(n[:, 2], 0, 1)) ** 3
    light = 0.30 + 0.62 * diff + 0.14 * soft
    shade = np.clip(col[:, :3] * light[:, None] * col[:, 3:4] + rim[:, None] * np.array([0.16, 0.65, 0.72]), 0, 1)

    img = np.zeros((h, w, 3))
    img[:] = np.array(bg) / 255
    zb = np.full((h, w), -1e9)
    for t in tri:
        a, b_, c_ = t
        if n[a, 2] + n[b_, 2] + n[c_, 2] < -0.6:
            continue
        xs = np.array([sx[a], sx[b_], sx[c_]])
        ys = np.array([sy[a], sy[b_], sy[c_]])
        x0, x1 = int(max(np.floor(xs.min()), 0)), int(min(np.ceil(xs.max()), w - 1))
        y0, y1 = int(max(np.floor(ys.min()), 0)), int(min(np.ceil(ys.max()), h - 1))
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12:
            continue
        l0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        l1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        l2 = 1 - l0 - l1
        m = (l0 >= -1e-6) & (l1 >= -1e-6) & (l2 >= -1e-6)
        if not m.any():
            continue
        z = l0 * c[a, 2] + l1 * c[b_, 2] + l2 * c[c_, 2]
        sub = zb[y0 : y1 + 1, x0 : x1 + 1]
        m &= z > sub
        if not m.any():
            continue
        sub[m] = z[m]
        px = l0[..., None] * shade[a] + l1[..., None] * shade[b_] + l2[..., None] * shade[c_]
        img[y0 : y1 + 1, x0 : x1 + 1][m] = px[m]
    return Image.fromarray((img * 255).astype(np.uint8))


def main():
    d = np.load(sys.argv[1])
    out = sys.argv[2]
    views = [0, 35, 90, 180, 270] if len(sys.argv) < 4 else [float(a) for a in sys.argv[3].split(",")]
    imgs = [render(d["pos"], d["nrm"], d["col"], d["tri"], v) for v in views]
    sheet = Image.new("RGB", (sum(i.width for i in imgs), imgs[0].height))
    x = 0
    for i in imgs:
        sheet.paste(i, (x, 0))
        x += i.width
    sheet.save(out + ".png")


if __name__ == "__main__":
    main()
