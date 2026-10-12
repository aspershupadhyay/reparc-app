"""The painted gym model: the body icons' look on the 3D body.

The icons look real because they are paintings. This builds a model that
wears a painting in the same style:

1. `views`: render the smooth body in grey from set views (one "sheet" of
   panels per pose) for an image model to repaint (see README, "Painted
   model", and `paint/sheets.json`).
2. `build`: give the body a full UV layout (xatlas), then bake every painted
   view into three ordinary 2048 px textures:
   - `albedo.webp`: the paint. For each texel, every view that sees it adds its
     colour, weighted by facing^3 and faded out near an outline or an
     occlusion edge (paintings draw dark outlines there). Texels no view sees
     well take colour diffused over the surface from their neighbours.
   - `normal.webp`: relief from the paint (luminance high-pass as height), so
     the scene light moves over the painted bellies and fibres.
   - `label.png`: which muscle part each texel belongs to, for the red highlight.
     It starts from our muscle atlas and is snapped to the painted muscle edges
     with a watershed on each painting, so the red follows the painted muscle.
   The model ships as the 25k-point base mesh; the page and `glb.py` subdivide
   it once (Phong), exactly as `subdivide()` here does, so texture and surface
   agree.

    python3 -I paint.py views base.npz gym-flat.json paint/sheets.json SHEET_INDEX out.png
    python3 -I paint.py build base.npz gym-flat.json paint/sheets.json outdir

gym-flat.json is `RELIEF=0 gym.py` output; only its skeleton and muscle
tables are used. A painting must keep the panel layout: `build` prints the
outline overlap per view after alignment and stops below 0.9.
"""
import base64
import json
import os
import sys

import cv2
import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
sys.path.insert(0, os.path.join(os.path.dirname(here), 'body'))
import assign  # noqa: E402
import atlas  # noqa: E402
import muscles  # noqa: E402

TEX = 2048
SKIN_SEGS = ('trunk', 'neck', 'upperarm', 'forearm', 'thigh', 'shin')
EDGE_FADE = (3, 12)   # px inside an outline: start, length of the fade
MIN_OVERLAP = 0.9
BARE = 254


# ---------------------------------------------------------------- geometry
def normals(pos, tri, key=None, nkey=None):
    """Area-weighted vertex normals; with [key], copies of one point share one normal."""
    fn = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    if key is None:
        key, nkey = np.arange(len(pos)), len(pos)
    n = np.zeros((nkey, 3))
    for k in range(3):
        np.add.at(n, key[tri[:, k]], fn)
    n = n[key]
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def edges(tri):
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e.sort(1)
    uniq, inv = np.unique(e, axis=0, return_inverse=True)
    return uniq, inv.reshape(-1)


def subdivide(pos, nrm, tri, attrs, orig):
    """Each triangle into four; new points on the Phong surface. Same as the page.

    attrs are averaged. Also returns the weld key (one id per surface point,
    shared by the copies a UV seam makes) for seamless normals.
    """
    uniq, inv = edges(tri)
    a, b = uniq[:, 0], uniq[:, 1]
    m = (pos[a] + pos[b]) / 2
    proj = lambda q, p, n: q - ((q - p) * n).sum(1, keepdims=True) * n
    m = 0.25 * m + 0.75 * (proj(m, pos[a], nrm[a]) + proj(m, pos[b], nrm[b])) / 2
    n0, nt = len(pos), len(tri)
    out = {k: np.concatenate([v, (v[a] + v[b]) / 2]) for k, v in attrs.items()}
    mab, mbc, mca = inv[:nt] + n0, inv[nt:2 * nt] + n0, inv[2 * nt:] + n0
    t0, t1, t2 = tri[:, 0], tri[:, 1], tri[:, 2]
    newtri = np.concatenate([np.stack([t0, mab, mca], 1), np.stack([mab, t1, mbc], 1),
                             np.stack([mca, mbc, t2], 1), np.stack([mab, mbc, mca], 1)])
    oa, ob = np.minimum(orig[a], orig[b]), np.maximum(orig[a], orig[b])
    no = int(orig.max()) + 1
    ekey = np.unique(oa * no + ob, return_inverse=True)[1].reshape(-1)
    key = np.concatenate([orig, no + ekey])
    return np.concatenate([pos, m]), newtri, out, key, int(key.max() + 1)


def rot(axis, deg):
    a = np.radians(deg)
    x, y, z = np.asarray(axis, float) / np.linalg.norm(axis)
    K = np.array([[0, -z, y], [z, 0, -x], [-y, x, 0]])
    return np.eye(3) + np.sin(a) * K + (1 - np.cos(a)) * K @ K


def skin(bones, pos, nrm, si, sw, arm=0.0, leg=0.0):
    """Linear blend skinning with the arms and legs spread by [arm], [leg] degrees."""
    names = [b['name'] for b in bones]
    par = {b['name']: b['parent'] for b in bones}
    head = {b['name']: np.array(b['pos']) for b in bones}
    local = {'uarmL': rot((0, 0, 1), arm), 'uarmR': rot((0, 0, 1), -arm),
             'thighL': rot((0, 0, 1), leg), 'thighR': rot((0, 0, 1), -leg)}
    M = {}

    def world(n):
        if n not in M:
            Rp, tp = world(par[n]) if par[n] else (np.eye(3), np.zeros(3))
            R = local.get(n, np.eye(3))
            M[n] = (Rp @ R, Rp @ (head[n] - R @ head[n]) + tp)
        return M[n]
    Rs = np.stack([world(n)[0] for n in names])
    ts = np.stack([world(n)[1] for n in names])
    P, N = np.zeros_like(pos), np.zeros_like(nrm)
    for k in range(si.shape[1]):
        R, t = Rs[si[:, k]], ts[si[:, k]]
        P += sw[:, k:k + 1] * (np.einsum('nij,nj->ni', R, pos) + t)
        N += sw[:, k:k + 1] * np.einsum('nij,nj->ni', R, nrm)
    return P, N / (np.linalg.norm(N, axis=1, keepdims=True) + 1e-9)


# ---------------------------------------------------------------- cameras
def axes(yaw, pitch):
    """(screen right, screen up, toward camera) for a camera at [yaw] around y (0 = front)."""
    y, p = np.radians(yaw), np.radians(pitch)
    c = np.array([np.sin(y) * np.cos(p), np.sin(p), np.cos(y) * np.cos(p)])
    r = np.cross([0, 1.0, 0], c)
    r /= np.linalg.norm(r)
    return r, np.cross(c, r), c


def framing(P, sheet):
    """One scale for every panel of a sheet: the largest that fits all views."""
    W, H = sheet['w'], sheet['h']
    best = np.inf
    for yaw, pitch in sheet['views']:
        r, u, c = axes(yaw, pitch)
        best = min(best, H * 0.92 / np.ptp(P @ u), W * 0.86 / (2 * np.abs(P @ r).max()))
    ys = P @ axes(*sheet['views'][0])[1]
    return (ys.min() + ys.max()) / 2, best


def project(P, view, W, H, cy, scale):
    r, u, c = axes(*view)
    return W / 2 + (P @ r) * scale, H / 2 - ((P @ u) - cy) * scale, P @ c


def splat(x, y, z, tri, W, H, n=9):
    """Z-buffer by splatting barycentric samples. Returns depth, triangle, barycentrics."""
    a, b = np.meshgrid(np.linspace(0, 1, n), np.linspace(0, 1, n))
    keep = (a + b) <= 1
    a, b = a[keep], b[keep]
    depth = np.full(H * W, -1e9)
    fid = np.full(H * W, -1, np.int64)
    bary = np.zeros((H * W, 2))
    for s in range(0, len(tri), 20000):
        t = tri[s:s + 20000]
        lerp = lambda q: q[t[:, 0], None] * a + q[t[:, 1], None] * b + q[t[:, 2], None] * (1 - a - b)
        px, py, pz = lerp(x), lerp(y), lerp(z)
        ix, iy = np.round(px).astype(np.int64), np.round(py).astype(np.int64)
        ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
        pid, zz = (iy * W + ix)[ok], pz[ok]
        ti = np.broadcast_to(np.arange(s, s + len(t))[:, None], px.shape)[ok]
        A, B = np.broadcast_to(a, px.shape)[ok], np.broadcast_to(b, px.shape)[ok]
        o = np.argsort(zz, kind='stable')
        pid, zz, ti, A, B = pid[o], zz[o], ti[o], A[o], B[o]
        m = zz >= depth[pid]
        pid, zz, ti, A, B = pid[m], zz[m], ti[m], A[m], B[m]
        u_, last = np.unique(pid[::-1], return_index=True)
        last = len(pid) - 1 - last
        depth[u_], fid[u_] = zz[last], ti[last]
        bary[u_] = np.stack([A[last], B[last]], 1)
    b3 = np.concatenate([bary, 1 - bary.sum(1, keepdims=True)], 1)
    return depth.reshape(H, W), fid.reshape(H, W), b3.reshape(H, W, 3)


# ---------------------------------------------------------------- the model
def base_model(base_npz, meta_json):
    """The 25k base body with skin weights, occlusion, muscle ids and a full UV layout."""
    import xatlas
    d = np.load(base_npz, allow_pickle=True)
    meta = json.load(open(meta_json))
    J = {k: np.array(v) for k, v in json.loads(str(d['joints'])).items()}
    pos, tri, W, seg = d['pos'].astype(np.float64), d['tri'].astype(np.int64), d['W'], d['seg']
    nrm = normals(pos, tri)
    ao = muscles.occlusion(pos, nrm, tri, dirs=96)
    # Muscle ids and belly weight for the volume bulge (as in gym.py).
    mid, depth, fib, side, _, near_id, _ = assign.assign(pos, seg, J)
    ins = mid >= 0
    maxd = np.zeros(len(atlas.M))
    for i in range(len(atlas.M)):
        if (mid == i).any():
            maxd[i] = depth[mid == i].max()
    amp = np.zeros(len(pos))
    R = np.clip(maxd[mid[ins]] * 0.75, 0.006, 0.03)
    s = np.clip(depth[ins] / R, 0, 1)
    tendon = np.array([m['kind'] == 'tendon' for m in atlas.M])
    amp[ins] = np.where(tendon[mid[ins]], 0, s * (2 - s))
    near = (~ins) & np.isin(seg, SKIN_SEGS)
    gid = np.where((near_id >= 0) & (ins | near), near_id * 2 + (side == 'R'), 65535).astype(np.int64)
    idx = np.argsort(-W, axis=1)[:, :4]
    w4 = np.take_along_axis(W, idx, 1)
    w4 /= np.maximum(w4.sum(1, keepdims=True), 1e-9)
    # UV layout: charts cut by xatlas, packed for 2048 px with room to pad.
    at = xatlas.Atlas()
    at.add_mesh(pos.astype(np.float32), tri.astype(np.uint32))
    po = xatlas.PackOptions()
    po.resolution, po.padding, po.bilinear = TEX, 8, True
    co = xatlas.ChartOptions()
    # Fewer, longer charts (275 rather than 353): fewer seams and longer fibre strokes.
    co.max_cost, co.normal_deviation_weight, co.roundness_weight, co.straightness_weight = 16.0, 1.0, 0.0, 2.0
    at.generate(co, po)
    vm, ntri, uv = at[0]
    vm = vm.astype(np.int64)
    print(f'uv layout: {len(pos)} -> {len(vm)} points (seams split), {at.chart_count} charts')
    return {'meta': meta, 'pos': pos[vm], 'nrm': nrm[vm], 'tri': ntri.astype(np.int64), 'uv': uv.astype(np.float64),
            'orig': vm, 'si': idx[vm], 'sw': w4[vm], 'ao': ao[vm], 'gid': gid[vm], 'amp': amp[vm], 'fib': fib[vm],
            'bare': np.isin(seg, ('head', 'hand', 'foot'))[vm]}


def fine(mdl, arm=0.0, leg=0.0):
    """The subdivided (page) surface, posed: positions, welded normals, uv, part, triangles, weld key."""
    P, N = skin(mdl['meta']['bones'], mdl['pos'], mdl['nrm'], mdl['si'], mdl['sw'], arm, leg)
    # Part per point: atlas part, 254 bare skin (head, hands, feet), 255 body skin with no part.
    lab = np.where(mdl['gid'] < 65535, mdl['gid'] // 2, np.where(mdl['bare'], BARE, 255))
    pos, tri, A, key, nkey = subdivide(P, N, mdl['tri'], {'uv': mdl['uv']}, mdl['orig'])
    uniq, _ = edges(mdl['tri'])
    lab = np.concatenate([lab, lab[uniq[:, 0]]])  # a midpoint takes its first end's part
    return pos, normals(pos, tri, key, nkey), A['uv'], lab, tri, key, nkey


def render_grey(P, N, tri, view, W, H, cy, scale):
    x, y, z = project(P, view, W, H, cy, scale)
    depth, fid, bary = splat(x, y, z, tri, W, H)
    hit = fid >= 0
    t = tri[np.maximum(fid, 0)]
    n = (N[t] * bary[..., None]).sum(2)
    n /= np.linalg.norm(n, axis=-1, keepdims=True) + 1e-9
    r, u, c = axes(*view)
    L = -0.45 * r + 0.6 * u + 0.66 * c
    L /= np.linalg.norm(L)
    shade = 0.35 + 0.55 * np.clip(n @ L, 0, 1) + 0.1 * (n @ u + 1) / 2
    shade -= 0.12 * (1 - np.clip(n @ c, 0, 1)) ** 2
    g = np.where(hit, np.clip(shade * 215, 0, 255), 255).astype(np.uint8)
    g = cv2.bilateralFilter(cv2.medianBlur(g, 5), 9, 30, 9)  # hide mesh moire; the painter adds detail
    g[~hit] = 255
    return g


def views(base_npz, meta_json, sheets_json, i, out):
    """The grey sheet an image model repaints."""
    sheet = json.load(open(sheets_json))[int(i)]
    mdl = base_model(base_npz, meta_json)
    P, N, _, _, tri, _, _ = fine(mdl, sheet.get('arm', 0), sheet.get('leg', 0))
    W, H, cols = sheet['w'], sheet['h'], sheet['cols']
    cy, scale = framing(P, sheet)
    img = np.full((H * sheet['rows'], W * cols), 255, np.uint8)
    for k, view in enumerate(sheet['views']):
        img[(k // cols) * H:(k // cols + 1) * H, (k % cols) * W:(k % cols + 1) * W] = render_grey(P, N, tri, view, W, H, cy, scale)
    cv2.imwrite(out, img)


# ---------------------------------------------------------------- baking
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


def remap(img, x, y, border=255):
    out = []
    for i in range(0, len(x), 30000):  # remap needs < 32767 per side
        r = cv2.remap(img, x[i:i + 30000, None].astype(np.float32), y[i:i + 30000, None].astype(np.float32),
                      cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=border)
        out.append(r.reshape(len(r), -1))
    return np.concatenate(out).astype(np.float64)


def snap_labels(paint, lab, hit, core=9):
    """Move our atlas part borders onto the painted muscle edges (watershed).

    Only the sure middle of each part (eroded [core] px) seeds; the watershed
    on the painting decides where the border runs.
    """
    seeds = np.zeros(lab.shape, np.int32)
    for v in np.unique(lab[hit]):
        if v == 255:
            continue  # plain body skin seeds nothing: the muscles around it share it out
        m = ((lab == v) & hit).astype(np.uint8)
        seeds[cv2.erode(m, np.ones((3, 3)), iterations=core) > 0] = int(v) + 1
    seeds[cv2.dilate(hit.astype(np.uint8), np.ones((3, 3)), iterations=2) == 0] = 300  # background
    ws = cv2.watershed(cv2.GaussianBlur(paint, (0, 0), 1.2), seeds)
    out = np.where((ws > 0) & (ws < BARE + 1), ws - 1, 255)
    out[ws == -1] = lab[ws == -1]
    out[~hit] = 255
    # Small stray islands (under 300 px) go back to the atlas part.
    for v in np.unique(out[hit]):
        n, cc, stats, _ = cv2.connectedComponentsWithStats((out == v).astype(np.uint8), connectivity=4)
        small = np.where(stats[1:, cv2.CC_STAT_AREA] < 300)[0] + 1
        if len(small):
            m = np.isin(cc, small)
            out[m] = lab[m]
    return out.astype(np.int64)


def mode_filter(L, cov, k=7):
    """Each covered texel takes the commonest part around it: removes stray specks."""
    best = np.full(L.shape, -1.0, np.float32)
    out = L.copy()
    for v in np.unique(L[cov]):
        f = cv2.blur((L == v).astype(np.float32), (k, k))
        take = cov & (f > best)
        out[take] = v
        best = np.maximum(best, np.where(cov, f, -1))
    return out


def pushpull(img, mask):
    """Fill unmasked texels from masked ones (mip pyramid push-pull)."""
    levels = [(img * mask[..., None], mask.astype(np.float64))]
    while min(levels[-1][1].shape) > 4:
        c, w = levels[-1]
        c2 = c[0::2, 0::2] + c[1::2, 0::2] + c[0::2, 1::2] + c[1::2, 1::2]
        w2 = w[0::2, 0::2] + w[1::2, 0::2] + w[0::2, 1::2] + w[1::2, 1::2]
        levels.append((c2, w2))
    c, w = levels[-1]
    fill = c / np.maximum(w, 1e-9)[..., None]
    for c, w in reversed(levels[:-1]):
        up = cv2.resize(fill, (c.shape[1], c.shape[0]), interpolation=cv2.INTER_LINEAR).reshape(c.shape)
        k = np.clip(w, 0, 1)[..., None]
        fill = c / np.maximum(w, 1e-9)[..., None] * k + up * (1 - k)
    return fill


def mesh_fill(val, ok, tri, key, nkey, relax=60):
    """Diffuse values from known points into unknown ones over the welded surface, then smooth them."""
    acc = np.zeros((nkey, val.shape[1]))
    cnt = np.zeros(nkey)
    np.add.at(acc, key[ok], val[ok])
    np.add.at(cnt, key[ok], 1)
    v = acc / np.maximum(cnt, 1)[:, None]
    known = cnt > 0
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = key[np.concatenate([e, e[:, ::-1]])]
    while not known.all():
        s = np.zeros_like(v)
        c = np.zeros(nkey)
        np.add.at(s, e[:, 0], v[e[:, 1]] * known[e[:, 1], None])
        np.add.at(c, e[:, 0], known[e[:, 1]])
        new = (c > 0) & ~known
        if not new.any():
            break
        v[new] = s[new] / c[new, None]
        known |= new
    free = cnt == 0
    deg = np.bincount(e[:, 0], minlength=nkey)[:, None]
    for _ in range(relax):
        s = np.zeros_like(v)
        np.add.at(s, e[:, 0], v[e[:, 1]])
        v[free] = (s / np.maximum(deg, 1))[free]
    return v[key]


def fibre_field(mdl, P0, uv, tri, ti, tb):
    """Each covered texel's muscle fibre direction in texels (unit length; zero off muscle)."""
    _, _, A, _, _ = subdivide(mdl['pos'], mdl['nrm'], mdl['tri'], {'f': mdl['fib']}, mdl['orig'])
    t = tri[ti]
    f = (A['f'][t] * tb[..., None]).sum(1)
    p0, p1, p2 = P0[t[:, 0]], P0[t[:, 1]], P0[t[:, 2]]
    u0, u1, u2 = uv[t[:, 0]] * TEX, uv[t[:, 1]] * TEX, uv[t[:, 2]] * TEX
    E = np.stack([p1 - p0, p2 - p0], 2)            # edges in space (3x2)
    U = np.stack([u1 - u0, u2 - u0], 2)            # the same edges in texels (2x2)
    Tm = np.einsum('nij,njk->nik', E, np.linalg.pinv(U))   # d(space)/d(texel)
    d = np.einsum('nji,nj->ni', np.linalg.pinv(Tm).transpose(0, 2, 1), f)
    n = np.linalg.norm(d, axis=1, keepdims=True)
    on = (np.linalg.norm(f, axis=1) > 0.5)[:, None]
    return np.where(on & (n > 1e-9), d / np.maximum(n, 1e-9), 0)


def lic(dirx, diry, mask, steps=16, seed=7):
    """Line integral convolution: noise averaged along the field gives fibre streaks."""
    H, W = mask.shape
    rng = np.random.RandomState(seed)
    noise = cv2.GaussianBlur(rng.rand(H, W).astype(np.float32), (0, 0), 0.7)
    acc = noise.copy()
    cnt = np.ones_like(noise)
    gy, gx = np.mgrid[0:H, 0:W].astype(np.float32)
    for sgn in (1, -1):
        x, y = gx.copy(), gy.copy()
        px, py = sgn * dirx, sgn * diry   # a fibre has no sign: keep going the way we came
        for _ in range(steps):
            ix, iy = np.clip(x.round().astype(int), 0, W - 1), np.clip(y.round().astype(int), 0, H - 1)
            dx, dy = dirx[iy, ix], diry[iy, ix]
            flip = np.where(dx * px + dy * py < 0, -1.0, 1.0).astype(np.float32)
            dx, dy = dx * flip, dy * flip
            x += dx; y += dy
            px, py = dx, dy
            ok = mask[np.clip(y.round().astype(int), 0, H - 1), np.clip(x.round().astype(int), 0, W - 1)]
            acc += np.where(ok, cv2.remap(noise, x, y, cv2.INTER_LINEAR), 0)
            cnt += ok
    # A streak cut short at a chart edge is just noise: report how long each one got.
    return acc / cnt, np.clip((cnt - 6) / (2 * steps - 6), 0, 1)


def build(base_npz, meta_json, sheets_json, outdir):
    os.makedirs(outdir, exist_ok=True)
    sheets = json.load(open(sheets_json))
    root = os.path.dirname(os.path.abspath(sheets_json))
    mdl = base_model(base_npz, meta_json)
    # Texels: which fine triangle covers each one.
    P0, _, uv, lab0, tri, key, nkey = fine(mdl)
    _, tfid, tbary = splat(uv[:, 0] * TEX - 0.5, uv[:, 1] * TEX - 0.5, np.zeros(len(uv)), tri, TEX, TEX, n=8)
    cov = tfid >= 0
    tt, tb = tri[tfid[cov]], tbary[cov]
    tl = lab0[tt[np.arange(len(tt)), tb.argmax(1)]]
    print(f'texels covered: {cov.mean():.2f}')
    nT = len(tt)
    csum, hsum, wsum = np.zeros((nT, 3)), np.zeros(nT), np.zeros(nT)
    lbest, lw = tl.copy(), np.zeros(nT)
    vsum, vw = np.zeros((len(P0), 4)), np.zeros(len(P0))  # per point colour + height, for the fallback
    for sheet in sheets:
        img = cv2.imread(os.path.join(root, sheet['image']))
        cols, rows, W, H = sheet['cols'], sheet['rows'], sheet['w'], sheet['h']
        sx, sy = img.shape[1] / (W * cols), img.shape[0] / (H * rows)
        small = cv2.resize(img, (W * cols, H * rows), interpolation=cv2.INTER_AREA)
        lum = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32) / 255
        height = lum - cv2.GaussianBlur(lum, (0, 0), 6 * sx)  # detail finer than about 7 mm
        P, N, _, labv, _, _, _ = fine(mdl, sheet.get('arm', 0), sheet.get('leg', 0))
        cy, scale = framing(P, sheet)
        Pt = (P[tt] * tb[..., None]).sum(1)
        Nt = (N[tt] * tb[..., None]).sum(1)
        Nt /= np.linalg.norm(Nt, axis=1, keepdims=True) + 1e-9
        for k, view in enumerate(sheet['views']):
            x0, y0 = (k % cols) * W, (k // cols) * H
            x, y, z = project(P, view, W, H, cy, scale)
            depth, fid, bary = splat(x, y, z, tri, W, H)
            hit = fid >= 0
            warp, iou = register(small[y0:y0 + H, x0:x0 + W], hit)
            print(f"{sheet['image']} view {view}: outline overlap after alignment {iou:.3f}")
            if iou < MIN_OVERLAP:
                raise SystemExit('this painting moved the body; do not use it')
            dz = np.maximum(np.abs(np.diff(depth, axis=0, prepend=depth[:1])),
                            np.abs(np.diff(depth, axis=1, prepend=depth[:, :1])))
            inside = cv2.distanceTransform((hit & (dz < 0.02)).astype(np.uint8), cv2.DIST_L2, 5)
            zb = cv2.dilate(depth.astype(np.float32), np.ones((3, 3)))

            def to_paint(px, py):
                return ((warp[0, 0] * px + warp[0, 1] * py + warp[0, 2] + x0) * sx,
                        (warp[1, 0] * px + warp[1, 1] * py + warp[1, 2] + y0) * sy)
            # Our part labels in this view, snapped to the painting's muscle edges.
            t = tri[np.maximum(fid, 0)]
            lv = np.where(hit, labv[np.take_along_axis(t, bary.argmax(-1)[..., None], -1)[..., 0]], 255)
            gx, gy = np.meshgrid(np.arange(W, dtype=np.float64), np.arange(H, dtype=np.float64))
            ppx, ppy = to_paint(gx, gy)
            pan = cv2.remap(img, ppx.astype(np.float32), ppy.astype(np.float32), cv2.INTER_AREA, borderValue=(255, 255, 255))
            lsnap = snap_labels(pan, lv, hit)

            def weights(Q, Nq):
                qx, qy, qz = project(Q, view, W, H, cy, scale)
                ix, iy = np.clip(np.round(qx).astype(int), 0, W - 1), np.clip(np.round(qy).astype(int), 0, H - 1)
                vis = qz >= zb[iy, ix] - 0.004
                edge = np.clip((inside[iy, ix] - EDGE_FADE[0]) / EDGE_FADE[1], 0, 1)
                return np.clip(Nq @ axes(*view)[2], 0, 1) ** 3 * vis * edge, qx, qy, ix, iy
            w, qx, qy, ix, iy = weights(Pt, Nt)
            px, py = to_paint(qx, qy)
            s = w > 0
            csum[s] += w[s, None] * remap(img, px[s], py[s])
            hsum[s] += w[s] * remap(height, px[s], py[s], border=0)[:, 0]
            wsum += w
            better = (w > lw) & (w > 0.25)  # only a clear view moves a part border
            lbest[better] = lsnap[iy[better], ix[better]]
            lw = np.maximum(lw, w)
            wv, vx, vy, _, _ = weights(P, N)
            vpx, vpy = to_paint(vx, vy)
            s = wv > 0
            vsum[s, :3] += wv[s, None] * remap(img, vpx[s], vpy[s])
            vsum[s, 3] += wv[s] * remap(height, vpx[s], vpy[s], border=0)[:, 0]
            vw += wv
    seen = vw > 1e-3
    print(f'fine points no view sees: {(~seen).mean():.2f} (filled from neighbours)')
    fb = mesh_fill(vsum / np.maximum(vw, 1e-9)[:, None], seen, tri, key, nkey)
    fbt = (fb[tt] * tb[..., None]).sum(1)
    eps = 0.03
    col = (csum + eps * fbt[:, :3]) / (wsum + eps)[:, None]
    hgt = (hsum + eps * fbt[:, 3]) / (wsum + eps)
    # Where the painting is thin (no view sees a texel well), draw fibre strokes in the
    # paint's own colour along each muscle's fibre direction, so it still reads as painted muscle.
    d = fibre_field(mdl, P0, uv, tri, tfid[cov], tb)
    dx = np.zeros((TEX, TEX), np.float32); dy = np.zeros((TEX, TEX), np.float32)
    dx[cov], dy[cov] = d[:, 0], d[:, 1]
    st, full = lic(dx, dy, cov)
    st, full = st[cov], full[cov]
    on = np.linalg.norm(d, axis=1) > 0
    z = (st - st[on].mean()) / (st[on].std() + 1e-9)
    thin = np.clip(1 - wsum / 0.35, 0, 1) * on * full
    col *= (1 + 0.1 * np.clip(z, -2.5, 2.5) * thin)[:, None]
    hgt += 0.025 * np.clip(z, -2.5, 2.5) * thin
    print(f'texels with thin paint (fibre strokes added): {(thin > 0.5).mean():.2f}')
    weak = lw < 0.05
    lbest[weak] = tl[weak]  # no view sees it well: keep the atlas part
    print(f'texels with a weak view (atlas part kept): {weak.mean():.2f}')
    # Texture images, padded past the chart borders.
    A = np.zeros((TEX, TEX, 3)); A[cov] = col
    Hh = np.zeros((TEX, TEX, 1)); Hh[cov, 0] = hgt
    A = pushpull(A, cov)
    Hh = pushpull(Hh, cov)[..., 0]
    lbest = np.where(lbest == BARE, 255, lbest)
    L = np.full((TEX, TEX), 255, np.uint8); L[cov] = np.clip(lbest, 0, 255)
    L = mode_filter(L, cov)
    pad = L.copy()
    for _ in range(10):
        grow = cv2.dilate(np.where(pad == 255, 0, pad.astype(int) + 1).astype(np.uint8), np.ones((3, 3))).astype(int) - 1
        pad = np.where((pad == 255) & (grow >= 0) & ~cov, grow, pad).astype(np.uint8)
    # Normal map from the painted height, glTF convention (+x along u, +y up = against v).
    texel_m = np.sqrt(1.9 / cov.sum())  # metres per texel (body area about 1.9 m²)
    relief = 0.0015                     # metres of relief for a full luminance step
    gxh = cv2.Sobel(Hh, cv2.CV_64F, 1, 0, ksize=3) / 8
    gyh = cv2.Sobel(Hh, cv2.CV_64F, 0, 1, ksize=3) / 8
    n = np.stack([-gxh * relief / texel_m, gyh * relief / texel_m, np.ones_like(Hh)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    nmap = np.clip((n * 0.5 + 0.5) * 255, 0, 255).astype(np.uint8)
    cv2.imwrite(os.path.join(outdir, 'albedo.webp'), np.clip(A, 0, 255).astype(np.uint8), [cv2.IMWRITE_WEBP_QUALITY, 90])
    cv2.imwrite(os.path.join(outdir, 'normal.webp'), nmap[..., ::-1], [cv2.IMWRITE_WEBP_QUALITY, 92])
    cv2.imwrite(os.path.join(outdir, 'label.png'), pad)
    # The model: the base mesh (the page and glb.py subdivide it).
    b64 = lambda a: base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
    q8 = lambda a: np.round(np.clip(a, 0, 1) * 255).astype(np.uint8)
    wq = np.round(mdl['sw'] * 255).astype(np.int32)
    wq[:, 0] += 255 - wq.sum(1)
    assert len(mdl['pos']) < 65536
    data = {k: mdl['meta'][k] for k in ('bones', 'extra', 'muscles', 'atlas', 'cats')}
    data.update({
        'version': 5, 'painted': True, 'nv': len(mdl['pos']), 'nt': len(mdl['tri']),
        'pos': b64(mdl['pos'].astype('<f4')), 'nrm': b64(np.round(mdl['nrm'] * 127).astype(np.int8)),
        'uv': b64(np.round(mdl['uv'] * 65535).astype('<u2')), 'orig': b64(mdl['orig'].astype('<u2')),
        'skinIndex': b64(mdl['si'].astype(np.uint8)), 'skinWeight': b64(wq.astype(np.uint8)),
        'index': b64(mdl['tri'].astype('<u2')), 'mid': b64(mdl['gid'].astype('<u2')),
        'amp': b64(q8(mdl['amp'])), 'ao': b64(q8(mdl['ao'])),
    })
    json.dump(data, open(os.path.join(outdir, 'model.json'), 'w'))
    print('model KB', os.path.getsize(os.path.join(outdir, 'model.json')) // 1024)


if __name__ == '__main__':
    if sys.argv[1] == 'views':
        views(*sys.argv[2:7])
    elif sys.argv[1] == 'build':
        build(*sys.argv[2:6])
    else:
        raise SystemExit(__doc__)
