"""Adds detail where the muscles are, without cracks.

MakeHuman spends most of its vertices on the face, hands, and feet; the
trunk and limbs are coarse. Here each quad of the trunk and limbs is split
into four. A neighbouring quad that is not split gets the new points on
its shared edges too, and is fanned from its centre, so the surface stays
closed. New points sit on a curved surface through the old ones (Phong
tessellation), which also rounds off the outline.
"""

import numpy as np


def _phong(q, ps, ns, alpha=0.75):
    """[q] moved toward the curved surface through points [ps] with
    normals [ns]: the mean of its projections onto their tangent planes."""
    proj = [q - np.dot(q - p, n) * n for p, n in zip(ps, ns)]
    return (1 - alpha) * q + alpha * np.mean(proj, axis=0)


def refine(pos, nrm, quads, seg, split):
    """[quads]: list of 4 vertex ids. [seg]: segment per vertex.
    [split]: segments whose quads are split. Returns new positions,
    segments, and triangles."""
    pos = list(pos)
    seg = list(seg)
    nrm = np.asarray(nrm)
    mids = {}

    def mid(a, b):
        key = (min(a, b), max(a, b))
        if key not in mids:
            p = _phong((pos[a] + pos[b]) / 2, [pos[a], pos[b]], [nrm[a], nrm[b]])
            mids[key] = len(pos)
            pos.append(p)
            seg.append(seg[a] if seg[a] == seg[b] else seg[a] if seg[a] in split else seg[b])
        return mids[key]

    def centre(q):
        p = _phong(np.mean([pos[i] for i in q], axis=0), [pos[i] for i in q], [nrm[i] for i in q])
        segs = [seg[i] for i in q]
        pos.append(p)
        seg.append(max(set(segs), key=segs.count))
        return len(pos) - 1

    refined = [all(seg[i] in split for i in q) or sum(seg[i] in split for i in q) >= 3 for q in quads]
    for q, r in zip(quads, refined):
        if r:
            for k in range(4):
                mid(q[k], q[(k + 1) % 4])
    tris = []
    for q, r in zip(quads, refined):
        if r:
            c = centre(q)
            m = [mids[(min(q[k], q[(k + 1) % 4]), max(q[k], q[(k + 1) % 4]))] for k in range(4)]
            for k in range(4):
                # Two triangles per small quad, split along the diagonal
                # through the centre.
                a, b, d = q[k], m[k], m[k - 1]
                tris += [(a, b, c), (a, c, d)]
            continue
        # Points already added on this quad's edges by a split neighbour.
        ring = []
        for k in range(4):
            a, b = q[k], q[(k + 1) % 4]
            ring.append(a)
            key = (min(a, b), max(a, b))
            if key in mids:
                ring.append(mids[key])
        if len(ring) == 4:
            d02 = np.linalg.norm(pos[q[0]] - pos[q[2]])
            d13 = np.linalg.norm(pos[q[1]] - pos[q[3]])
            if d02 <= d13:
                tris += [(q[0], q[1], q[2]), (q[0], q[2], q[3])]
            else:
                tris += [(q[0], q[1], q[3]), (q[1], q[2], q[3])]
        else:
            c = centre(q)
            for k in range(len(ring)):
                tris.append((ring[k], ring[(k + 1) % len(ring)], c))
    return np.array(pos), np.array(seg, dtype=object), np.array(tris, dtype=np.int64)
