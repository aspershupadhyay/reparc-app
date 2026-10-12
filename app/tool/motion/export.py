"""Exports the realistic body with a skeleton, skin weights, and muscle
fibre directions for the three.js Motion Lab (see README.md).

    python3 -I tool/motion/export.py <makehuman>/makehuman/data /tmp/body.json

Same mesh as app/assets/body/body.bin (tool/body/build.py): MakeHuman's
CC0 base mesh, shaped and posed the same way, with the same muscle regions.
MakeHuman's 163 bones are merged into 54: the trunk, limbs, a two-part
forearm (so it can twist), and three bones for each finger.
"""
import base64, json, os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'body'))
import build, mh, muscles, pose, refine as R

DATA = sys.argv[1]
OUT = sys.argv[2]

BONES = [  # name, parent, joint key (head of first MH bone)
 ('hips', None, 'root____head'),
 ('spine', 'hips', 'spine04____head'),
 ('chest', 'spine', 'spine02____head'),
 ('neck', 'chest', 'neck01____head'),
 ('head', 'neck', 'head____head'),
]
for s in 'LR':
    BONES += [
     (f'clav{s}', 'chest', f'clavicle.{s}____head'),
     (f'uarm{s}', f'clav{s}', f'upperarm01.{s}____head'),
     (f'farm{s}', f'uarm{s}', f'lowerarm01.{s}____head'),
     (f'farm2{s}', f'farm{s}', f'lowerarm02.{s}____head'),
     (f'hand{s}', f'farm2{s}', f'wrist.{s}____head'),
     (f'thigh{s}', 'hips', f'upperleg01.{s}____head'),
     (f'shin{s}', f'thigh{s}', f'lowerleg01.{s}____head'),
     (f'foot{s}', f'shin{s}', f'foot.{s}____head'),
    ]
    for n in range(1, 6):
        for k in range(1, 4):
            BONES.append((f'f{n}{k}{s}', f'hand{s}' if k == 1 else f'f{n}{k - 1}{s}', f'finger{n}-{k}.{s}____head'))
MAP = {'root':'hips','pelvis.L':'hips','pelvis.R':'hips','spine05':'hips','spine04':'spine','spine03':'spine',
       'spine02':'chest','spine01':'chest','breast.L':'chest','breast.R':'chest',
       'neck01':'neck','neck02':'neck','neck03':'neck','head':'head'}
for s in 'LR':
    MAP.update({f'clavicle.{s}':f'clav{s}', f'shoulder01.{s}':f'clav{s}', f'upperarm01.{s}':f'uarm{s}', f'upperarm02.{s}':f'uarm{s}',
      f'lowerarm01.{s}':f'farm{s}', f'lowerarm02.{s}':f'farm2{s}', f'wrist.{s}':f'hand{s}',
      **{f'metacarpal{m}.{s}': f'hand{s}' for m in range(1, 5)},
      **{f'finger{n}-{k}.{s}': f'f{n}{k}{s}' for n in range(1, 6) for k in range(1, 4)}, f'upperleg01.{s}':f'thigh{s}',
      f'upperleg02.{s}':f'thigh{s}', f'lowerleg01.{s}':f'shin{s}', f'lowerleg02.{s}':f'shin{s}', f'foot.{s}':f'foot{s}'})
BI = {b[0]: i for i, b in enumerate(BONES)}

base = mh.Base(DATA)
def reduced(bone):
    while bone not in MAP:
        bone = base.bones[bone]['parent']
    return MAP[bone]

# Same steps as build.body, keeping the weights.
v = mh.shaped(base, build.MUSCLE, build.WEIGHT, build.PROPORTIONS)
v = pose.arms_down(base, v, build.UPPER_ARM_OUT, build.FOREARM_OUT, build.FOREARM_FORWARD)
quads = base.body_quads()
used = np.array(sorted({i for f in quads for i in f}))
remap = -np.ones(len(v), dtype=np.int64); remap[used] = np.arange(len(used))
joints = {name: base.joint(v, name) for name in base.joint_verts}
lo, hi = v[used, 1].min(), v[used, 1].max()
s = build.HEIGHT_M / (hi - lo)
hip = (joints['upperleg01.L____head'] + joints['upperleg01.R____head']) / 2
origin = np.array([0.0, lo, hip[2]])
pos = (v[used] - origin) * s
joints = {k: (j - origin) * s for k, j in joints.items()}
quads = [[int(remap[i]) for i in q] for q in quads]
weights = {b: [(remap[i], w) for i, w in pairs if remap[i] >= 0] for b, pairs in base.weights.items()}
seg = muscles.segments(len(pos), weights)
W = np.zeros((len(pos), len(BONES)))
for b, pairs in weights.items():
    k = BI[reduced(b)]
    for i, w in pairs:
        W[i, k] += w

# Refine, tracking each new point's parents so weights follow.
nrm0 = build.normals(pos, build.triangulate(quads, pos))
def refine_with_parents(pos, nrm, quads, seg, split):
    P = list(pos); S = list(seg); mids = {}; par = []
    def mid(a, b):
        key = (min(a, b), max(a, b))
        if key not in mids:
            P.append(R._phong((P[a] + P[b]) / 2, [P[a], P[b]], [nrm[a], nrm[b]])); mids[key] = len(P) - 1
            S.append(S[a] if S[a] == S[b] else S[a] if S[a] in split else S[b]); par.append([a, b])
        return mids[key]
    def centre(q):
        P.append(R._phong(np.mean([P[i] for i in q], axis=0), [P[i] for i in q], [nrm[i] for i in q]))
        segs = [S[i] for i in q]; S.append(max(set(segs), key=segs.count)); par.append(list(q))
        return len(P) - 1
    refined = [all(S[i] in split for i in q) or sum(S[i] in split for i in q) >= 3 for q in quads]
    for q, r in zip(quads, refined):
        if r:
            for k in range(4): mid(q[k], q[(k + 1) % 4])
    tris = []
    for q, r in zip(quads, refined):
        if r:
            c = centre(q)
            m = [mids[(min(q[k], q[(k + 1) % 4]), max(q[k], q[(k + 1) % 4]))] for k in range(4)]
            for k in range(4):
                a, b, d = q[k], m[k], m[k - 1]; tris += [(a, b, c), (a, c, d)]
            continue
        ring = []
        for k in range(4):
            a, b = q[k], q[(k + 1) % 4]; ring.append(a)
            key = (min(a, b), max(a, b))
            if key in mids: ring.append(mids[key])
        if len(ring) == 4:
            d02 = np.linalg.norm(P[q[0]] - P[q[2]]); d13 = np.linalg.norm(P[q[1]] - P[q[3]])
            tris += [(q[0], q[1], q[2]), (q[0], q[2], q[3])] if d02 <= d13 else [(q[0], q[1], q[3]), (q[1], q[2], q[3])]
        else:
            c = centre(q)
            for k in range(len(ring)): tris.append((ring[k], ring[(k + 1) % len(ring)], c))
    return np.array(P), np.array(S, dtype=object), np.array(tris, dtype=np.int64), par

pos2, seg2, tri, par = refine_with_parents(pos, nrm0, quads, seg, build.REFINE)
# Sanity: same as the app's refine.
p_ref, _, t_ref = R.refine(pos, nrm0, quads, seg, build.REFINE)
assert len(p_ref) == len(pos2) and (t_ref == tri).all()
Wl = list(W)
for ps in par:
    Wl.append(np.mean([Wl[i] for i in ps], axis=0))
W = np.array(Wl)
pos = pos2
nrm = build.normals(pos, tri)
label, mw, groove = muscles.label(pos, nrm, tri, joints, seg2)
ao = muscles.occlusion(pos, nrm, tri)

# Muscle fibre directions, for the striations the page draws. Rules follow
# anatomy: limb muscles run along the bone, the chest fans to the upper
# arm, the delts converge on their insertion, abs run up and down, and the
# external obliques run down and in.
J = lambda k: np.array(joints[k])
fib = np.zeros_like(pos)
def unit(a): return a / np.maximum(np.linalg.norm(a, axis=-1, keepdims=True), 1e-9)
N = muscles.NAMES
side = np.where(pos[:, 0] >= 0, 'L', 'R')
for i in range(len(pos)):
    l = label[i]
    if l < 0:
        continue
    m, s = N[l], side[i]
    sx = 1.0 if s == 'L' else -1.0
    sh, el, wr = J(f'upperarm01.{s}____head'), J(f'lowerarm01.{s}____head'), J(f'wrist.{s}____head')
    hp, kn, an = J(f'upperleg01.{s}____head'), J(f'lowerleg01.{s}____head'), J(f'foot.{s}____head')
    p = pos[i]
    if m in ('upperChest', 'chest', 'lowerChest'): d = sh + (el - sh) * 0.15 - p
    elif m in ('frontDelts', 'sideDelts', 'rearDelts'): d = sh + (el - sh) * 0.45 - p
    elif m in ('biceps', 'triceps'): d = el - sh
    elif m == 'forearms': d = wr - el
    elif m == 'lats': d = sh + (el - sh) * 0.2 - p
    elif m == 'traps': d = sh - p
    elif m == 'upperBack': d = sh - p; d[1] *= 0.3
    elif m in ('lowerBack', 'abs', 'lowerAbs'): d = np.array([0.0, 1.0, 0.0])
    elif m == 'obliques': d = np.array([-0.7 * sx, -0.75, 0.15])
    elif m == 'glutes': d = np.array([0.9 * sx, -0.55, 0.0])
    elif m == 'abductors': d = hp + np.array([0.07 * sx, -0.04, 0.0]) - p
    elif m in ('quads', 'hamstrings', 'adductors'): d = kn - hp
    elif m == 'calves': d = an - kn
    else: d = np.array([0.0, 1.0, 0.0])
    fib[i] = d
fib = unit(fib)

# Top 4 influences, quantised.
idx = np.argsort(-W, axis=1)[:, :4]
w4 = np.take_along_axis(W, idx, 1)
w4 = w4 / np.maximum(w4.sum(1, keepdims=True), 1e-9)
wq = np.round(w4 * 255).astype(np.int32)
wq[:, 0] += 255 - wq.sum(1)
nohit = W.sum(1) == 0
print('verts', len(pos), 'tris', len(tri), 'unweighted', nohit.sum())

def b64(a): return base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
out = {
 'bones': [{'name': n, 'parent': p, 'pos': [round(float(x), 5) for x in joints[j]]} for n, p, j in BONES],
 'extra': {k: [round(float(x), 5) for x in joints[k]] for k in ['wrist.L____tail', 'wrist.R____tail', 'foot.L____tail', 'foot.R____tail', 'head____tail', 'spine01____head', 'neck01____head'] + [f'finger{n}-3.{s}____tail' for n in range(1, 6) for s in 'LR']},
 'muscles': muscles.NAMES,
 'nv': len(pos), 'nt': len(tri),
 'pos': b64(pos.astype('<f4')),
 'nrm': b64(np.round(nrm * 127).astype(np.int8)),
 'skinIndex': b64(idx.astype(np.uint8)),
 'skinWeight': b64(wq.astype(np.uint8)),
 'label': b64(label.astype(np.int8)),
 'mweight': b64(np.round(np.clip(mw, 0, 1) * 255).astype(np.uint8)),
 'groove': b64(np.round(np.clip(groove, 0, 1) * 255).astype(np.uint8)),
 'fiber': b64(np.round(fib * 127).astype(np.int8)),
 'ao': b64(np.round(np.clip(ao, 0, 1) * 255).astype(np.uint8)),
 'index': b64(tri.astype('<u2')),
}
json.dump(out, open(OUT, 'w'))
print('json KB', os.path.getsize(OUT) // 1024)
