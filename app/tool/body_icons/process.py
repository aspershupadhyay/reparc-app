"""Turns the generated body icon PNGs into app assets.

    python3 -I tool/body_icons/process.py <source dir> assets/body/icons

Each source is a 1024 px PNG on white, made in Figma (see README.md).
The white background around the figure becomes transparent, colours at
the soft edge lose their white fringe, and the figure is trimmed, padded
to a square, and saved as a 256 px WebP.
"""

import pathlib
import sys

import cv2
import numpy as np
from PIL import Image

SIZE = 256
PAD = 0.04


def cut(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    h, w, _ = rgb.shape
    lo = rgb.min(2)
    sat = rgb.max(2) - lo
    # Near-white, unsaturated pixels joined to the border are background.
    light = ((lo > 232) & (sat < 14)).astype(np.uint8)
    n, lab = cv2.connectedComponents(light, connectivity=4)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border)) & (light > 0)
    # Soft edge: alpha from how far a pixel is from white, inside a thin
    # band around the cut.
    near = cv2.dilate(bg.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    whiteness = np.clip((255 - lo) / (255 - 200), 0, 1)
    alpha = np.where(bg, 0.0, np.where(near, np.maximum(whiteness, 0.0), 1.0))
    alpha = cv2.GaussianBlur(alpha.astype(np.float32), (0, 0), 0.7)
    alpha[bg & (cv2.erode(bg.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0)] = 0
    # Remove the white the edge was blended with.
    a = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip((rgb - (1 - a) * 255) / a, 0, 255)
    col = np.where(alpha[..., None] > 0.02, col, 0)
    rgba = np.dstack([col, alpha * 255]).astype(np.uint8)
    ys, xs = np.nonzero(alpha > 0.05)
    box = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    img = Image.fromarray(rgba, "RGBA").crop(box)
    side = int(max(img.size) * (1 + 2 * PAD))
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
    return sq.resize((SIZE, SIZE), Image.LANCZOS)


def main(src, out):
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for p in sorted(pathlib.Path(src).glob("*.png")):
        cut(p).save(out / f"{p.stem}.webp", "WEBP", quality=82, method=6)
        print(p.stem)


if __name__ == "__main__":
    main(*sys.argv[1:3])
