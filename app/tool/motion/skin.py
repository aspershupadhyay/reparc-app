"""The skin look: the gym model as a real person (MakeHuman's CC0 skin, eyes, and brows).

The painted look shows the muscles as an anatomy plate. This step gives the
same body real skin, so it reads as a fit person, while the page still lights
the working muscles red through the skin:

1. Skin. MakeHuman's skin textures use MakeHuman's own UV layout. Every
   triangle of our mesh lies in one MakeHuman body quad (export.py refines
   quads, it never crosses them), so each corner's MakeHuman UV is exact: an
   original point takes its quad corner's UV, an edge middle the mean of its
   two ends, a quad centre the mean of four. Each texel of our layout then
   reads the skin texture through its triangle (re-bake, no projection).
2. Shorts. The skin textures are nude, so compression shorts are painted on,
   from the waist to the middle of the thigh, measured on the body.
3. Eyes, brows, lashes, and short hair. MakeHuman's proxies are fitted to the
   shaped body as MakeHuman fits them (.mhclo: three body points with
   weights plus a scaled offset). They ride the head bone.

    python3 -I tool/motion/skin.py <makehuman>/makehuman/data <system-assets> /tmp/base.npz /tmp/paint-out [skin]

<system-assets> is MakeHuman's CC0 system assets pack, unzipped
(makehuman_system_assets_cc0.zip, see README). [skin] is a folder in its
skins/ (default young_asian_male). Writes skin.webp into the paint folder
and adds the head parts to model.json (and model-smooth.json). Run it after
paint.py build; sculpt.py may run before or after.
"""
import base64
import io
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import paint  # noqa: E402

TEX = paint.TEX
SHORTS = np.array([0.075, 0.08, 0.09])   # charcoal fabric, linear RGB
WAIST = 0.075     # metres above the hip joints: top of the shorts
LEG = 0.45        # the shorts end this part of the way from hip to knee


def read_obj(path):
    """Vertices, texture points, and faces as (vertex ids, texture ids)."""
    v, vt, f, g = [], [], [], []
    group = None
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == 'v':
            v.append([float(x) for x in p[1:4]])
        elif p[0] == 'vt':
            vt.append([float(x) for x in p[1:3]])
        elif p[0] == 'g':
            group = p[1]
        elif p[0] == 'f':
            c = [q.split('/') for q in p[1:]]
            f.append(([int(a[0]) - 1 for a in c], [int(a[1]) - 1 for a in c] if len(c[0]) > 1 and c[0][1] else None))
            g.append(group)
    return np.array(v), np.array(vt), f, g


def fit_proxy(mhclo, V):
    """MakeHuman's proxy fitting: each point is three body points with weights plus an offset scaled per axis."""
    lines = open(mhclo).read().splitlines()
    scale = np.ones(3)
    refs = []
    on = False
    for line in lines:
        p = line.split()
        if not p or p[0].startswith('#'):
            continue
        if p[0] in ('x_scale', 'y_scale', 'z_scale'):
            ax = 'xyz'.index(p[0][0])
            a, b, d = int(p[1]), int(p[2]), float(p[3])
            scale[ax] = abs(V[a, ax] - V[b, ax]) / d
        elif p[0] == 'verts':
            on = True
        elif on and p[0][0].isdigit():
            refs.append([float(x) for x in p])
        elif on:
            on = False
    out = []
    for r in refs:
        if len(r) == 1:
            out.append(V[int(r[0])])
        else:
            i, w, d = np.array(r[:3], int), np.array(r[3:6]), np.array(r[6:9])
            out.append(w @ V[i] + d * scale)
    return np.array(out)


def webp_uri(img):
    buf = io.BytesIO()
    img.save(buf, 'WEBP', quality=85)
    return 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode()


def head_part(name, folder, mhclo, tex, V, origin, s, alpha, size):
    """A proxy fitted to the body, in metres, with its own UVs (split where a point has two)."""
    v, vt, faces, _ = read_obj(os.path.join(folder, mhclo.replace('.mhclo', '.obj')))
    P = (fit_proxy(os.path.join(folder, mhclo), V) - origin) * s
    keys, tris = {}, []
    for fv, ft in faces:
        ids = []
        for a, b in zip(fv, ft):
            ids.append(keys.setdefault((a, b), len(keys)))
        for k in range(1, len(ids) - 1):
            tris.append([ids[0], ids[k], ids[k + 1]])
    pairs = np.array(list(keys.keys()))
    pos = P[pairs[:, 0]]
    uv = vt[pairs[:, 1]] * [1, -1] + [0, 1]   # OBJ v runs up; textures load with flipY off
    img = Image.open(tex).convert('RGBA' if alpha else 'RGB')
    img.thumbnail((size, size))
    b64 = lambda a: base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
    return {'name': name, 'nv': len(pos), 'pos': b64(pos.astype('<f4')), 'uv': b64(uv.astype('<f4')),
            'index': b64(np.array(tris, '<u2')), 'tex': webp_uri(img), 'alpha': alpha}


def main(mhdata, sysdir, base_npz, outdir, skin='young_asian_male'):
    d = np.load(base_npz, allow_pickle=True)
    used, par, seg = d['used'], d['par'], d['seg']
    V, origin, s = d['vfull'], d['origin'], float(d['scale'])
    nu = len(used)
    remap = -np.ones(len(V), np.int64)
    remap[used] = np.arange(nu)
    # MakeHuman body quads with their texture points, in our point ids.
    _, vt, faces, groups = read_obj(os.path.join(mhdata, '3dobjs', 'base.obj'))
    quads = [(remap[fv], ft) for (fv, ft), g in zip(faces, groups) if g == 'body']
    by_vert = {}
    for qi, (fv, _) in enumerate(quads):
        for a in fv:
            by_vert.setdefault(int(a), []).append(qi)
    anc = lambda i: [i] if i < nu else [int(p) for p in par[i - nu] if p >= 0]

    data = json.load(open(os.path.join(outdir, 'model-smooth.json') if os.path.exists(os.path.join(outdir, 'model-smooth.json'))
                          else os.path.join(outdir, 'model.json')))
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
    pos = dec('pos', '<f4').reshape(nv, 3).astype(np.float64)
    tri = dec('index', '<u2').reshape(-1, 3).astype(np.int64)
    uv = dec('uv', '<u2').reshape(nv, 2) / 65535.0
    orig = dec('orig', '<u2').astype(np.int64)
    # 1. MakeHuman UV of every triangle corner.
    cuv = np.zeros((len(tri), 3, 2))
    for t, corners in enumerate(orig[tri]):
        A = [anc(int(c)) for c in corners]
        need = set(a for x in A for a in x)
        cand = set(by_vert[next(iter(need))])
        for a in need:
            cand &= set(by_vert[a])
        fv, ft = quads[min(cand)]
        tex_of = {int(a): vt[b] for a, b in zip(fv, ft)}
        for k in range(3):
            cuv[t, k] = np.mean([tex_of[a] for a in A[k]], axis=0)
    _, fid, bary = paint.splat(uv[:, 0] * TEX - 0.5, uv[:, 1] * TEX - 0.5, np.zeros(nv), tri, TEX, TEX, n=24)
    cov = fid >= 0
    f, b = fid[cov], bary[cov]
    muv = (cuv[f] * b[..., None]).sum(1)
    src = cv2.imread(os.path.join(sysdir, 'skins', skin, next(x for x in os.listdir(os.path.join(sysdir, 'skins', skin)) if x.endswith('.png'))))
    sh, sw = src.shape[:2]
    col = paint.remap(src, muv[:, 0] * sw - 0.5, (1 - muv[:, 1]) * sh - 0.5) / 255
    # 2. Shorts, measured on the body: from the waist to part way down the thigh.
    J = {k: np.array(v) for k, v in json.loads(str(d['joints'])).items()}
    hip = (J['upperleg01.L____head'] + J['upperleg01.R____head']) / 2
    knee = (J['lowerleg01.L____head'] + J['lowerleg01.R____head']) / 2
    p3 = (pos[tri[f]] * b[..., None]).sum(1)
    sg = seg[orig[tri[f, 0]]]
    top, low = hip[1] + WAIST, hip[1] - LEG * (hip[1] - knee[1])
    on = np.isin(sg, ('trunk', 'thigh')) & (p3[:, 1] < top) & (p3[:, 1] > low)
    edge = np.minimum(top - p3[:, 1], p3[:, 1] - low)
    rng = np.random.default_rng(3)
    weave = 1 + 0.06 * rng.standard_normal(len(col))
    band = (top - p3[:, 1] < 0.035) | (p3[:, 1] - low < 0.02)   # waistband and hems
    fabric = SHORTS * weave[:, None] * np.where(band, 1.35, 1.0)[:, None]
    srgb = lambda x: np.where(x < 0.0031308, 12.92 * x, 1.055 * np.power(np.maximum(x, 0), 1 / 2.4) - 0.055)
    a = np.clip(edge / 0.002, 0, 1) * on
    col = col * (1 - a[:, None]) + srgb(fabric)[:, ::-1] * a[:, None]
    img = np.zeros((TEX, TEX, 3))
    img[cov] = col
    # Pad past chart borders with the nearest covered texel (a blur would pull in other charts' colours).
    _, near = cv2.distanceTransformWithLabels((~cov).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    src = np.zeros((int(near.max()) + 1, 3))
    src[near[cov]] = img[cov]
    img = np.where(cov[..., None], img, src[near])
    cv2.imwrite(os.path.join(outdir, 'skin.webp'), np.clip(img * 255, 0, 255).astype(np.uint8), [cv2.IMWRITE_WEBP_QUALITY, 90])
    print(f'skin {skin}: texels covered {cov.mean():.2f}, shorts {on.mean():.2f} of them')
    # 3. Eyes and brows on the head bone.
    parts = [
        head_part('eyes', os.path.join(sysdir, 'eyes', 'low-poly'), 'low-poly.mhclo',
                  os.path.join(sysdir, 'eyes', 'materials', 'brown_eye.png'), V, origin, s, False, 512),
        head_part('brows', os.path.join(sysdir, 'eyebrows', 'eyebrow001'), 'eyebrow001.mhclo',
                  os.path.join(sysdir, 'eyebrows', 'eyebrow001', 'eyebrow001.png'), V, origin, s, True, 256),
        head_part('hair', os.path.join(sysdir, 'hair', 'short02'), 'short02.mhclo',
                  os.path.join(sysdir, 'hair', 'short02', 'short02_diffuse.png'), V, origin, s, True, 512),
        head_part('lashes', os.path.join(sysdir, 'eyelashes', 'eyelashes01'), 'eyelashes01.mhclo',
                  os.path.join(sysdir, 'eyelashes', 'eyelashes01', 'eyelashes01.png'), V, origin, s, True, 256),
    ]
    for fn in ('model.json', 'model-smooth.json'):
        p = os.path.join(outdir, fn)
        if os.path.exists(p):
            m = json.load(open(p))
            m['head'] = parts
            m['skin'] = skin
            json.dump(m, open(p, 'w'))
    print('head parts:', ', '.join(f"{p['name']} {p['nv']} points" for p in parts))


if __name__ == '__main__':
    if len(sys.argv) not in (5, 6):
        raise SystemExit(__doc__)
    main(*sys.argv[1:])
