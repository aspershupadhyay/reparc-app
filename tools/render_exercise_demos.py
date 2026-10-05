"""Render draft, looping Reparc exercise demonstrations with Blender.

Run from the repository root:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/render_exercise_demos.py

The motion is a stylized visual draft. A qualified coach must review it before
the files are presented as exercise instruction in a public app release.
"""

import math
import os
import subprocess
import tempfile

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "exercise-demos")
FONT_PATH = os.path.join(OUT_DIR, "Manrope-SemiBold.ttf")
SIZE = 512
FRAME_COUNT = 48
FPS = 24

COLORS = {
    "canvas": (0.965, 0.973, 0.961, 1),
    "ink": (0.045, 0.065, 0.055, 1),
    "body": (0.075, 0.17, 0.13, 1),
    "body_far": (0.22, 0.34, 0.28, 1),
    "secondary": (0.25, 0.32, 0.28, 1),
    "lime": (0.847, 1.0, 0.459, 1),
    "soft": (0.91, 0.945, 0.945, 1),
    "white": (1, 1, 1, 1),
    "lavender": (0.804, 0.733, 1, 1),
}


def material(name, color, roughness=0.75):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def flat_material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = color
    output = nodes.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(emission.outputs["Emission"], output.inputs["Surface"])
    return mat


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def add_text(name, value, loc, size, mat, font, align="LEFT"):
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = value
    curve.size = size
    curve.align_x = align
    curve.extrude = 0
    curve.font = font
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (math.radians(90), 0, 0)
    obj.data.materials.append(mat)
    return obj


def add_capsule(name, radius, mat, depth=1.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (radius, radius, radius)
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def add_bone(name, radius, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=1)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Soft edges", "BEVEL")
    bevel.width = radius * 0.65
    bevel.segments = 2
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def set_segment(obj, a, b):
    start, end = Vector(a), Vector(b)
    delta = end - start
    obj.location = (start + end) * 0.5
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.scale.z = max(delta.length, 0.001)


def key_segment(obj, a, b, frame):
    set_segment(obj, a, b)
    for attr in ("location", "rotation_quaternion", "scale"):
        obj.keyframe_insert(data_path=attr, frame=frame)


def add_ground():
    ground = flat_material("Canvas", COLORS["canvas"])
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.035))
    bpy.context.object.name = "Seamless canvas"
    bpy.context.object.data.materials.append(ground)


def setup_scene(title, font, mats):
    scene = bpy.context.scene
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.fps = FPS
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.image_settings.compression = 15
    scene.camera = None

    world = bpy.data.worlds.new("Reparc world") if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = COLORS["canvas"]
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35

    bpy.ops.object.camera_add(location=(0, -7.4, 2.25))
    camera = bpy.context.object
    camera.name = "Side view camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.95
    direction = Vector((0, 0, 1.16)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    bpy.ops.object.light_add(type="AREA", location=(-3.5, -4.0, 5.5))
    key = bpy.context.object
    key.name = "Large soft key"
    key.data.energy = 480
    key.data.shape = "DISK"
    key.data.size = 5
    key.rotation_euler = (math.radians(20), 0, math.radians(-28))
    bpy.ops.object.light_add(type="AREA", location=(3.5, 1.0, 3.0))
    fill = bpy.context.object
    fill.name = "Soft fill"
    fill.data.energy = 220
    fill.data.size = 4
    fill.rotation_euler = (math.radians(32), 0, math.radians(145))

    add_ground()
    add_text("Brand", "REPARC  /  MOVEMENT LIBRARY", (-1.22, -0.28, 2.46), 0.085, mats["ink_flat"], font)
    add_text("Title", title.upper(), (-1.22, -0.28, 2.17), 0.19, mats["ink_flat"], font)
    add_text("View label", "SIDE VIEW  ·  VISUAL DRAFT", (-1.22, -0.28, 1.98), 0.068, mats["secondary_flat"], font)

    # A restrained platform mark gives the feet a clear ground reference.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.0, 0.0, 0.005))
    platform = bpy.context.object
    platform.name = "Lime ground cue"
    platform.dimensions = (1.15, 0.12, 0.025)
    platform.data.materials.append(mats["lime_flat"])
    bevel = platform.modifiers.new("Rounded ends", "BEVEL")
    bevel.width = 0.06
    bevel.segments = 4

    # Lightweight loop marker at the bottom of the instruction card.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.01, 1.82))
    track = bpy.context.object
    track.name = "Rep path"
    track.dimensions = (1.45, 0.025, 0.018)
    track.data.materials.append(mats["soft"])
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.045, location=(-0.7, -0.04, 1.82))
    marker = bpy.context.object
    marker.name = "Rep progress marker"
    marker.data.materials.append(mats["lime_flat"])
    for frame in range(1, FRAME_COUNT + 1):
        phase = (frame - 1) / (FRAME_COUNT - 1)
        marker.location = (-0.7 + 1.4 * (0.5 - 0.5 * math.cos(phase * math.tau)), -0.04, 1.82)
        marker.keyframe_insert(data_path="location", frame=frame)
    return scene


def add_actor(mats):
    parts = {}
    joints = {}
    # Each side is separate so near and far limbs remain readable in a side view.
    for side, y, color in (("far", 0.095, mats["body_far"]), ("near", -0.075, mats["body"])):
        for name, radius in (("arm_upper", 0.055), ("arm_lower", 0.048), ("leg_upper", 0.078), ("leg_lower", 0.062), ("foot", 0.056)):
            parts[f"{side}_{name}"] = add_bone(f"{side} {name}", radius, color)
        for name, radius in (("head", 0.13), ("shoulder", 0.085), ("elbow", 0.06), ("wrist", 0.05), ("hip", 0.08), ("knee", 0.068), ("ankle", 0.05)):
            joints[f"{side}_{name}"] = add_capsule(f"{side} {name}", radius, color)
    parts["torso"] = add_bone("torso", 0.105, mats["body"])
    parts["neck"] = add_bone("neck", 0.055, mats["body"])
    # Face profile details make the silhouette read as a person without copying a photo.
    eye_mat = mats["ink"]
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.018, location=(-0.055, -0.15, 1.63))
    eye = bpy.context.object
    eye.name = "Eye detail"
    eye.data.materials.append(eye_mat)
    joints["eye"] = eye
    return parts, joints


def segment_map(p):
    result = {"torso": (p["hip"], p["shoulder"]), "neck": (p["shoulder"], p["head_base"])}
    for side in ("near", "far"):
        result[f"{side}_arm_upper"] = (p[f"{side}_shoulder"], p[f"{side}_elbow"])
        result[f"{side}_arm_lower"] = (p[f"{side}_elbow"], p[f"{side}_wrist"])
        result[f"{side}_leg_upper"] = (p[f"{side}_hip"], p[f"{side}_knee"])
        result[f"{side}_leg_lower"] = (p[f"{side}_knee"], p[f"{side}_ankle"])
        result[f"{side}_foot"] = (p[f"{side}_ankle"], p[f"{side}_toe"])
    return result


def key_actor(parts, joints, pose, frame):
    pose = pose(frame)
    for key, (a, b) in segment_map(pose).items():
        key_segment(parts[key], a, b, frame)
    joint_points = {
        "head": pose["head"], "shoulder": pose["shoulder"], "elbow": pose["near_elbow"], "wrist": pose["near_wrist"],
        "hip": pose["hip"], "knee": pose["near_knee"], "ankle": pose["near_ankle"],
    }
    for side in ("near", "far"):
        depth = -0.075 if side == "near" else 0.095
        for label, point in joint_points.items():
            obj = joints[f"{side}_{label}"]
            obj.location = (point[0], depth, point[2])
            obj.keyframe_insert(data_path="location", frame=frame)
    eye = joints["eye"]
    eye.location = (pose["head"][0] - 0.05, -0.16, pose["head"][2] + 0.025)
    eye.keyframe_insert(data_path="location", frame=frame)


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def cyclic_amount(frame):
    phase = (frame - 1) / (FRAME_COUNT - 1)
    return 0.5 - 0.5 * math.cos(phase * math.tau)


def base_pose():
    p = {
        "head": (0.02, 0, 1.66), "head_base": (0.02, 0, 1.53),
        "shoulder": (0.0, 0, 1.39), "hip": (0.0, 0, 0.92),
        "near_shoulder": (0.0, -0.075, 1.37), "near_elbow": (-0.10, -0.075, 1.12), "near_wrist": (-0.13, -0.075, 0.92),
        "far_shoulder": (0.0, 0.095, 1.37), "far_elbow": (-0.10, 0.095, 1.12), "far_wrist": (-0.13, 0.095, 0.92),
        "near_hip": (0, -0.075, 0.92), "near_knee": (-0.02, -0.075, 0.49), "near_ankle": (0, -0.075, 0.09), "near_toe": (-0.23, -0.075, 0.055),
        "far_hip": (0, 0.095, 0.92), "far_knee": (-0.02, 0.095, 0.49), "far_ankle": (0, 0.095, 0.09), "far_toe": (-0.23, 0.095, 0.055),
    }
    return p


def squat_pose(frame):
    t = cyclic_amount(frame)
    p = base_pose()
    p.update({
        "head": lerp((0.02, 0, 1.66), (0.15, 0, 1.42), t),
        "head_base": lerp((0.02, 0, 1.53), (0.15, 0, 1.30), t),
        "shoulder": lerp((0, 0, 1.39), (0.18, 0, 1.20), t),
        "hip": lerp((0, 0, 0.92), (0.18, 0, 0.58), t),
        "near_shoulder": lerp((0, -0.075, 1.37), (0.18, -0.075, 1.18), t),
        "near_elbow": lerp((-0.10, -0.075, 1.12), (-0.30, -0.075, 1.03), t),
        "near_wrist": lerp((-0.13, -0.075, 0.92), (-0.37, -0.075, 0.96), t),
        "far_shoulder": lerp((0, 0.095, 1.37), (0.18, 0.095, 1.18), t),
        "far_elbow": lerp((-0.10, 0.095, 1.12), (-0.30, 0.095, 1.03), t),
        "far_wrist": lerp((-0.13, 0.095, 0.92), (-0.37, 0.095, 0.96), t),
    })
    for side in ("near", "far"):
        y = -0.075 if side == "near" else 0.095
        p[f"{side}_hip"] = p["hip"][0], y, p["hip"][2]
        p[f"{side}_knee"] = lerp((-0.02, y, 0.49), (-0.34, y, 0.37), t)
        p[f"{side}_ankle"] = (0, y, 0.09)
        p[f"{side}_toe"] = (-0.23, y, 0.055)
    return p


def pushup_pose(frame):
    t = cyclic_amount(frame)
    p = base_pose()
    # Horizontal, side-facing body. The shoulder and elbow travel while the trunk stays aligned.
    p["head"] = (-0.74, 0, 0.50 - 0.11 * t)
    p["head_base"] = (-0.68, 0, 0.47 - 0.11 * t)
    p["shoulder"] = (-0.43, 0, 0.55 - 0.28 * t)
    p["hip"] = (0.28, 0, 0.46 - 0.07 * t)
    for side in ("near", "far"):
        y = -0.075 if side == "near" else 0.095
        p[f"{side}_shoulder"] = (p["shoulder"][0], y, p["shoulder"][2])
        p[f"{side}_elbow"] = lerp((-0.12, y, 0.31), (0.00, y, 0.20), t)
        p[f"{side}_wrist"] = (-0.28, y, 0.08)
        p[f"{side}_hip"] = (0.28, y, p["hip"][2])
        p[f"{side}_knee"] = (0.61, y, 0.39 - 0.05 * t)
        p[f"{side}_ankle"] = (0.83, y, 0.11)
        p[f"{side}_toe"] = (0.99, y, 0.055)
    p["shoulder"] = (p["shoulder"][0], 0, p["shoulder"][2])
    return p


def row_pose(frame):
    t = cyclic_amount(frame)
    p = base_pose()
    # Hinge at the hip. The torso keeps one angle through each row repetition.
    p.update({"head": (-0.51, 0, 1.33), "head_base": (-0.45, 0, 1.22), "shoulder": (-0.33, 0, 1.16), "hip": (0.18, 0, 0.90)})
    for side in ("near", "far"):
        y = -0.075 if side == "near" else 0.095
        p[f"{side}_shoulder"] = (-0.33, y, 1.16)
        # One arm supports the torso on a bench. The near arm rows the weight.
        if side == "near":
            p[f"{side}_elbow"] = lerp((-0.05, y, 0.88), (-0.19, y, 1.10), t)
            p[f"{side}_wrist"] = lerp((0.04, y, 0.56), (-0.12, y, 0.88), t)
        else:
            p[f"{side}_elbow"] = (-0.08, y, 0.80)
            p[f"{side}_wrist"] = (0.05, y, 0.53)
        p[f"{side}_hip"] = (0.18, y, 0.90)
        p[f"{side}_knee"] = (0.25, y, 0.49)
        p[f"{side}_ankle"] = (0.48, y, 0.09)
        p[f"{side}_toe"] = (0.23, y, 0.055)
    return p


def add_row_bench(mats):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.39, 0.20, 0.58))
    bench = bpy.context.object
    bench.name = "Row support bench"
    bench.dimensions = (0.82, 0.38, 0.10)
    bench.data.materials.append(mats["soft"])
    bevel = bench.modifiers.new("Bench soft edges", "BEVEL")
    bevel.width = 0.04
    bevel.segments = 3
    for x in (0.12, 0.69):
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.025, depth=0.48, location=(x, 0.2, 0.31))
        bpy.context.object.name = "Bench leg"
        bpy.context.object.data.materials.append(mats["secondary"])


def key_dumbbell(frame, wrist):
    for obj in bpy.data.objects:
        if obj.name.startswith("Dumbbell"):
            depth_offset = obj.get("depth_offset", 0.0)
            obj.location = (wrist[0], wrist[1] + depth_offset, wrist[2])
            obj.keyframe_insert(data_path="location", frame=frame)


def add_dumbbell_parts(mats):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.018, depth=0.16, location=(-0.12, -0.075, 0.88), rotation=(math.radians(90), 0, 0))
    handle = bpy.context.object
    handle.name = "Dumbbell handle"
    handle.data.materials.append(mats["ink"])
    for side in (-1, 1):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.12, -0.075 + side * 0.07, 0.88))
        plate = bpy.context.object
        plate.name = "Dumbbell plate"
        plate["depth_offset"] = side * 0.07
        plate.dimensions = (0.11, 0.05, 0.095)
        plate.data.materials.append(mats["lime"])
        bevel = plate.modifiers.new("Weight soft edges", "BEVEL")
        bevel.width = 0.025
        bevel.segments = 3


def render_gif(slug, pose_fn, title):
    clear_scene()
    mats = {name: material(name.title(), color) for name, color in COLORS.items()}
    mats["ink_flat"] = flat_material("Ink typography", COLORS["ink"])
    mats["secondary_flat"] = flat_material("Secondary typography", COLORS["secondary"])
    mats["lime_flat"] = flat_material("Lime graphic", COLORS["lime"])
    font = bpy.data.fonts.load(FONT_PATH)
    scene = setup_scene(title, font, mats)
    if slug == "one_arm_dumbbell_row":
        add_row_bench(mats)
    parts, joints = add_actor(mats)
    dumbbell = slug == "one_arm_dumbbell_row"
    if dumbbell:
        add_dumbbell_parts(mats)
    scene.frame_start = 1
    scene.frame_end = FRAME_COUNT
    scene.render.fps = FPS
    for frame in range(1, FRAME_COUNT + 1):
        key_actor(parts, joints, pose_fn, frame)
        if dumbbell:
            key_dumbbell(frame, pose_fn(frame)["near_wrist"])
    with tempfile.TemporaryDirectory(prefix=f"reparc_{slug}_") as frame_dir:
        for frame in range(1, FRAME_COUNT + 1):
            scene.frame_set(frame)
            scene.render.filepath = os.path.join(frame_dir, f"frame_{frame:03d}.png")
            bpy.ops.render.render(write_still=True)
        output = os.path.join(OUT_DIR, f"{slug}.gif")
        palette = os.path.join(frame_dir, "palette.png")
        subprocess.run([
            "ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS),
            "-i", os.path.join(frame_dir, "frame_%03d.png"),
            "-vf", "fps=20,scale=480:-1:flags=lanczos,palettegen=max_colors=128:stats_mode=diff",
            palette,
        ], check=True)
        subprocess.run([
            "ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS),
            "-i", os.path.join(frame_dir, "frame_%03d.png"), "-i", palette,
            "-lavfi", "fps=20,scale=480:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle",
            "-loop", "0", output,
        ], check=True)
        print(f"Created {output} ({os.path.getsize(output):,} bytes)")


os.makedirs(OUT_DIR, exist_ok=True)
render_only = os.environ.get("REPARC_RENDER_ONLY")
renders = {
    "bodyweight_squat": (squat_pose, "Bodyweight squat"),
    "push_up": (pushup_pose, "Push-up"),
    "one_arm_dumbbell_row": (row_pose, "One-arm dumbbell row"),
}
for slug, (pose, title) in renders.items():
    if render_only and slug != render_only:
        continue
    render_gif(slug, pose, title)
