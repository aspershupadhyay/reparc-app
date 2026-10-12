"""Builds the Motion Lab page: lab.html with the body data inlined.

    python3 -I tool/motion/build.py /tmp/body.json /tmp/motion-lab.html
"""
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
page = open(os.path.join(here, 'lab.html')).read()
data = open(sys.argv[1]).read()
open(sys.argv[2], 'w').write(page.replace('__BODY__', data))
print(f'{os.path.getsize(sys.argv[2]) // 1024} KB -> {sys.argv[2]}')
