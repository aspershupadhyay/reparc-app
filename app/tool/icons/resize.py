"""Resizes the icon masters from render_test.dart into every platform size.

Run from app/ after `flutter test tool/icons/render_test.dart`.
"""
import json
import os
from PIL import Image, ImageDraw

OUT = "tool/icons/out"
icon = Image.open(f"{OUT}/icon-1024.png").convert("RGBA")
fg = Image.open(f"{OUT}/foreground-1024.png").convert("RGBA")
mark = Image.open(f"{OUT}/mark-1024.png").convert("RGBA")


def save(img, size, path, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if rgb:
        # iOS icons must be opaque.
        out = out.convert("RGB")
    out.save(path, optimize=True)


# iOS app icons, from the asset catalog's own list.
ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for entry in json.load(open(f"{ios}/Contents.json"))["images"]:
    pts = float(entry["size"].split("x")[0])
    scale = int(entry["scale"].replace("x", ""))
    save(icon, round(pts * scale), f"{ios}/{entry['filename']}", rgb=True)

# Android legacy icons: rounded square, as launchers before Android 8 expect.
dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
mask = Image.new("L", (1024, 1024), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 1023, 1023), radius=224, fill=255)
rounded = icon.copy()
rounded.putalpha(mask)
for d, f in dens.items():
    res = f"android/app/src/main/res/mipmap-{d}"
    save(rounded, round(48 * f), f"{res}/ic_launcher.png")
    # Adaptive icon foreground: 108 dp canvas.
    save(fg, round(108 * f), f"{res}/ic_launcher_foreground.png")
    # Splash logo: 160 dp.
    save(mark, round(160 * f), f"android/app/src/main/res/drawable-{d}/launch_logo.png")

# iOS launch image (1x/2x/3x of 160 pt).
li = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
save(mark, 160, f"{li}/LaunchImage.png")
save(mark, 320, f"{li}/LaunchImage@2x.png")
save(mark, 480, f"{li}/LaunchImage@3x.png")

# Website.
save(icon, 180, "../site/apple-touch-icon.png", rgb=True)
save(mark, 512, "../site/assets/mark-512.png")
save(icon, 512, "../site/assets/icon-512.png", rgb=True)
print("icons written")
