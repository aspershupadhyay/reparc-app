"""The RepArc muscle atlas: about 40 muscles a side, drawn as 2D shapes
on the surface charts in charts.py (metres), then laid on the body.

Each muscle has:
- chart and shape: a polygon (rounded) or a tapered spindle.
- cat: the app's Muscle it belongs to (for highlights), or None.
- kind: 'muscle' (raised belly with fibres) or 'tendon' (flat, smooth).
- fiber: fibre direction in chart space: ('along', (du, dv)) or ('to', (u, v)).
- height: peak relief of the belly in metres.
- attach: origin, optional via points, and insertion as (bone, joint key,
  offset in metres). The page measures the path through them each frame:
  via points let a tendon wrap over a joint (the kneecap, the elbow), as in
  musculoskeletal models such as OpenSim.
"""
import numpy as np

P_ARM = 2 * np.pi * 0.045
P_FORE = 2 * np.pi * 0.04
P_THIGH = 2 * np.pi * 0.075
P_SHIN = 2 * np.pi * 0.055


def sd_poly(p, poly, r=0.0):
    """Signed distance from points p (n, 2) to a polygon (inside < 0), rounded by r."""
    v = np.asarray(poly, float)
    d = np.full(len(p), np.inf)
    s = np.ones(len(p))
    j = len(v) - 1
    for i in range(len(v)):
        e = v[j] - v[i]
        w = p - v[i]
        b = w - e * np.clip((w @ e) / (e @ e), 0, 1)[:, None]
        d = np.minimum(d, np.einsum('ij,ij->i', b, b))
        c1 = p[:, 1] >= v[i, 1]
        c2 = p[:, 1] < v[j, 1]
        c3 = e[0] * w[:, 1] > e[1] * w[:, 0]
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
        j = i
    return s * np.sqrt(d) + r


def sd_spindle(p, a, b, ra, rm, rb):
    """Tapered capsule from a to b: radius ra at a, rm in the middle, rb at b."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    e = b - a
    t = np.clip(((p - a) @ e) / (e @ e), 0, 1)
    q = a + t[:, None] * e
    r = np.where(t < 0.5, ra + (rm - ra) * np.sin(np.pi * t), rb + (rm - rb) * np.sin(np.pi * t))
    return np.linalg.norm(p - q, axis=1) - r


def wrap(fn, period):
    """A shape on a limb, evaluated across the seam at the back."""
    def g(p):
        out = fn(p)
        for k in (-period, period):
            q = p.copy(); q[:, 0] += k
            out = np.minimum(out, fn(q))
        return out
    return g


def poly(pts, r=0.006):
    return lambda p: sd_poly(p, pts, -r)


def spindle(a, b, ra, rm, rb):
    return lambda p: sd_spindle(p, a, b, ra, rm, rb)


def inter(f, g):
    return lambda p: np.maximum(f(p), g(p))


def half(u0, side):
    """Half plane u > u0 (side=+1) or u < u0 (side=-1), as a distance."""
    return lambda p: (u0 - p[:, 0]) * side


def band(v0, v1):
    return lambda p: np.maximum(v0 - p[:, 1], p[:, 1] - v1)


M = []


def mus(name, chart, shape, cat=None, kind='muscle', fiber=('along', (0, 1)), height=0.004, attach=None, segs=None, over=0.0):
    """[over] (m) lets a surface muscle lie over its neighbours (the sartorius over the quads)."""
    M.append(dict(name=name, chart=chart, shape=shape, cat=cat, kind=kind, fiber=fiber, height=height, attach=attach, segs=segs, over=over,
                  group=name.split(',')[0].split(' (')[0] if ',' in name else name))


def ray_split(apex, through, sgn):
    """Half plane on one side of the line from [apex] through [through], as a distance.
    Fan muscles (pectoralis, deltoid) split into heads along such rays."""
    a = np.array(apex, float); b = np.array(through, float)
    n = np.array([b[1] - a[1], a[0] - b[0]]); n /= np.linalg.norm(n)
    return lambda p: sgn * ((p - a) @ n)


# ---------------- Trunk (left side drawn; the right mirrors) ----------------
# u: arc from the front midline (0) round the side (0.22) to the spine (0.44). v: height (m).
PEC = [(0.017, 1.455), (0.06, 1.47), (0.15, 1.476), (0.186, 1.437), (0.207, 1.396), (0.197, 1.352), (0.18, 1.312), (0.15, 1.268), (0.108, 1.232), (0.062, 1.214), (0.017, 1.216)]
pec = poly(PEC, 0.005)
PEC_APEX = (0.207, 1.39)
mus('Pectoralis major, clavicular head', 'trunk', inter(pec, ray_split(PEC_APEX, (0.012, 1.425), -1)), 'upperChest', fiber=('to', PEC_APEX), height=0.006,
    attach=(('chest', 'clavicle.L____head', (0.05, 0.0, 0.08)), ('uarmL', 'upperarm01.L____head', (0.0, -0.07, 0.03))))
pec_up = poly([(x, y + 0.016) for x, y in PEC], 0.005)  # the pec moved up: what is left below it is the lower rim
mus('Pectoralis major, sternal head', 'trunk', inter(pec, lambda p: np.maximum(ray_split(PEC_APEX, (0.012, 1.425), 1)(p), np.minimum(pec_up(p), ray_split(PEC_APEX, (0.012, 1.3), -1)(p)))), 'chest', fiber=('to', PEC_APEX), height=0.009,
    attach=(('chest', 'spine01____head', (0.0, 0.0, 0.15)), ('uarmL', 'upperarm01.L____head', (0.0, -0.08, 0.03))))
mus('Pectoralis major, abdominal head', 'trunk', inter(pec, lambda p: np.maximum(np.maximum(-pec_up(p), ray_split(PEC_APEX, (0.012, 1.425), 1)(p)), ray_split(PEC_APEX, (0.012, 1.3), 1)(p))), 'lowerChest', fiber=('to', PEC_APEX), height=0.007,
    attach=(('chest', 'spine01____head', (0.0, -0.12, 0.15)), ('uarmL', 'upperarm01.L____head', (0.0, -0.08, 0.03))))
RA_U = (0.009, 0.072)
for i, (v0, v1) in enumerate([(1.183, 1.245), (1.125, 1.177), (1.07, 1.119)]):
    mus(f'Rectus abdominis, block {i + 1}', 'trunk', poly([(RA_U[0], v0), (RA_U[1], v0), (RA_U[1] + 0.004, v1), (RA_U[0], v1)], 0.007), 'abs',
        height=0.0035, attach=(('hips', 'root____head', (0.0, -0.02, 0.17)), ('chest', 'spine01____head', (0.0, -0.1, 0.16))))
mus('Rectus abdominis, lower', 'trunk', poly([(RA_U[0], 0.945), (0.055, 0.95), (0.07, 1.0), (RA_U[1], 1.064), (RA_U[0], 1.064)], 0.007), 'lowerAbs',
    height=0.003, attach=(('hips', 'root____head', (0.0, -0.02, 0.17)), ('chest', 'spine01____head', (0.0, -0.1, 0.16))))
mus('Linea alba', 'trunk', poly([(-0.009, 0.95), (0.009, 0.95), (0.009, 1.25), (-0.009, 1.25)], 0.0), kind='tendon', height=0)
mus('External oblique', 'trunk', poly([(0.085, 1.0), (0.082, 1.1), (0.088, 1.19), (0.13, 1.215), (0.155, 1.2), (0.175, 1.22), (0.2, 1.205), (0.225, 1.22), (0.25, 1.2), (0.255, 1.06), (0.235, 1.0), (0.17, 0.97), (0.12, 0.955)], 0.005),
    'obliques', fiber=('along', (-0.7, -0.7)), height=0.004,
    attach=(('chest', 'spine01____head', (0.12, -0.1, 0.06)), ('hips', 'root____head', (0.02, -0.03, 0.15))))
for i, v in enumerate([1.225, 1.255, 1.285]):
    mus(f'Serratus anterior, slip {i + 1}', 'trunk', poly([(0.15, v + 0.006), (0.205, v - 0.01), (0.235, v + 0.012), (0.232, v + 0.032), (0.2, v + 0.022), (0.16, v + 0.026)], 0.004),
        None, fiber=('to', (0.26, v + 0.06)), height=0.003)
mus('Latissimus dorsi', 'trunk', poly([(0.265, 1.335), (0.3, 1.31), (0.36, 1.27), (0.42, 1.2), (0.43, 1.04), (0.37, 1.0), (0.3, 0.99), (0.255, 1.06), (0.258, 1.2), (0.232, 1.25), (0.235, 1.3)], 0.006),
    'lats', fiber=('to', (0.24, 1.36)), height=0.006,
    attach=(('hips', 'root____head', (0.0, 0.12, -0.08)), ('uarmL', 'upperarm01.L____head', (-0.02, -0.07, 0.0))))
TRAP = [(0.43, 1.6), (0.405, 1.56), (0.36, 1.505), (0.29, 1.488), (0.255, 1.465), (0.29, 1.43), (0.34, 1.405), (0.39, 1.33), (0.415, 1.215), (0.437, 1.18), (0.437, 1.6)]
trap = poly(TRAP, 0.005)
mus('Trapezius, upper', 'trunk', inter(trap, band(1.445, 2)), 'traps', fiber=('to', (0.27, 1.47)), height=0.006,
    attach=(('neck', 'neck03____head', (0.0, 0.0, -0.06)), ('clavL', 'clavicle.L____tail', (0.0, 0.02, -0.02))))
mus('Trapezius, middle and lower', 'trunk', inter(trap, band(0, 1.44)), 'upperBack', fiber=('to', (0.3, 1.43)), height=0.004,
    attach=(('chest', 'spine01____head', (0.0, -0.05, -0.1)), ('clavL', 'clavicle.L____tail', (0.0, 0.0, -0.05))))
mus('Infraspinatus', 'trunk', poly([(0.285, 1.425), (0.34, 1.4), (0.375, 1.355), (0.36, 1.315), (0.3, 1.325), (0.27, 1.38)], 0.005), 'upperBack',
    fiber=('to', (0.26, 1.42)), height=0.004)
mus('Teres major', 'trunk', poly([(0.268, 1.37), (0.3, 1.32), (0.355, 1.305), (0.35, 1.29), (0.29, 1.3), (0.258, 1.345)], 0.004), 'upperBack',
    fiber=('to', (0.24, 1.37)), height=0.004)
mus('Erector spinae', 'trunk', poly([(0.395, 0.99), (0.432, 0.98), (0.432, 1.2), (0.41, 1.22), (0.398, 1.1)], 0.006), 'lowerBack', height=0.005,
    attach=(('hips', 'root____head', (0.03, 0.0, -0.1)), ('chest', 'spine01____head', (0.03, 0.0, -0.1))))
mus('Thoracolumbar fascia', 'trunk', poly([(0.36, 0.975), (0.44, 0.96), (0.44, 1.05), (0.4, 0.99)], 0.0), kind='tendon', height=0)
mus('Gluteus medius', 'trunk', poly([(0.24, 0.985), (0.33, 0.995), (0.37, 0.975), (0.36, 0.93), (0.3, 0.915), (0.24, 0.93)], 0.006), 'abductors',
    fiber=('to', (0.24, 0.9)), height=0.005,
    attach=(('hips', 'root____head', (0.11, 0.08, -0.05)), ('thighL', 'upperleg01.L____head', (0.07, -0.03, -0.01))))
mus('Gluteus maximus', 'trunk', poly([(0.36, 0.97), (0.44, 0.95), (0.44, 0.78), (0.35, 0.775), (0.27, 0.8), (0.255, 0.86), (0.3, 0.915), (0.35, 0.93)], 0.008), 'glutes',
    fiber=('to', (0.24, 0.84)), height=0.008,
    attach=(('hips', 'root____head', (0.03, 0.02, -0.12)), ('thighL', 'upperleg01.L____head', (0.04, -0.12, -0.06))), segs=('trunk', 'thigh'))
mus('Sternocleidomastoid', 'trunk', spindle((0.02, 1.47), (0.3, 1.63), 0.008, 0.016, 0.01), None, fiber=('along', (0.28, 0.16)), height=0.004, segs=('neck', 'trunk'))

# ---------------- Upper arm (u: front 0, + outer; v: shoulder 0 to elbow 0.265) ----------------
apex = (0.045, 0.135)
delt = poly([(-0.075, -0.075), (0.15, -0.075), (0.15, 0.03), (0.07, 0.11), apex, (0.02, 0.11), (-0.06, 0.03)], 0.006)
def ray_side(p0, sgn):
    a = np.array(apex); b = np.array(p0, float)
    n = np.array([b[1] - a[1], a[0] - b[0]]); n /= np.linalg.norm(n)
    return lambda p: sgn * ((p - a) @ n)
mus('Deltoid, front', 'upperarm', inter(delt, ray_side((0.0, -0.075), 1)), 'frontDelts', fiber=('to', apex), height=0.006,
    attach=(('clavL', 'clavicle.L____tail', (0.0, 0.0, 0.04)), ('uarmL', 'upperarm01.L____head', (0.03, -0.12, 0.02))), segs=('upperarm', 'trunk'))
mus('Deltoid, side', 'upperarm', inter(delt, lambda p: np.maximum(ray_side((0.0, -0.075), -1)(p), ray_side((0.085, -0.075), 1)(p))), 'sideDelts', fiber=('to', apex), height=0.007,
    attach=(('clavL', 'clavicle.L____tail', (0.03, 0.02, 0.0)), ('uarmL', 'upperarm01.L____head', (0.03, -0.12, 0.0))), segs=('upperarm', 'trunk'))
mus('Deltoid, rear', 'upperarm', inter(delt, ray_side((0.085, -0.075), -1)), 'rearDelts', fiber=('to', apex), height=0.006,
    attach=(('clavL', 'clavicle.L____tail', (0.0, 0.0, -0.05)), ('uarmL', 'upperarm01.L____head', (0.03, -0.12, -0.01))), segs=('upperarm', 'trunk'))
BI_A = (('clavL', 'clavicle.L____tail', (0.0, -0.03, 0.03)), ('farmL', 'lowerarm01.L____head', (0.0, -0.04, 0.025)))
mus('Biceps, long head', 'upperarm', spindle((0.012, 0.09), (0.0, 0.25), 0.012, 0.022, 0.006), 'biceps', height=0.007, attach=BI_A)
mus('Biceps, short head', 'upperarm', spindle((-0.03, 0.09), (-0.012, 0.25), 0.011, 0.02, 0.006), 'biceps', height=0.007, attach=BI_A)
mus('Brachialis', 'upperarm', wrap(lambda p: np.minimum(spindle((0.05, 0.12), (0.035, 0.255), 0.006, 0.014, 0.006)(p), spindle((-0.06, 0.15), (-0.04, 0.255), 0.006, 0.012, 0.005)(p)), P_ARM), 'biceps',
    height=0.004, attach=(('uarmL', 'upperarm01.L____head', (0.0, -0.14, 0.02)), ('farmL', 'lowerarm01.L____head', (0.0, -0.03, 0.02))))
TRI_A = (('clavL', 'clavicle.L____tail', (0.0, -0.05, -0.05)), ('uarmL', 'lowerarm01.L____head', (0.0, 0.03, -0.04)), ('farmL', 'lowerarm01.L____head', (0.0, 0.0, -0.035)))  # over the elbow
mus('Triceps, lateral head', 'upperarm', wrap(spindle((0.095, 0.05), (0.115, 0.2), 0.01, 0.022, 0.012), P_ARM), 'triceps', height=0.006, attach=TRI_A)
mus('Triceps, long head', 'upperarm', wrap(spindle((0.165, 0.03), (0.155, 0.2), 0.012, 0.024, 0.012), P_ARM), 'triceps', height=0.006, attach=TRI_A)
mus('Triceps, medial head', 'upperarm', wrap(spindle((-0.105, 0.15), (-0.09, 0.245), 0.006, 0.013, 0.006), P_ARM), 'triceps', height=0.004, attach=TRI_A)
mus('Triceps tendon', 'upperarm', wrap(poly([(0.1, 0.195), (0.19, 0.2), (0.17, 0.27), (0.12, 0.27)], 0.004), P_ARM), kind='tendon', height=0)

# ---------------- Forearm (u: palm side 0, + thumb side; v: elbow 0 to wrist 0.27) ----------------
mus('Brachioradialis', 'forearm', spindle((0.05, -0.05), (0.04, 0.17), 0.008, 0.017, 0.006), 'forearms', height=0.005,
    attach=(('uarmL', 'lowerarm01.L____head', (0.03, 0.06, 0.0)), ('farm2L', 'wrist.L____head', (0.0, 0.03, 0.02))), segs=('forearm', 'upperarm'))
FLEX_A = (('uarmL', 'lowerarm01.L____head', (-0.03, 0.0, 0.0)), ('handL', 'wrist.L____head', (-0.02, -0.03, 0.0)))
EXT_A = (('uarmL', 'lowerarm01.L____head', (0.03, 0.0, -0.01)), ('handL', 'wrist.L____head', (0.02, -0.03, 0.0)))
mus('Wrist flexors, radial', 'forearm', spindle((-0.005, 0.01), (0.012, 0.17), 0.008, 0.015, 0.004), 'forearms', height=0.004, attach=FLEX_A)
mus('Wrist flexors, ulnar', 'forearm', spindle((-0.045, 0.0), (-0.035, 0.17), 0.009, 0.016, 0.004), 'forearms', height=0.004, attach=FLEX_A)
mus('Wrist extensors, radial', 'forearm', wrap(spindle((0.085, -0.01), (0.09, 0.16), 0.008, 0.014, 0.005), P_FORE), 'forearms', height=0.004, attach=EXT_A)
mus('Finger extensors', 'forearm', wrap(spindle((0.125, 0.01), (0.122, 0.18), 0.007, 0.013, 0.005), P_FORE), 'forearms', height=0.0035, attach=EXT_A)
mus('Wrist extensors, ulnar', 'forearm', wrap(spindle((-0.09, 0.01), (-0.085, 0.17), 0.007, 0.013, 0.005), P_FORE), 'forearms', height=0.0035, attach=EXT_A)
mus('Wrist tendons', 'forearm', wrap(poly([(-0.13, 0.19), (0.13, 0.19), (0.13, 0.29), (-0.13, 0.29)], 0.0), P_FORE), kind='tendon', height=0)

# ---------------- Thigh (u: front 0, + outer; v: hip 0 to knee 0.43) ----------------
KNEE_VIA = ('thighL', 'lowerleg01.L____head', (0.0, 0.03, 0.065))  # over the kneecap
QUAD_A = (('hips', 'upperleg01.L____head', (0.0, 0.05, 0.06)), KNEE_VIA, ('shinL', 'lowerleg01.L____head', (0.0, -0.05, 0.05)))
mus('Rectus femoris', 'thigh', spindle((-0.004, 0.05), (-0.002, 0.36), 0.01, 0.025, 0.011), 'quads', height=0.008, attach=QUAD_A)
mus('Vastus lateralis', 'thigh', poly([(0.024, 0.15), (0.05, 0.085), (0.105, 0.085), (0.135, 0.19), (0.133, 0.31), (0.108, 0.385), (0.07, 0.408), (0.035, 0.38), (0.026, 0.27)], 0.012), 'quads', height=0.008,
    attach=(('thighL', 'upperleg01.L____head', (0.05, -0.08, 0.0)), KNEE_VIA, QUAD_A[2]))
mus('Vastus medialis', 'thigh', poly([(-0.03, 0.215), (-0.055, 0.24), (-0.088, 0.31), (-0.088, 0.38), (-0.06, 0.41), (-0.03, 0.4), (-0.024, 0.33)], 0.012), 'quads', height=0.008,
    attach=(('thighL', 'upperleg01.L____head', (-0.02, -0.15, 0.02)), KNEE_VIA, QUAD_A[2]))
mus('Quadriceps tendon', 'thigh', poly([(-0.02, 0.37), (0.035, 0.37), (0.03, 0.44), (-0.016, 0.44)], 0.006), kind='tendon', height=0)
mus('Sartorius', 'thigh', lambda p: np.minimum(spindle((0.075, -0.02), (-0.04, 0.12), 0.01, 0.011, 0.01)(p), spindle((-0.04, 0.12), (-0.115, 0.43), 0.01, 0.01, 0.007)(p)), 'hipFlexors',
    fiber=('along', (-0.16, 0.42)), height=0.004, over=0.006,
    attach=(('hips', 'upperleg01.L____head', (0.05, 0.07, 0.07)), ('shinL', 'lowerleg01.L____head', (-0.04, -0.06, 0.0))))
mus('Adductors', 'thigh', wrap(poly([(-0.06, 0.02), (-0.19, 0.0), (-0.2, 0.2), (-0.13, 0.27), (-0.085, 0.2)], 0.008), P_THIGH), 'adductors',
    fiber=('along', (0.03, 1)), height=0.005,
    attach=(('hips', 'root____head', (0.03, -0.1, 0.06)), ('thighL', 'upperleg01.L____head', (-0.02, -0.25, 0.0))))
mus('Gracilis', 'thigh', wrap(spindle((-0.205, 0.02), (-0.16, 0.42), 0.01, 0.013, 0.006), P_THIGH), 'adductors', height=0.003)
mus('Tensor fasciae latae', 'thigh', spindle((0.09, -0.04), (0.11, 0.1), 0.012, 0.02, 0.01), 'abductors', height=0.005, segs=('thigh', 'trunk'))
mus('Iliotibial band', 'thigh', wrap(poly([(0.115, 0.1), (0.15, 0.1), (0.14, 0.43), (0.11, 0.43)], 0.004), P_THIGH), kind='tendon', height=0)
HAM_A = (('hips', 'root____head', (0.07, -0.08, -0.08)), ('shinL', 'lowerleg01.L____head', (0.0, -0.05, -0.05)))
mus('Biceps femoris', 'thigh', wrap(spindle((0.2, 0.1), (0.155, 0.41), 0.012, 0.032, 0.01), P_THIGH), 'hamstrings', height=0.006, attach=HAM_A)
mus('Semitendinosus', 'thigh', wrap(spindle((0.25, 0.1), (0.29, 0.41), 0.012, 0.024, 0.008), P_THIGH), 'hamstrings', height=0.0055, attach=HAM_A)
mus('Semimembranosus', 'thigh', wrap(spindle((0.3, 0.16), (0.33, 0.41), 0.01, 0.022, 0.01), P_THIGH), 'hamstrings', height=0.005, attach=HAM_A)

# ---------------- Shin (u: front 0, + outer; v: knee 0 to ankle 0.456) ----------------
CALF_A = (('thighL', 'lowerleg01.L____head', (0.0, 0.03, -0.04)), ('footL', 'foot.L____head', (0.0, -0.03, -0.06)))
mus('Gastrocnemius, inner head', 'shin', wrap(spindle((-0.135, 0.04), (-0.145, 0.24), 0.015, 0.03, 0.01), P_SHIN), 'calves', height=0.007, attach=CALF_A)
mus('Gastrocnemius, outer head', 'shin', wrap(spindle((0.135, 0.04), (0.14, 0.21), 0.014, 0.027, 0.01), P_SHIN), 'calves', height=0.007, attach=CALF_A)
mus('Soleus', 'shin', wrap(lambda p: np.minimum(spindle((-0.1, 0.17), (-0.13, 0.34), 0.01, 0.02, 0.008)(p), spindle((0.1, 0.16), (0.13, 0.33), 0.01, 0.018, 0.008)(p)), P_SHIN), 'calves',
    height=0.004, attach=(('shinL', 'lowerleg01.L____head', (0.0, -0.05, -0.04)), CALF_A[1]))
mus('Achilles tendon', 'shin', wrap(poly([(0.155, 0.28), (0.19, 0.28), (0.183, 0.47), (0.163, 0.47)], 0.004), P_SHIN), kind='tendon', height=0)
mus('Tibialis anterior', 'shin', spindle((0.018, 0.05), (0.0, 0.35), 0.009, 0.018, 0.006), None, height=0.005)
mus('Peroneus longus', 'shin', spindle((0.07, 0.03), (0.085, 0.33), 0.007, 0.012, 0.005), None, height=0.0035)
mus('Patellar tendon', 'shin', poly([(-0.018, -0.02), (0.018, -0.02), (0.015, 0.06), (-0.015, 0.06)], 0.004), kind='tendon', height=0)

# Heads of one muscle: the seam between them is faint, not a deep groove.
FAINT_GROUPS = {'Pectoralis major', 'Trapezius', 'Deltoid', 'Biceps', 'Triceps', 'Gastrocnemius'}


def faint(i, j):
    return i >= 0 and j >= 0 and M[i]['group'] == M[j]['group'] and M[i]['group'] in FAINT_GROUPS


CHART_SEGS = {'trunk': ('trunk', 'neck'), 'upperarm': ('upperarm',), 'forearm': ('forearm',), 'thigh': ('thigh',), 'shin': ('shin',)}
