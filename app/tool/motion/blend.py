"""Builds a ready-to-edit Blender file of the gym model: real skin, the painted
anatomy as a second material, the skeleton, and eyes, brows, lashes, and hair.

    python3 tool/motion/blend.py tool/motion/dist/reparc-gym-model.glb /tmp/paint-out out.blend
    blender -b -P tool/motion/blend.py -- tool/motion/dist/reparc-gym-model.glb /tmp/paint-out out.blend

Needs the .glb (glb.py) and the paint folder after skin.py (skin.webp and the
head parts in model.json). Every texture is packed into the .blend, so the
file opens anywhere. In the file:

- "Body": material slot 1 is "Skin" (skin texture with a little subsurface
  scattering and the painted relief at low strength); slot 2 is "Painted
  anatomy" (the painting). To show the anatomy, select the body, Tab into
  Edit Mode, select all, pick "Painted anatomy" in the material list, and
  press Assign.
- "Eyes", "Brows", "Lashes", "Hair" follow the "head" bone.
- The armature carries the 51 bones in the bind pose; pose it in Pose Mode.
- Three area lights and a camera frame the body; F12 renders with Cycles.

Changes made in this file do not reach the Motion Lab, which builds from the
scripts: put lasting changes into the scripts, or export a .glb and tell us.
"""
import base64
import json
import os
import sys
import tempfile

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
glb, texdir, out = args[:3]
data = json.load(open(os.path.join(texdir, 'model.json')))
tmp = tempfile.mkdtemp()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
body = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
body.name, arm.name = 'Body', 'Armature'
painted = body.data.materials[0]
painted.name = 'Painted anatomy'


def image(path, colour=True):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = 'sRGB' if colour else 'Non-Color'
    return img


def material(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    return m, m.node_tree.nodes, m.node_tree.links, m.node_tree.nodes['Principled BSDF']


# Skin: the baked skin texture, a little subsurface scattering, and the painted relief, softened.
skin, nodes, links, bsdf = material('Skin')
tex = nodes.new('ShaderNodeTexImage')
tex.image = image(os.path.join(texdir, 'skin.webp'))
links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
bsdf.inputs['Roughness'].default_value = 0.5
bsdf.inputs['Subsurface Weight'].default_value = 0.12
bsdf.inputs['Subsurface Radius'].default_value = (1.0, 0.35, 0.2)
bsdf.inputs['Subsurface Scale'].default_value = 0.01
nt = nodes.new('ShaderNodeTexImage')
nt.image = image(os.path.join(texdir, 'normal.webp'), colour=False)
nm = nodes.new('ShaderNodeNormalMap')
nm.inputs['Strength'].default_value = 0.35
links.new(nt.outputs['Color'], nm.inputs['Color'])
links.new(nm.outputs['Normal'], bsdf.inputs['Normal'])
body.data.materials.clear()
body.data.materials.append(skin)
body.data.materials.append(painted)
for p in body.data.polygons:
    p.material_index = 0

# Head parts (skin.py): glTF y-up metres to Blender z-up, parented to the head bone.
head_bone = arm.data.bones['head']
for h in data.get('head', []):
    import numpy as np
    dec = lambda k, t: np.frombuffer(base64.b64decode(h[k]), t)
    P = dec('pos', '<f4').reshape(-1, 3)
    UV = dec('uv', '<f4').reshape(-1, 2)
    T = dec('index', '<u2').reshape(-1, 3)
    verts = [(x, -z, y) for x, y, z in P]
    me = bpy.data.meshes.new(h['name'].title())
    me.from_pydata(verts, [], [tuple(int(i) for i in t) for t in T])
    uvl = me.uv_layers.new(name='UVMap')
    for loop in me.loops:
        u, v = UV[loop.vertex_index]
        uvl.data[loop.index].uv = (u, 1 - v)   # skin.py stores v top-down for the page
    me.shade_smooth() if hasattr(me, 'shade_smooth') else None
    ob = bpy.data.objects.new(h['name'].title(), me)
    bpy.context.scene.collection.objects.link(ob)
    # Texture from the data URI.
    path = os.path.join(tmp, h['name'] + '.webp')
    open(path, 'wb').write(base64.b64decode(h['tex'].split(',', 1)[1]))
    m, nodes, links, bsdf = material(h['name'].title())
    t = nodes.new('ShaderNodeTexImage')
    t.image = image(path)
    links.new(t.outputs['Color'], bsdf.inputs['Base Color'])
    bsdf.inputs['Roughness'].default_value = 0.15 if h['name'] == 'eyes' else 0.6
    if h['alpha']:
        links.new(t.outputs['Alpha'], bsdf.inputs['Alpha'])
        if hasattr(m, 'surface_render_method'):
            m.surface_render_method = 'DITHERED'
        m.use_backface_culling = False
    me.materials.append(m)
    # Follow the head bone, keeping the bind-pose place.
    ob.parent = arm
    ob.parent_type = 'BONE'
    ob.parent_bone = 'head'
    bpy.context.view_layer.update()
    ob.matrix_parent_inverse = (arm.matrix_world @ head_bone.matrix_local @ __import__('mathutils').Matrix.Translation((0, head_bone.length, 0))).inverted()

# Studio: three area lights, a camera, a soft grey world, Cycles.
sc = bpy.context.scene
centre = Vector((0, 0, 0.95))


def light(name, energy, size, loc):
    ld = bpy.data.lights.new(name, 'AREA')
    ld.energy, ld.size = energy, size
    ob = bpy.data.objects.new(name, ld)
    ob.location = centre + Vector(loc)
    ob.rotation_euler = Vector(loc).to_track_quat('Z', 'Y').to_euler()
    sc.collection.objects.link(ob)


light('Key', 300, 1.2, (-1.6, -2.2, 1.6))
light('Fill', 80, 2.0, (2.2, -1.5, 0.3))
light('Rim', 160, 1.0, (0.8, 2.2, 1.2))
cd = bpy.data.cameras.new('Camera')
cd.lens = 70
cam = bpy.data.objects.new('Camera', cd)
cam.location = (0, -4.1, 0.95)
cam.rotation_euler = (1.5708, 0, 0)
sc.collection.objects.link(cam)
sc.camera = cam
world = bpy.data.worlds.new('Studio')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.05, 0.055, 0.06, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 1.0
sc.world = world
sc.render.engine = 'CYCLES'
sc.cycles.samples = 128
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = 1080, 1920
sc.view_settings.view_transform = 'AgX'

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out), compress=True)
print('wrote', out, os.path.getsize(out) // 1024, 'KB')
