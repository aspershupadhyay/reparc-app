"""Builds the Motion Lab page: lab.html with the model and its textures inlined.

    python3 -I tool/motion/build.py /tmp/gym.json /tmp/gym-tex /tmp/motion-lab.html
"""
import base64
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
model, texdir, out = sys.argv[1:4]
page = open(os.path.join(here, 'lab.html')).read()
uri = lambda f, mime: f'data:{mime};base64,' + base64.b64encode(open(os.path.join(texdir, f), 'rb').read()).decode()
# A painted model (paint.py build) brings albedo, normal and label textures; an atlas model (bake.py) does not.
has = lambda f: os.path.exists(os.path.join(texdir, f))
if has('detail.webp'):
    page = page.replace('__NORMAL__', uri('normal.webp', 'image/webp')).replace('__DETAIL__', uri('detail.webp', 'image/webp')).replace('__ID__', uri('id.png', 'image/png'))
page = page.replace('__ALBEDO__', uri('albedo.webp', 'image/webp') if has('albedo.webp') else '')
page = page.replace('__PNORMAL__', uri('normal.webp', 'image/webp') if has('albedo.webp') else '')
page = page.replace('__SKIN__', uri('skin.webp', 'image/webp') if has('skin.webp') else '')
page = page.replace('__LABEL__', uri('label.png', 'image/png') if has('label.png') else '')
page = page.replace('__BODY__', open(model).read())
open(out, 'w').write(page)
print(f'{os.path.getsize(out) // 1024} KB -> {out}')
