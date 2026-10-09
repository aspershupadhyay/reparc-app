"""Muscle regions, grooves, and baked soft shadow for the body map mesh."""

import numpy as np

# Same order as mapMuscles in body_model.dart.
NAMES = [
    "upperChest",
    "chest",
    "lowerChest",
    "lats",
    "upperBack",
    "traps",
    "lowerBack",
    "frontDelts",
    "sideDelts",
    "rearDelts",
    "biceps",
    "triceps",
    "forearms",
    "quads",
    "hamstrings",
    "calves",
    "adductors",
    "glutes",
    "abductors",
    "abs",
    "lowerAbs",
    "obliques",
]
ID = {n: i for i, n in enumerate(NAMES)}


# Body segments, from the skeleton's skin weights.
SEGMENTS = {
    "trunk": ("spine", "pelvis", "root", "breast", "clavicle", "shoulder01"),
    "neck": ("neck",),
    "head": ("head", "jaw", "eye", "oculi", "orbicularis", "oris", "levator", "risorius", "special", "temporalis", "tongue"),
    "upperarm": ("upperarm",),
    "forearm": ("lowerarm",),
    "hand": ("wrist", "metacarpal", "finger"),
    "thigh": ("upperleg",),
    "shin": ("lowerleg",),
    "foot": ("foot", "toe"),
}


def segments(n, weights):
    """The segment each vertex mostly moves with."""
    names = list(SEGMENTS)
    score = np.zeros((n, len(names)))
    for bone, pairs in weights.items():
        k = next(i for i, s in enumerate(names) if bone.startswith(SEGMENTS[s]))
        for v, w in pairs:
            score[v, k] += w
    return np.array(names, dtype=object)[np.argmax(score, 1)]


def _limb(pos, side, top, bottom):
    """Limb coordinates: t from 0 at [top] to 1 at [bottom], and the angle
    around the limb in degrees: 0 front, 90 outer side, 180 back, -90
    inner side."""
    axis = bottom - top
    length = np.linalg.norm(axis)
    axis = axis / length
    rel = pos - top
    t = (rel @ axis) / length
    radial = rel - np.outer(rel @ axis, axis)
    fwd = np.array([0.0, 0.0, 1.0])
    fwd = fwd - (fwd @ axis) * axis
    fwd /= np.linalg.norm(fwd)
    out = np.cross(axis, fwd) * -side
    out = out if out[0] * side > 0 else -out
    ang = np.degrees(np.arctan2(radial @ out, radial @ fwd))
    return t, ang


def _smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def regions(pos, nrm, joints, seg):
    """Muscle and sub-region for each vertex. Sub-regions split a muscle
    into its heads or blocks (the six-pack, the quad heads), so their
    seams show as grooves while a tap still picks the whole muscle.
    Returns (muscle id or -1, sub-region id or -1)."""
    n = len(pos)
    ax = np.abs(pos[:, 0])
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]
    side = np.where(x >= 0, 1.0, -1.0)
    J = lambda name: joints[name]  # noqa: E731

    # Trunk angle: 0 front, 90 side, 180 back, around the trunk's middle
    # at each height.
    trunk = seg == "trunk"
    bins = np.round(y / 0.01).astype(int)
    zc = np.zeros(n)
    for b in np.unique(bins[trunk]):
        s = trunk & (bins == b)
        zc[bins == b] = (z[s].min() + z[s].max()) / 2
    # Below the trunk (the thighs), keep the hips' middle.
    low = bins < bins[trunk].min()
    zc[low] = zc[trunk & (bins == bins[trunk].min())].mean()
    phi = np.degrees(np.arctan2(ax, z - zc))

    lab = -np.ones(n, dtype=np.int64)
    sub = -np.ones(n, dtype=np.int64)
    subs = {}

    def put(mask, muscle, part):
        key = (muscle, part)
        if key not in subs:
            subs[key] = len(subs)
        free = mask & (lab < 0)
        lab[free] = ID[muscle]
        sub[free] = subs[key]

    # ---- Limb coordinates (left and right picked per vertex).
    def limb(top, bottom):
        t = np.zeros(n)
        a = np.zeros(n)
        for s, tag in ((1.0, "L"), (-1.0, "R")):
            m = side == s
            tt, aa = _limb(pos[m], s, J(f"{top}.{tag}____head"), J(f"{bottom}.{tag}____head"))
            t[m], a[m] = tt, aa
        return t, a

    ta, aa = limb("upperarm01", "lowerarm01")
    tf, af = limb("lowerarm01", "wrist")
    tt, at = limb("upperleg01", "lowerleg01")
    ts, as_ = limb("lowerleg01", "foot")

    up_arm = seg == "upperarm"
    fore = seg == "forearm"
    thigh = seg == "thigh"
    shin = seg == "shin"
    neck = seg == "neck"
    front = phi < 80
    back = phi > 100

    # ---- Shoulders: the deltoid caps the joint and comes to a point on
    # the outer arm, a little under halfway down.
    cap = (trunk | up_arm) & (ax > 0.158) & (y > 1.33)
    delt_len = np.interp(np.abs(aa), [0, 40, 90, 140, 180], [0.20, 0.30, 0.44, 0.30, 0.17])
    on_arm = up_arm & (ta < delt_len) & (aa > -40) & (aa < 215)
    on_arm |= up_arm & (ta < delt_len) & (aa < -150)
    delt = (cap & (y > 1.355 + 0.25 * np.clip(0.19 - ax, 0, 1))) | on_arm
    # Not the armpit, front or back.
    delt &= ~((aa < -45) & (aa > -150) & (ta > 0.05))
    head = np.where(np.abs(aa) < 52, "frontDelts", np.where(np.abs(aa) > 128, "rearDelts", "sideDelts"))
    for h in ("frontDelts", "sideDelts", "rearDelts"):
        put(delt & (head == h), h, h)

    # ---- Trapezius: a diamond from the skull down to the middle back,
    # out to the tip of each shoulder; also the slope of the shoulders
    # seen from the front.
    w_tr = np.interp(y, [1.13, 1.30, 1.40, 1.45, 1.49, 1.55, 1.60], [0.0, 0.060, 0.098, 0.150, 0.10, 0.06, 0.05])
    traps = (trunk | neck) & (y >= 1.13) & (ax < w_tr) & (phi > 105 - np.clip((y - 1.44) * 1500, 0, 50))
    traps &= ~((y > 1.58) & (phi < 140))
    put(traps & (y > 1.40), "traps", "upper")
    put(traps & (y > 1.27), "traps", "middle")
    put(traps, "traps", "lower")

    # ---- Chest: the pectoral fan, from the breastbone and collarbone to
    # the upper arm. Upper, middle, and lower fibres by their angle to the
    # insertion.
    lower = 1.252 + np.clip(ax - 0.095, 0, None) * 0.95
    upper = 1.452 + 0.08 * np.clip(ax - 0.02, 0, 0.1)
    edge = 0.15 + (1.47 - y) * 0.42  # the groove with the front deltoid
    pec = trunk & front & (ax > 0.0) & (y > lower) & (y < upper) & (ax < edge) & (ax < 0.20)
    pec |= up_arm & (aa > -60) & (aa < 10) & (ta < 0.14) & (ta > -0.2) & (y > 1.33)
    fan = np.degrees(np.arctan2(y - 1.372, 0.195 - ax))
    put(pec & (fan > 9), "upperChest", "clav")
    put(pec & (fan > -17), "chest", "mid")
    put(pec, "lowerChest", "low")

    # ---- Abs: rectus abdominis in blocks. The top two rows are abs,
    # the rest lower abs.
    rect_w = np.interp(y, [0.95, 1.00, 1.10, 1.20, 1.26], [0.042, 0.058, 0.072, 0.080, 0.084])
    rect = trunk & (phi < 55) & (ax < rect_w) & (y > 0.955) & (y < 1.262)
    rows = [1.262, 1.205, 1.152, 1.098, 0.955]
    names = ["abs", "abs", "lowerAbs", "lowerAbs"]
    for k in range(4):
        put(rect & (y <= rows[k]) & (y > rows[k + 1]), names[k], f"row{k}")

    # ---- Obliques and serratus on the side of the waist and ribs.
    lat_bottom = 1.0 + np.clip(ax - 0.05, 0, None) * 0.55
    lat_front = np.interp(y, [1.0, 1.10, 1.20, 1.30], [112, 100, 92, 86])
    lats = trunk & (phi > lat_front) & (y > lat_bottom) & (y < 1.34) & (ax >= 0.045)
    lats &= ~((phi > 100) & (y > 1.27) & (ax < 0.19))  # the shoulder blade
    put(lats, "lats", "lats")

    crest = 0.975 + np.clip(ax - 0.06, 0, None) * 0.75
    obl = trunk & (phi < 118) & (y > crest) & (y < 1.25)
    put(obl & (y > 1.17) & (phi > 62), "obliques", "serratus")
    put(obl, "obliques", "external")

    # ---- Back.
    put(trunk & back & (y > 1.27) & (y < 1.425) & (ax < 0.19), "upperBack", "scapula")
    erect = trunk & back & (ax < 0.052) & (y > 0.985) & (y < 1.24)
    put(erect, "lowerBack", "erectors")

    # ---- Hips: glutes behind, the outer hip on the side.
    fold = 0.80 + np.clip(ax - 0.03, 0, None) * 0.35
    glute_top = 0.985 + np.clip(ax - 0.02, 0, None) * 0.30
    hips = (trunk | thigh) & (y < glute_top)
    # The outer hip (gluteus medius and TFL) sits above and beside the
    # glute: its back edge leans back as it rises.
    hip_back = 104 + (y - 0.90) * 120
    put(hips & (y > fold) & (phi > hip_back), "glutes", "max")
    put(hips & (y > 0.87) & (phi > 72) & (y > crest - 0.06), "abductors", "medius")

    # ---- Thigh.
    th = thigh & (tt > 0.04) & (tt < 0.90)
    put(th & (at < -40) & (at > -135) & (tt < 0.55 + (at + 40) * 0.002), "adductors", "adductors")
    put(th & (at >= -25) & (at <= 28) & (tt > 0.10) & (tt < 0.84), "quads", "rectus")
    put(th & (at > 28) & (at < 112), "quads", "lateralis")
    put(th & (at >= -80) & (at < -25) & (tt > 0.40), "quads", "medialis")
    put(th & (at >= -80) & (at < -25), "quads", "sartorius")
    ham = th & ((at >= 112) | (at <= -125)) & (tt > 0.06) & (tt < 0.86)
    put(ham & (at >= 0), "hamstrings", "biceps")
    put(ham, "hamstrings", "semi")

    # ---- Calves: two heads of the gastrocnemius, soleus on the sides.
    sh = shin & (ts > 0.04) & (ts < 0.74)
    put(sh & (np.abs(as_) > 112) & (ts < 0.58) & (as_ > 0), "calves", "lateral")
    put(sh & (np.abs(as_) > 112) & (ts < 0.58), "calves", "medial")
    put(sh & (np.abs(as_) > 78) & (ts > 0.18), "calves", "soleus")

    # ---- Upper arm.
    ua = up_arm & (ta < 0.93)
    put(ua & (aa > -70) & (aa < 48) & (ta > 0.18), "biceps", "biceps")
    put(ua & (aa >= 48) & (aa < 100) & (ta > 0.45), "biceps", "brachialis")
    put(ua & ((aa >= 100) | (aa < -150)) & (aa > 0) & (ta > 0.1), "triceps", "lateral")
    put(ua & ((aa >= 100) | (aa < -110)) & (ta > 0.1), "triceps", "long")

    # ---- Forearm.
    fa = fore & (tf > 0.02) & (tf < 0.78)
    put(fa & (np.abs(af) < 70), "forearms", "flexors")
    put(fa & (af >= 70) & (af < 120) & (tf < 0.55), "forearms", "brachioradialis")
    put(fa, "forearms", "extensors")

    return lab, sub


def _edges(tri, pos):
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = np.unique(np.sort(e, 1), axis=0)
    length = np.linalg.norm(pos[e[:, 0]] - pos[e[:, 1]], axis=1)
    return e, length


def _distance_to(seed, edges, length, n, limit):
    """Distance along the surface from each vertex to the nearest [seed]
    vertex, up to [limit] metres (a few rounds of edge relaxation)."""
    d = np.where(seed, 0.0, np.inf)
    a, b = edges[:, 0], edges[:, 1]
    for _ in range(60):
        prev = d.copy()
        np.minimum.at(d, a, d[b] + length)
        np.minimum.at(d, b, d[a] + length)
        if np.array_equal(prev, d):
            break
    return np.minimum(d, limit)


def _smooth_labels(lab, sub, edges, n, rounds=2):
    """Majority vote among neighbours, to clean one-vertex specks and
    jagged steps along region edges."""
    for _ in range(rounds):
        nb = [[] for _ in range(n)]
        for a, b in edges:
            nb[a].append(b)
            nb[b].append(a)
        new_sub = sub.copy()
        new_lab = lab.copy()
        for v in range(n):
            vals, counts = np.unique(sub[nb[v]], return_counts=True)
            k = np.argmax(counts)
            if vals[k] != sub[v] and counts[k] > len(nb[v]) / 2:
                new_sub[v] = vals[k]
                new_lab[v] = lab[nb[v]][list(sub[nb[v]]).index(vals[k])]
        lab, sub = new_lab, new_sub
    return lab, sub


def label(pos, nrm, tri, joints, seg):
    """Muscle id per vertex (-1 for skin), how strongly it shows its
    colour, and the groove where it meets another muscle or head."""
    n = len(pos)
    lab, sub = regions(pos, nrm, joints, seg)
    edges, length = _edges(tri, pos)
    lab, sub = _smooth_labels(lab, sub, edges, n, rounds=1)
    # A vertex is on a seam when a neighbour is in a different sub-region.
    a, b = edges[:, 0], edges[:, 1]
    seam = np.zeros(n, dtype=bool)
    # Only where two muscles (or two heads) meet: bare skin gets no outline.
    diff = (sub[a] != sub[b]) & (sub[a] >= 0) & (sub[b] >= 0)
    seam[a[diff]] = True
    seam[b[diff]] = True
    to_seam = _distance_to(seam, edges, length, n, 0.05)
    to_skin = _distance_to(lab < 0, edges, length, n, 0.05)
    # Colour fades in over the first 2 cm from bare skin.
    weight = np.where(lab >= 0, _smooth(0.0, 0.022, to_skin), 0.0)
    # Grooves: dark on the seam, gone 1 cm away. Between muscles they are
    # deeper than between the heads of one muscle.
    same = np.zeros(n, dtype=bool)
    same_muscle = (lab[a] == lab[b]) & diff
    same[a[same_muscle]] = True
    same[b[same_muscle]] = True
    depth = np.where(same & ~_touches_other(lab, edges, n), 0.55, 1.0)
    groove = (1 - _smooth(0.0, 0.010, to_seam)) * depth
    return lab, weight, groove


def _touches_other(lab, edges, n):
    a, b = edges[:, 0], edges[:, 1]
    out = np.zeros(n, dtype=bool)
    d = (lab[a] != lab[b]) & (lab[a] >= 0) & (lab[b] >= 0)
    out[a[d]] = True
    out[b[d]] = True
    return out


def triangle_labels(label, tri):
    """A triangle takes the muscle most of its corners have."""
    a, b, c = label[tri[:, 0]], label[tri[:, 1]], label[tri[:, 2]]
    return np.where((a == b) | (a == c), a, np.where(b == c, b, np.maximum(np.maximum(a, b), c)))


def _directions(k):
    """[k] directions spread evenly over the sphere."""
    i = np.arange(k) + 0.5
    phi = np.arccos(1 - 2 * i / k)
    th = np.pi * (1 + 5**0.5) * i
    return np.stack([np.cos(th) * np.sin(phi), np.cos(phi), np.sin(th) * np.sin(phi)], 1)


def occlusion(pos, nrm, tri, dirs=160, res=320):
    """Ambient occlusion, 0 open to 1 closed in. For each direction, a
    depth map of the surface (dense surface samples splatted into a grid)
    tells which vertices that direction can see."""
    # Surface samples: corners, edge middles, and centres of triangles.
    a, b, c = pos[tri[:, 0]], pos[tri[:, 1]], pos[tri[:, 2]]
    samples = np.concatenate([pos, (a + b) / 2, (b + c) / 2, (c + a) / 2, (a + b + c) / 3])
    lo, hi = samples.min(0) - 0.02, samples.max(0) + 0.02
    centre = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    cell = 2 * radius / res
    seen = np.zeros(len(pos))
    total = np.zeros(len(pos))
    for d in _directions(dirs):
        up = np.array([0.0, 1.0, 0.0]) if abs(d[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
        u = np.cross(up, d)
        u /= np.linalg.norm(u)
        v = np.cross(d, u)

        def grid(p):
            q = p - centre
            return (
                np.clip(((q @ u) / cell + res / 2).astype(int), 0, res - 1),
                np.clip(((q @ v) / cell + res / 2).astype(int), 0, res - 1),
                q @ d,
            )

        gx, gy, gz = grid(samples)
        depth = np.full((res, res), -1e9)
        for ox in (-1, 0, 1):
            for oy in (-1, 0, 1):
                np.maximum.at(depth, (np.clip(gx + ox, 0, res - 1), np.clip(gy + oy, 0, res - 1)), gz)
        vx, vy, vz = grid(pos)
        facing = nrm @ d
        w = np.clip(facing, 0, 1)
        lit = vz >= depth[vx, vy] - 2.5 * cell
        seen += w * lit
        total += w
    return 1 - seen / np.maximum(total, 1e-9)


def anchors(pos, nrm, label, inner):
    """Tap targets: for each muscle, on each side of the body, the middle
    of the part that faces front, back, or out to the side. [inner] marks
    vertices well inside their muscle (no seam near), so a tap there lands
    on the muscle's own triangles."""
    out = []
    for m in range(len(NAMES)):
        for side in (1, -1):
            for d in ((0, 0, 1), (0, 0, -1), (side, 0, 0), (side, 0, 1), (side, 0, -1)):
                d = np.array(d, dtype=float) / np.linalg.norm(d)
                sel = (label == m) & (np.sign(pos[:, 0]) == side) & (nrm @ d > 0.55)
                if sel.sum() < 6:
                    continue
                c = pos[sel].mean(0)
                pick = sel & inner
                if pick.sum() == 0:
                    pick = sel
                idx = np.where(pick)[0]
                k = idx[np.argmin(np.linalg.norm(pos[idx] - c, axis=1))]
                if any(mm == m and np.linalg.norm(pp - pos[k]) < 0.03 for mm, pp, _ in out):
                    continue
                out.append((m, pos[k], nrm[k]))
    return out


PREVIEW_SKIN = np.array([0.345, 0.388, 0.420])
PREVIEW_MUSCLE = np.array([0.55, 0.62, 0.68])


def preview_colors(label, weight, groove, ao):
    """RGB plus a light factor per vertex: one clear colour per muscle,
    for checking regions by eye."""
    hues = np.array(
        [
            [0.95, 0.35, 0.35], [0.95, 0.65, 0.20], [0.95, 0.90, 0.30], [0.30, 0.80, 0.35],
            [0.25, 0.75, 0.90], [0.85, 0.40, 0.90], [0.95, 0.55, 0.70], [0.40, 0.45, 0.95],
            [0.20, 0.95, 0.75], [0.70, 0.95, 0.30], [0.95, 0.25, 0.60], [0.55, 0.30, 0.85],
            [0.98, 0.78, 0.55], [0.35, 0.60, 0.30], [0.80, 0.55, 0.35], [0.30, 0.45, 0.70],
            [0.60, 0.95, 0.95], [0.90, 0.20, 0.20], [0.55, 0.85, 0.55], [0.95, 0.95, 0.70],
            [0.65, 0.65, 0.20], [0.20, 0.55, 0.55],
        ]
    )
    base = np.tile(PREVIEW_SKIN, (len(label), 1))
    m = label >= 0
    base[m] = base[m] * (1 - weight[m, None]) + hues[label[m]] * weight[m, None]
    light = (1 - 0.6 * ao) * (1 - 0.45 * groove)
    return np.concatenate([base, light[:, None]], 1)
