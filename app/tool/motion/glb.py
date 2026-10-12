"""Packs the gym model and its baked textures into one glTF 2.0 binary
(.glb), in the bind pose, with skeleton and skin, so it opens in Blender,
three.js, game engines, or Flutter.

    python3 -I tool/motion/glb.py /tmp/paint-out/model.json /tmp/paint-out /tmp/reparc-gym-model.glb

Painted model (paint.py build, the default): the mesh is subdivided once
exactly as the page does it, and carries the paint as its base colour, the
paint's relief as its normal map, and the muscle-part map (scene extras:
labelTexture; texel value = index into extras.atlas, 255 = none). Any glTF
viewer shows the painted body.

Atlas model (gym.py + bake.py):

Standard parts: positions, normals, tangents, texture coordinates, joints,
weights, a normal map, and a base colour. RepArc parts ride along:
_MUSCLE (muscle id, both sides) and _AMP (belly depth) attributes, the
muscle-id and detail textures (scene extras: idTexture, detailTexture),
and the muscle table (scene extras: muscles, atlas).
"""
import base64
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image


def png(path):
    buf = io.BytesIO()
    Image.open(path).save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def jpeg(path, q=92):
    buf = io.BytesIO()
    Image.open(path).convert('RGB').save(buf, 'JPEG', quality=q)
    return buf.getvalue()


def painted_arrays(data):
    """The page's surface: the base mesh subdivided once (paint.subdivide), welded normals."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import paint
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
    pos = dec('pos', '<f4').reshape(nv, 3).astype(np.float64)
    nrm = dec('nrm', np.int8).reshape(nv, 3) / 127.0
    nrm = nrm / np.linalg.norm(nrm, axis=1, keepdims=True)
    tri = dec('index', '<u2').reshape(-1, 3).astype(np.int64)
    orig = dec('orig', '<u2').astype(np.int64)
    uv = dec('uv', '<u2').reshape(nv, 2) / 65535.0
    si = dec('skinIndex', np.uint8).reshape(nv, 4).astype(np.int64)
    sw = dec('skinWeight', np.uint8).reshape(nv, 4) / 255.0
    nb = int(si.max()) + 1
    dense = np.zeros((nv, nb))
    np.add.at(dense, (np.repeat(np.arange(nv), 4), si.reshape(-1)), sw.reshape(-1))
    P, T, A, key, nkey = paint.subdivide(pos, nrm, tri, {'uv': uv, 'w': dense,
                                                          'amp': dec('amp', np.uint8)[:, None] / 255.0}, orig)
    uniq, _ = paint.edges(tri)
    mid = dec('mid', '<u2')
    mid = np.concatenate([mid, mid[uniq[:, 0]]])
    N = paint.normals(P, T, key, nkey)
    idx = np.argsort(-A['w'], axis=1)[:, :4]
    w4 = np.take_along_axis(A['w'], idx, 1)
    w4 /= np.maximum(w4.sum(1, keepdims=True), 1e-9)
    wq = np.round(w4 * 255).astype(np.int32)
    wq[:, 0] += 255 - wq.sum(1)
    arrays = [
        ('POSITION', P.astype('<f4'), 5126, 'VEC3', False),
        ('NORMAL', N.astype('<f4'), 5126, 'VEC3', False),
        ('TEXCOORD_0', np.round(A['uv'] * 65535).astype('<u2'), 5123, 'VEC2', True),
        ('JOINTS_0', idx.astype(np.uint8), 5121, 'VEC4', False),
        ('WEIGHTS_0', wq.astype(np.uint8), 5121, 'VEC4', True),
        ('_MUSCLE', mid.astype('<u2'), 5123, 'SCALAR', False),
        ('_AMP', np.round(A['amp'][:, 0] * 255).astype(np.uint8), 5121, 'SCALAR', True),
    ]
    return arrays, T.reshape(-1).astype('<u4')


def main(model, texdir, out):
    data = json.load(open(model))
    painted = bool(data.get('painted'))
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
    if painted:
        arrays, idx = painted_arrays(data)
    else:
        arrays, idx = atlas_arrays(data, dec, nv)
    write(data, arrays, idx, texdir, out, painted)


def atlas_arrays(data, dec, nv):
    arrays = [
        ('POSITION', dec('pos', '<f4').reshape(nv, 3), 5126, 'VEC3', False),
        ('NORMAL', (dec('nrm', np.int8).reshape(nv, 3) / 127).astype('<f4'), 5126, 'VEC3', False),
        ('TANGENT', (dec('tangent', np.int8).reshape(nv, 4) / 127).astype('<f4'), 5126, 'VEC4', False),
        ('TEXCOORD_0', dec('uv', '<u2').reshape(nv, 2), 5123, 'VEC2', True),
        ('JOINTS_0', dec('skinIndex', np.uint8).reshape(nv, 4), 5121, 'VEC4', False),
        ('WEIGHTS_0', dec('skinWeight', np.uint8).reshape(nv, 4), 5121, 'VEC4', True),
        ('_MUSCLE', dec('mid', '<u2'), 5123, 'SCALAR', False),
        ('_AMP', dec('amp', np.uint8), 5121, 'SCALAR', True),
    ]
    # Tangent w must be exactly ±1 in glTF.
    t = arrays[2][1]; t[:, 3] = np.sign(t[:, 3]); t[:, :3] /= np.linalg.norm(t[:, :3], axis=1, keepdims=True) + 1e-9
    return arrays, dec('index', '<u4')


def write(data, arrays, idx, texdir, out, painted):
    bones = data['bones']
    bpos = {b['name']: np.array(b['pos']) for b in bones}
    blob = bytearray(); views = []; accs = []

    def view(raw, target=None):
        while len(blob) % 4:
            blob.append(0)
        v = {'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(raw)}
        if target:
            v['target'] = target
        blob.extend(raw); views.append(v)
        return len(views) - 1

    def acc(arr, comp, typ, norm, target=None, minmax=False):
        a = {'bufferView': view(np.ascontiguousarray(arr).tobytes(), target), 'componentType': comp, 'count': int(len(arr)), 'type': typ}
        if norm:
            a['normalized'] = True
        if minmax:
            a['min'] = arr.min(0).tolist(); a['max'] = arr.max(0).tolist()
        accs.append(a)
        return len(accs) - 1

    attrs = {k: acc(a, c, ty, n, 34962, k == 'POSITION') for k, a, c, ty, n in arrays}
    ind = acc(idx, 5125, 'SCALAR', False, 34963)
    ibm = np.zeros((len(bones), 16), '<f4')
    for i, b in enumerate(bones):
        m = np.eye(4); m[:3, 3] = -bpos[b['name']]; ibm[i] = m.T.reshape(-1)
    ibm_acc = acc(ibm, 5126, 'MAT4', False)
    if painted:
        images = [{'mimeType': 'image/jpeg', 'bufferView': view(jpeg(os.path.join(texdir, 'albedo.webp'))), 'name': 'paint'},
                  {'mimeType': 'image/jpeg', 'bufferView': view(jpeg(os.path.join(texdir, 'normal.webp'), 95)), 'name': 'relief'},
                  {'mimeType': 'image/png', 'bufferView': view(png(os.path.join(texdir, 'label.png'))), 'name': 'muscle_parts'}]
        material = {'name': 'painted anatomy', 'normalTexture': {'index': 1},
                    'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'metallicFactor': 0, 'roughnessFactor': 0.72}}
        extras = {'labelTexture': 2}
    else:
        images = [{'mimeType': 'image/png', 'bufferView': view(png(os.path.join(texdir, f))), 'name': f.split('.')[0]} for f in ('normal.webp', 'detail.webp', 'id.png')]
        material = {'name': 'anatomy', 'normalTexture': {'index': 0},
                    'pbrMetallicRoughness': {'baseColorFactor': [0.72, 0.71, 0.69, 1], 'metallicFactor': 0, 'roughnessFactor': 0.6}}
        extras = {'detailTexture': 1, 'idTexture': 2}
    nodes = [{'name': 'RepArc gym model', 'mesh': 0, 'skin': 0}]
    for b in bones:
        tr = bpos[b['name']] - (bpos[b['parent']] if b['parent'] else 0)
        nodes.append({'name': b['name'], 'translation': [float(x) for x in tr]})
    for i, b in enumerate(bones):
        kids = [j + 1 for j, c in enumerate(bones) if c['parent'] == b['name']]
        if kids:
            nodes[i + 1]['children'] = kids
    gl = {
        'asset': {'version': '2.0', 'generator': 'RepArc tool/motion/glb.py', 'copyright': 'Body: MakeHuman CC0. Muscle atlas, painting and textures: RepArc.'},
        'scene': 0,
        'scenes': [{'nodes': [0, 1], 'extras': {'muscles': data['muscles'], 'atlas': data['atlas'], 'cats': data['cats'], **extras}}],
        'nodes': nodes,
        'meshes': [{'name': 'body', 'primitives': [{'attributes': attrs, 'indices': ind, 'material': 0}]}],
        'materials': [material],
        'samplers': [{'magFilter': 9729, 'minFilter': 9987}, {'magFilter': 9728, 'minFilter': 9728}],
        'images': images,
        'textures': [{'source': 0, 'sampler': 0}, {'source': 1, 'sampler': 0}, {'source': 2, 'sampler': 1}],
        'skins': [{'joints': list(range(1, len(bones) + 1)), 'inverseBindMatrices': ibm_acc, 'skeleton': 1}],
        'accessors': accs, 'bufferViews': views, 'buffers': [{'byteLength': len(blob)}],
    }
    js = json.dumps(gl, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    while len(blob) % 4:
        blob.append(0)
    with open(out, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack('<II', len(blob), 0x004E4942)); f.write(blob)
    print('glb KB', os.path.getsize(out) // 1024, '->', out)


if __name__ == '__main__':
    main(*sys.argv[1:4])
