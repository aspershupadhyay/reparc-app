"""Packs the gym model and its baked textures into one glTF 2.0 binary
(.glb), in the bind pose, with skeleton and skin, so it opens in Blender,
three.js, game engines, or Flutter.

    python3 -I tool/motion/glb.py /tmp/gym.json /tmp/gym-tex /tmp/reparc-gym-model.glb

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


def main(model, texdir, out):
    data = json.load(open(model))
    dec = lambda k, t: np.frombuffer(base64.b64decode(data[k]), t)
    nv = data['nv']
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
    idx = dec('index', '<u4')
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
    images = [{'mimeType': 'image/png', 'bufferView': view(png(os.path.join(texdir, f))), 'name': f.split('.')[0]} for f in ('normal.webp', 'detail.webp', 'id.png')]
    nodes = [{'name': 'RepArc gym model', 'mesh': 0, 'skin': 0}]
    for b in bones:
        tr = bpos[b['name']] - (bpos[b['parent']] if b['parent'] else 0)
        nodes.append({'name': b['name'], 'translation': [float(x) for x in tr]})
    for i, b in enumerate(bones):
        kids = [j + 1 for j, c in enumerate(bones) if c['parent'] == b['name']]
        if kids:
            nodes[i + 1]['children'] = kids
    gl = {
        'asset': {'version': '2.0', 'generator': 'RepArc tool/motion/glb.py', 'copyright': 'Body: MakeHuman CC0. Muscle atlas and textures: RepArc.'},
        'scene': 0,
        'scenes': [{'nodes': [0, 1], 'extras': {'muscles': data['muscles'], 'atlas': data['atlas'], 'cats': data['cats'], 'detailTexture': 1, 'idTexture': 2}}],
        'nodes': nodes,
        'meshes': [{'name': 'body', 'primitives': [{'attributes': attrs, 'indices': ind, 'material': 0}]}],
        'materials': [{'name': 'anatomy', 'normalTexture': {'index': 0},
                       'pbrMetallicRoughness': {'baseColorFactor': [0.72, 0.71, 0.69, 1], 'metallicFactor': 0, 'roughnessFactor': 0.6}}],
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
