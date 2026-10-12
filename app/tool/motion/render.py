"""Renders the gym model .glb in Blender (studio light, Cycles) to judge its look.

Runs in Blender's Python: either the `bpy` package (pip install bpy; the
version must match your Python) or Blender itself:

    python3 tool/motion/render.py model.glb out.png [clay] [torso|legs]
    blender -b -P tool/motion/render.py -- model.glb out.png [clay] [torso|legs]

Writes one image with four views (front, side, back, three-quarter). With
`clay`, the body is plain grey, so only the shape shows (no paint); that is
the fair test of the surface relief. `torso` or `legs` frames that part
close up. Also a quick check that the .glb opens
in Blender.
"""
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
glb, out = args[0], args[1]
clay = 'clay' in args[2:]
# Framing: (height of the frame centre in metres, camera distance).
frame = {'torso': (1.3, 2.2), 'legs': (0.5, 2.4)}.get(next((a for a in args[2:] if a in ('torso', 'legs')), ''), (0.89, 4.9))
VIEWS = [0, 90, 180, -45]  # degrees around the body, 0 = front
W, H = 600, 1100

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
body = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
if clay:
    mat = bpy.data.materials.new('clay')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (0.55, 0.53, 0.5, 1)
    bsdf.inputs['Roughness'].default_value = 0.6
    body.data.materials.clear()
    body.data.materials.append(mat)

sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = 24
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = W, H
sc.render.film_transparent = False
world = bpy.data.worlds.new('w')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (1, 1, 1, 1)
sc.view_settings.view_transform = 'AgX'
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.25
sc.world = world

# The body stands on z = 0 in Blender (glTF +Y up becomes +Z up), facing -Y.
centre = Vector((0, 0, frame[0]))
rig = bpy.data.objects.new('rig', None)
rig.location = centre
sc.collection.objects.link(rig)


def light(name, energy, size, loc):
    ld = bpy.data.lights.new(name, 'AREA')
    ld.energy, ld.size = energy, size
    ob = bpy.data.objects.new(name, ld)
    ob.location = Vector(loc)  # in the rig's frame
    ob.parent = rig
    ob.rotation_euler = Vector(loc).to_track_quat('Z', 'Y').to_euler()  # -Z (the beam) faces the body
    sc.collection.objects.link(ob)


# Key from the upper left front, fill from the right, rim from behind: grazing
# enough to show relief, as in an anatomy plate.
light('key', 160, 1.0, (-1.6, -2.2, 1.6))
light('fill', 35, 2.0, (2.2, -1.5, 0.3))
light('rim', 90, 1.0, (0.8, 2.2, 1.2))
cd = bpy.data.cameras.new('cam')
cd.lens = 85
cam = bpy.data.objects.new('cam', cd)
cam.parent = rig
cam.location = (0, -frame[1], 0)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.collection.objects.link(cam)
sc.camera = cam

import numpy as np  # noqa: E402  (Blender ships numpy)
tiles = []
for deg in VIEWS:
    rig.rotation_euler = (0, 0, math.radians(deg))
    sc.render.filepath = out + f'.{deg}.png'
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(sc.render.filepath)
    px = np.array(img.pixels[:]).reshape(H, W, 4)[::-1]
    tiles.append(px)
sheet = np.concatenate(tiles, 1)
img = bpy.data.images.new('sheet', sheet.shape[1], sheet.shape[0])
img.pixels = sheet[::-1].reshape(-1)
img.filepath_raw = out
img.file_format = 'PNG'
img.save()
import os  # noqa: E402
for deg in VIEWS:
    os.remove(out + f'.{deg}.png')
print('wrote', out)
