"""Builds the RepArc gym model from the rigged base body (export.py with
BASE_CACHE): subdivides the mesh, lays the muscle atlas on it, carves each
muscle as a rounded belly with grooves between them, and writes one JSON
file the Motion Lab page reads.

    BASE_CACHE=/tmp/base.npz python3 -I tool/motion/export.py <mh data> /tmp/body.json
    python3 -I tool/motion/gym.py /tmp/base.npz /tmp/gym.json [/tmp/reparc-gym-model.glb]

Per vertex it stores the muscle, how far inside the muscle the point is
(the page uses it to keep volume when a muscle shortens), the fibre
direction, and a cavity term for shading.
"""
import base64
import json
import os
import sys

import numpy as np

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
sys.path.insert(0, os.path.join(os.path.dirname(here), 'body'))
import assign  # noqa: E402
import atlas  # noqa: E402
import muscles  # noqa: E402

GROOVE = 0.0032   # depth of the groove between muscles (m)
SKIN_SEGS = ('trunk', 'neck', 'upperarm', 'forearm', 'thigh', 'shin')


def normals(pos, tri):
    fn = np.cross(pos[tri[:, 1]] - pos[tri[:, 0]], pos[tri[:, 2]] - pos[tri[:, 0]])
    n = np.zeros_like(pos)
    for k in range(3):
        np.add.at(n, tri[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def subdivide(pos, nrm, tri, attrs):
    """Each triangle into four. New points sit on the curved surface through
    the corners (Phong); attributes in [attrs] are averaged."""
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e.sort(1)
    uniq, inv = np.unique(e, axis=0, return_inverse=True)
    a, b = uniq[:, 0], uniq[:, 1]
    m = (pos[a] + pos[b]) / 2
    proj = lambda q, p, n: q - ((q - p) * n).sum(1, keepdims=True) * n
    m = 0.25 * m + 0.75 * (proj(m, pos[a], nrm[a]) + proj(m, pos[b], nrm[b])) / 2
    n0 = len(pos)
    newpos = np.concatenate([pos, m])
    out = {k: np.concatenate([v, (v[a] + v[b]) / 2]) for k, v in attrs.items()}
    nt = len(tri)
    mab, mbc, mca = (inv[:nt] + n0, inv[nt:2 * nt] + n0, inv[2 * nt:] + n0)
    t0, t1, t2 = tri[:, 0], tri[:, 1], tri[:, 2]
    newtri = np.concatenate([np.stack([t0, mab, mca], 1), np.stack([mab, t1, mbc], 1), np.stack([mca, mbc, t2], 1), np.stack([mab, mbc, mca], 1)])
    return newpos, newtri, out


def neighbours(n, tri):
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    e = np.unique(e, axis=0)
    deg = np.bincount(e[:, 0], minlength=n)
    return e, deg


def smooth(val, e, deg, it=2):
    for _ in range(it):
        s = np.zeros_like(val)
        np.add.at(s, e[:, 0], val[e[:, 1]])
        val = 0.5 * val + 0.5 * s / np.maximum(deg, 1)[:, None] if val.ndim > 1 else 0.5 * val + 0.5 * s / np.maximum(deg, 1)
    return val


def main(base_path, out):
    d = np.load(base_path)
    J = {k: np.array(v) for k, v in json.loads(str(d['joints'])).items()}
    bones = json.loads(str(d['bones']))
    pos, tri, W, seg = d['pos'], d['tri'], d['W'], d['seg']
    segs = sorted(set(seg))
    segid = np.array([segs.index(s) for s in seg], float)
    nrm = normals(pos, tri)
    ao0 = muscles.occlusion(pos, nrm, tri, dirs=96)
    pos, tri, A = subdivide(pos, nrm, tri, {'W': W, 'seg': segid[:, None], 'ao': ao0[:, None]})
    W, ao = A['W'], A['ao'][:, 0]
    seg = np.array([segs[int(round(i))] if abs(i - round(i)) < 1e-6 else None for i in A['seg'][:, 0]], dtype=object)
    # Midpoints between two segments: take either neighbour's segment.
    e, deg = neighbours(len(pos), tri)
    for _ in range(2):
        miss = np.array([s is None for s in seg])
        if not miss.any():
            break
        for v, w in e[miss[e[:, 0]]]:
            if seg[v] is None and seg[w] is not None:
                seg[v] = seg[w]
    nrm = normals(pos, tri)
    print('subdivided:', len(pos), 'vertices', len(tri), 'triangles')

    mid, depth, fib, side, _, near_id = assign.assign(pos, seg, J)
    # Belly shape: rounded from the edge in to a plateau; grooves at edges.
    maxd = np.zeros(len(atlas.M))
    for i in range(len(atlas.M)):
        sel = mid == i
        if sel.any():
            maxd[i] = depth[sel].max()
    H = np.array([m['height'] for m in atlas.M]) * 1.35
    tendon = np.array([m['kind'] == 'tendon' for m in atlas.M])
    off = np.zeros(len(pos))
    amp = np.zeros(len(pos))
    edge = np.zeros(len(pos))
    ins = mid >= 0
    R = np.clip(maxd[mid[ins]] * 0.75, 0.006, 0.03)
    s = np.clip(depth[ins] / R, 0, 1)
    belly = s * (2 - s)
    off[ins] = H[mid[ins]] * belly - GROOVE * (1 - s) ** 2 * np.where(tendon[mid[ins]], 0.5, 1.0)
    amp[ins] = np.where(tendon[mid[ins]], 0, belly)
    edge[ins] = (1 - s) ** 2
    out_d = -depth  # outside distance for points not in a muscle
    near = (~ins) & np.isin(seg, SKIN_SEGS)
    off[near] = -GROOVE * np.exp(-np.clip(out_d[near], 0, None) / 0.005)
    edge[near] = np.exp(-np.clip(out_d[near], 0, None) / 0.005)
    off = smooth(off, e, deg, 1)
    pos = pos + nrm * off[:, None]
    nrm = normals(pos, tri)
    # Cavity: concave points darken, convex ones lighten (mean curvature).
    s_ = np.zeros_like(pos); np.add.at(s_, e[:, 0], pos[e[:, 1]])
    lap = s_ / np.maximum(deg, 1)[:, None] - pos
    el = np.linalg.norm(pos[e[:, 0]] - pos[e[:, 1]], axis=1)
    elen = np.bincount(e[:, 0], el, len(pos)) / np.maximum(deg, 1)
    curv = (lap * nrm).sum(1) / np.maximum(elen ** 2, 1e-8)
    cav = smooth(np.clip(curv * 0.004, -1, 1), e, deg, 1)

    # Muscle table, both sides. Global id = 2 * atlas index + (0 left, 1 right).
    def mirror(att):
        bone, key, off_ = att
        return (bone[:-1] + 'R' if bone.endswith('L') else bone, key.replace('.L_', '.R_'), (-off_[0], off_[1], off_[2]))
    table = []
    for m in atlas.M:
        for sd in 'LR':
            at = m['attach']
            if at and sd == 'R':
                at = tuple(mirror(a) for a in at)
            table.append({'name': m['name'], 'side': sd, 'cat': m['cat'], 'kind': m['kind'], 'height': m['height'],
                          'attach': [{'bone': b, 'at': [round(float(x), 5) for x in (J[k] + np.array(o))]} for b, k, o in at] if at else None})
    # Every point near a muscle takes that muscle's id (colour); 'edge' and
    # 'amp' say whether it is in the belly or in the groove beside it.
    has = near_id >= 0
    gid = np.where(has & (ins | near), near_id * 2 + (side == 'R'), 65535).astype(np.uint16)

    idx = np.argsort(-W, axis=1)[:, :4]
    w4 = np.take_along_axis(W, idx, 1)
    w4 /= np.maximum(w4.sum(1, keepdims=True), 1e-9)
    wq = np.round(w4 * 255).astype(np.int32); wq[:, 0] += 255 - wq.sum(1)
    b64 = lambda a: base64.b64encode(np.ascontiguousarray(a).tobytes()).decode()
    q8 = lambda a: np.round(np.clip(a, 0, 1) * 255).astype(np.uint8)
    data = {
        'version': 3, 'nv': len(pos), 'nt': len(tri), 'bones': [{'name': n, 'parent': p, 'pos': [round(float(x), 5) for x in J[k]]} for n, p, k in bones],
        'extra': {k: [round(float(x), 5) for x in J[k]] for k in ['wrist.L____tail', 'wrist.R____tail', 'foot.L____tail', 'foot.R____tail', 'head____tail', 'spine01____head', 'neck01____head'] + [f'finger{n}-3.{s}____tail' for n in range(1, 6) for s in 'LR']},
        'muscles': table, 'cats': muscles.NAMES,
        'pos': b64(pos.astype('<f4')), 'nrm': b64(np.round(nrm * 127).astype(np.int8)),
        'skinIndex': b64(idx.astype(np.uint8)), 'skinWeight': b64(wq.astype(np.uint8)),
        'index': b64(tri.astype('<u4')), 'mid': b64(gid.astype('<u2')),
        'amp': b64(q8(amp)), 'edge': b64(q8(edge)), 'ao': b64(q8(ao)), 'cav': b64(np.round(cav * 127).astype(np.int8)),
        'fiber': b64(np.round(fib * 127).astype(np.int8)),
    }
    json.dump(data, open(out, 'w'))
    print('muscle points:', ins.mean().round(3), 'json KB', os.path.getsize(out) // 1024)
    if len(sys.argv) > 3:
        write_glb(data, sys.argv[3])




def write_glb(data, path):
    """The same model as a standard glTF 2.0 binary, in the bind pose, with
    its skeleton and skin, so it opens in Blender, three.js, or a game
    engine. Muscle data rides along as custom attributes (_MUSCLE, _AMP,
    _EDGE, _FIBER) and the muscle table sits in the scene's extras."""
    import struct
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
    pos = dec('pos', '<f4').reshape(nv, 3)
    arrays = [
        ('POSITION', pos.astype('<f4'), 5126, 'VEC3', False),
        ('NORMAL', (dec('nrm', np.int8).reshape(nv, 3) / 127).astype('<f4'), 5126, 'VEC3', False),
        ('JOINTS_0', dec('skinIndex', np.uint8).reshape(nv, 4), 5121, 'VEC4', False),
        ('WEIGHTS_0', dec('skinWeight', np.uint8).reshape(nv, 4), 5121, 'VEC4', True),
        ('_MUSCLE', dec('mid', '<u2').astype('<u2'), 5123, 'SCALAR', False),
        ('_AMP', dec('amp', np.uint8), 5121, 'SCALAR', True),
        ('_EDGE', dec('edge', np.uint8), 5121, 'SCALAR', True),
        ('_FIBER', dec('fiber', np.int8).reshape(nv, 3), 5120, 'VEC3', True),
    ]
    idx = dec('index', '<u4')
    bones = data['bones']
    names = [b['name'] for b in bones]
    bpos = {b['name']: np.array(b['pos']) for b in bones}
    blob = bytearray(); views = []; accs = []
    def add(arr, comp, typ, norm, target=None, minmax=False):
        while len(blob) % 4: blob.append(0)
        off = len(blob); raw = np.ascontiguousarray(arr).tobytes(); blob.extend(raw)
        v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(raw)}
        if target: v['target'] = target
        views.append(v)
        a = {'bufferView': len(views) - 1, 'componentType': comp, 'count': int(len(arr)), 'type': typ}
        if norm: a['normalized'] = True
        if minmax: a['min'] = arr.min(0).tolist(); a['max'] = arr.max(0).tolist()
        accs.append(a); return len(accs) - 1
    attrs = {k: add(a, c, t, n, 34962, k == 'POSITION') for k, a, c, t, n in arrays}
    ind = add(idx, 5125, 'SCALAR', False, 34963)
    ibm = np.zeros((len(bones), 16), '<f4')
    for i, b in enumerate(bones):
        m = np.eye(4); m[:3, 3] = -bpos[b['name']]; ibm[i] = m.T.reshape(-1)
    ibm_acc = add(ibm, 5126, 'MAT4', False)
    nodes = [{'name': 'RepArc gym model', 'mesh': 0, 'skin': 0}]
    for b in bones:
        t = bpos[b['name']] - (bpos[b['parent']] if b['parent'] else 0)
        nodes.append({'name': b['name'], 'translation': [float(x) for x in t]})
    for i, b in enumerate(bones):
        kids = [j + 1 for j, c in enumerate(bones) if c['parent'] == b['name']]
        if kids: nodes[i + 1]['children'] = kids
    gl = {
        'asset': {'version': '2.0', 'generator': 'RepArc tool/motion/gym.py', 'copyright': 'Body: MakeHuman CC0. Muscle atlas: RepArc.'},
        'scene': 0, 'scenes': [{'nodes': [0, 1], 'extras': {'muscles': data['muscles'], 'cats': data['cats']}}],
        'nodes': nodes,
        'meshes': [{'name': 'body', 'primitives': [{'attributes': attrs, 'indices': ind, 'material': 0}]}],
        'materials': [{'name': 'anatomy', 'pbrMetallicRoughness': {'baseColorFactor': [0.72, 0.71, 0.69, 1], 'metallicFactor': 0, 'roughnessFactor': 0.6}}],
        'skins': [{'joints': list(range(1, len(bones) + 1)), 'inverseBindMatrices': ibm_acc, 'skeleton': 1}],
        'accessors': accs, 'bufferViews': views, 'buffers': [{'byteLength': len(blob)}],
    }
    js = json.dumps(gl, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    while len(blob) % 4: blob.append(0)
    with open(path, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack('<II', len(blob), 0x004E4942)); f.write(blob)
    print('glb KB', os.path.getsize(path) // 1024, '->', path)


if __name__ == '__main__':
    main(*sys.argv[1:3])
