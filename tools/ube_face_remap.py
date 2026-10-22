"""Remap a vanilla-UV face overlay (a SlaveTats face tattoo) onto the UBE 2.0 head's UV layout.

    python tools\\ube_face_remap.py <src.dds> <out.dds> [--preview out.png] [--size N]

Why: SlaveTats paints a face tattoo through the head mesh's UVs. Apropos's face textures are
drawn for the vanilla layout (shared by vanilla, High Poly Head and most replacers); UBE's head
is a different mesh with its own layout, so an unconverted texture lands in the wrong place
(the running-mascara streaks sat on the brow). The Apropos2_UBE set shipped since 1.0016 had the
two cheek-tears files as plain copies; this makes real ones.

How: the two heads stand in the same head-bone space once the vanilla-style mesh is shifted by
(0, -1.55, 120.34) (its raw vertices sit around the bone, UBE's at head height); measured on
the face region, the UBE head lies on High Poly Head within 0.35 units for 90% of its vertices.
So for every texel of the UBE layout: which UBE triangle covers it -> the 3D point on the UBE
head -> the closest point on the High Poly Head surface -> that point's vanilla UV -> the source
texel. High Poly Head is used as the vanilla-UV mesh because it is denser than the vanilla one
(3832 vs 996 vertices) with the same UV layout. Both tri files put v = 0 at the top of the
texture (checked: nose at the centre, top of the skull at v ~0.08 on HPH).

Output: RGBA, unreached texels transparent with the colour dilated a few pixels past every UV
island edge (mip blending), encoded with texconv as BC3 (DXT5 fourcc, full mip chain), the
format the stock files use. --preview draws the result over a UBE face diffuse next to the
source over a vanilla one, red where the overlay has alpha.

Standard library + numpy + Pillow; texconv (DirectXTex) for DDS in and out.
"""
import argparse
import os
import shutil
import struct
import subprocess
import tempfile

import numpy as np
from PIL import Image

MODS = r"E:\nefaram\mods"
HPH_TRI = os.path.join(MODS, r"High Poly Head SE\meshes\KL\High Poly Head\femalehead.tri")
UBE_TRI = os.path.join(MODS, r"[NoDelete][0007] UBE 2.0\meshes\!UBE\Head\FemaleHead.tri")
VANILLA_FACE = os.path.join(MODS, r"[BnP] Main Texture - Frostnip\textures\actors\character\female\femalehead.dds")
UBE_FACE = os.path.join(MODS, r"[NoDelete][0012] 4k UBE Momo Skin Updated compressed\Textures\!UBE\Head\femaleHead_d.dds")
TEXCONV = r"C:\Playground\3.1.0.0\Tools\texconv.exe"
HEAD_SHIFT = np.array([0.0, -1.55, 120.34])   # vanilla-style head raw space -> head-bone space
K_NEAREST = 48
PAD = 4


def read_tri(path):
    """FaceGen FRTRI003: positions, triangles, per-vertex UVs."""
    b = open(path, "rb").read()
    if b[:8] != b"FRTRI003":
        raise ValueError("not a FRTRI003 file: " + path)
    nv, nt, nq, nlv, nls, nuv, ext, nmd, nms, nmsv = struct.unpack_from("<10i", b, 8)
    off = 8 + 40 + 16
    pos = np.frombuffer(b, "<f4", nv * 3, off).reshape(nv, 3).astype(np.float64); off += (nv + nmsv) * 12
    tris = np.frombuffer(b, "<i4", nt * 3, off).reshape(nt, 3).astype(np.int64); off += nt * 12
    uv = np.frombuffer(b, "<f4", nuv * 2, off).reshape(nuv, 2).astype(np.float64); off += nuv * 8
    uv_tris = np.frombuffer(b, "<i4", nt * 3, off).reshape(nt, 3).astype(np.int64)
    if not np.array_equal(uv_tris, tris):
        raise ValueError("uv triangles differ from mesh triangles: " + path)
    return pos, tris, uv


def closest_on_triangles(p, a, b, c):
    """Ericson closest point, vectorized: p (n,1,3) against triangles (n,k,3) -> u, v, w, distance."""
    ab = b - a; ac = c - a; ap = p - a
    d1 = (ab * ap).sum(-1); d2 = (ac * ap).sum(-1)
    bp = p - b
    d3 = (ab * bp).sum(-1); d4 = (ac * bp).sum(-1)
    cp = p - c
    d5 = (ab * cp).sum(-1); d6 = (ac * cp).sum(-1)
    va = d3 * d6 - d5 * d4; vb = d5 * d2 - d1 * d6; vc = d1 * d4 - d3 * d2
    with np.errstate(divide="ignore", invalid="ignore"):
        denom = va + vb + vc
        v = vb / denom; w = vc / denom
        t = (d4 - d3) / ((d4 - d3) + (d5 - d6))
        m = (va <= 0) & (d4 - d3 >= 0) & (d5 - d6 >= 0); v = np.where(m, 1 - t, v); w = np.where(m, t, w)
        t = d2 / (d2 - d6)
        m = (vb <= 0) & (d2 >= 0) & (d6 <= 0); v = np.where(m, 0.0, v); w = np.where(m, t, w)
        t = d1 / (d1 - d3)
        m = (vc <= 0) & (d1 >= 0) & (d3 <= 0); v = np.where(m, t, v); w = np.where(m, 0.0, w)
        m = (d5 >= 0) & (d6 <= d5); v = np.where(m, 0.0, v); w = np.where(m, 1.0, w)
        m = (d3 >= 0) & (d4 <= d3); v = np.where(m, 1.0, v); w = np.where(m, 0.0, w)
        m = (d1 <= 0) & (d2 <= 0); v = np.where(m, 0.0, v); w = np.where(m, 0.0, w)
    v = np.nan_to_num(v); w = np.nan_to_num(w); u = 1.0 - v - w
    q = a * u[..., None] + b * v[..., None] + c * w[..., None]
    d = np.linalg.norm(q - p, axis=-1)
    bad = ~np.isfinite(d) | (np.linalg.norm(np.cross(ab, ac), axis=-1) < 1e-9) | (u < -1e-6) | (v < -1e-6) | (w < -1e-6)
    return u, v, w, np.where(bad, np.inf, d)


def rasterize(uv, tris, W, H):
    """Which triangle covers each texel of a W x H layout (v = 0 at the top), with barycentrics."""
    tri_of = np.full((H, W), -1, np.int64)
    bary = np.zeros((H, W, 3))
    P = uv * np.array([W, H])
    for ti, (i0, i1, i2) in enumerate(tris):
        a, b, c = P[i0], P[i1], P[i2]
        x0 = max(int(np.floor(min(a[0], b[0], c[0]))), 0); x1 = min(int(np.ceil(max(a[0], b[0], c[0]))), W - 1)
        y0 = max(int(np.floor(min(a[1], b[1], c[1]))), 0); y1 = min(int(np.ceil(max(a[1], b[1], c[1]))), H - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        det = (b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])
        if abs(det) < 1e-12:
            continue
        l1 = ((b[0] - xs) * (c[1] - ys) - (c[0] - xs) * (b[1] - ys)) / det
        l2 = ((c[0] - xs) * (a[1] - ys) - (a[0] - xs) * (c[1] - ys)) / det
        l3 = 1.0 - l1 - l2
        eps = -1e-4
        inside = (l1 >= eps) & (l2 >= eps) & (l3 >= eps)
        if not inside.any():
            continue
        yy, xx = np.nonzero(inside)
        yy += y0; xx += x0
        free = tri_of[yy, xx] < 0
        yy, xx = yy[free], xx[free]
        tri_of[yy, xx] = ti
        bary[yy, xx] = np.stack([l1[inside][free], l2[inside][free], l3[inside][free]], 1)
    return tri_of, bary


def bilinear(img, x, y):
    """img (H,W,C) float, sample at continuous pixel coords (x right, y down), edge clamped."""
    H, W = img.shape[:2]
    x = np.clip(x, 0, W - 1.001); y = np.clip(y, 0, H - 1.001)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int)
    fx = (x - x0)[:, None]; fy = (y - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy)
            + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


def dds_to_rgba(path, size=None):
    tmp = tempfile.mkdtemp(prefix="remap_")
    args = [TEXCONV, "-ft", "png", "-o", tmp, "-y"]
    if size:
        args += ["-w", str(size), "-h", str(size)]
    # texconv keeps a relative input's folders under -o; an absolute input lands flat
    r = subprocess.run(args + [os.path.abspath(path)], capture_output=True, text=True)
    png = os.path.join(tmp, os.path.splitext(os.path.basename(path))[0] + ".png")
    if not os.path.isfile(png):
        raise SystemExit("texconv could not decode %s:\n%s" % (path, (r.stdout or "") + (r.stderr or "")))
    img = np.asarray(Image.open(png).convert("RGBA"), np.float64)
    shutil.rmtree(tmp, ignore_errors=True)
    return img


def rgba_to_dds(img, out_path):
    tmp = tempfile.mkdtemp(prefix="remap_")
    png = os.path.join(tmp, os.path.splitext(os.path.basename(out_path))[0] + ".png")
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGBA").save(png)
    r = subprocess.run([TEXCONV, "-f", "BC3_UNORM", "-dx9", "-m", "0", "-y", "-o", tmp, png], capture_output=True, text=True)
    dds = png[:-4] + ".dds"
    if not os.path.isfile(dds):
        raise SystemExit("texconv could not encode:\n" + (r.stdout or "") + (r.stderr or ""))
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    shutil.move(dds, out_path)
    shutil.rmtree(tmp, ignore_errors=True)


def dilate(img, covered, steps):
    """Spread colour (not alpha) from covered texels into their uncovered neighbours."""
    out = img.copy(); cov = covered.copy()
    for _ in range(steps):
        acc = np.zeros_like(out[..., :3]); cnt = np.zeros(out.shape[:2])
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            sh = np.roll(np.roll(out[..., :3], dy, 0), dx, 1); sc = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += sh * sc[..., None]; cnt += sc
        fill = (~cov) & (cnt > 0)
        out[fill, :3] = acc[fill] / cnt[fill][:, None]
        cov = cov | fill
    return out


def face_island(pos, tris):
    """Triangles of the UV island that holds the nose tip. UV seams split vertices, so the
    islands are the connected components over shared vertex indices; the ears and the lobe
    discs are their own pieces and a face overlay never belongs on them."""
    n = len(pos)
    parent = np.arange(n)

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for a, b, c in tris:
        ra, rb, rc = find(a), find(b), find(c)
        parent[rb] = ra; parent[rc] = ra
    roots = np.array([find(i) for i in range(n)])
    nose = int(np.argmax(pos[:, 1]))
    return roots[tris[:, 0]] == roots[nose]


def remap(src_img, size, log=print):
    hp, ht, huv = read_tri(HPH_TRI)
    hp = hp + HEAD_SHIFT
    up, ut, uuv = read_tri(UBE_TRI)
    keep = face_island(up, ut)
    log("UBE face island: %d of %d triangles" % (int(keep.sum()), len(ut)))
    ut = ut[keep]
    W = H = size
    log("rasterizing %d UBE triangles at %d x %d" % (len(ut), W, H))
    tri_of, bary = rasterize(uuv, ut, W, H)
    covered = tri_of >= 0
    yy, xx = np.nonzero(covered)
    log("  %d texels covered (%.0f%%)" % (len(yy), 100.0 * len(yy) / (W * H)))
    t = tri_of[yy, xx]; b = bary[yy, xx]
    pts = (up[ut[t, 0]] * b[:, :1] + up[ut[t, 1]] * b[:, 1:2] + up[ut[t, 2]] * b[:, 2:3])
    cen = hp[ht].mean(1)
    hn = np.cross(hp[ht[:, 1]] - hp[ht[:, 0]], hp[ht[:, 2]] - hp[ht[:, 0]])
    hn /= np.maximum(np.linalg.norm(hn, axis=1, keepdims=True), 1e-12)
    un = np.cross(up[ut[:, 1]] - up[ut[:, 0]], up[ut[:, 2]] - up[ut[:, 0]])
    un /= np.maximum(np.linalg.norm(un, axis=1, keepdims=True), 1e-12)
    src_uv = np.zeros((len(pts), 2)); dist = np.zeros(len(pts))
    k = min(K_NEAREST, len(ht))
    for s in range(0, len(pts), 512):
        q = pts[s:s + 512]
        dc = np.linalg.norm(q[:, None, :] - cen[None, :, :], axis=-1)
        near = np.argpartition(dc, k - 1, axis=1)[:, :k]
        tri = ht[near]
        a, bb, c = hp[tri[..., 0]], hp[tri[..., 1]], hp[tri[..., 2]]
        u, v, w, d = closest_on_triangles(q[:, None, :], a, bb, c)
        # a surface facing another way than the texel's own triangle (the inner side of an
        # earlobe against the cheek) is not the same skin: refuse it
        facing = (hn[near] * un[t[s:s + 512]][:, None, :]).sum(-1) > 0.2
        d = np.where(facing, d, np.inf)
        best = d.argmin(1); r = np.arange(len(q))
        bt = tri[r, best]
        src_uv[s:s + 512] = (huv[bt[:, 0]] * u[r, best][:, None] + huv[bt[:, 1]] * v[r, best][:, None]
                             + huv[bt[:, 2]] * w[r, best][:, None])
        dist[s:s + 512] = d[r, best]
    ok = np.isfinite(dist)
    log("  UBE -> vanilla surface distance: median %.2f, 90%% %.2f, max %.2f; %d texels face no vanilla skin"
        % (np.median(dist[ok]), np.percentile(dist[ok], 90), dist[ok].max(), int((~ok).sum())))
    sh, sw = src_img.shape[:2]
    samples = bilinear(src_img, src_uv[:, 0] * sw - 0.5, src_uv[:, 1] * sh - 0.5)
    # fade the overlay out where the two skins are far apart (0.6 .. 1.0 units)
    fade = np.clip((1.0 - np.nan_to_num(dist, posinf=9.0)) / 0.4, 0.0, 1.0)
    samples[:, 3] *= fade
    out = np.zeros((H, W, 4))
    out[yy, xx] = samples
    out = dilate(out, covered, PAD)
    return out


def preview(src_img, out_img, path):
    van = dds_to_rgba(VANILLA_FACE, 1024)[..., :3]
    ube = dds_to_rgba(UBE_FACE, 1024)[..., :3]

    def paint(face, ov):
        o = np.asarray(Image.fromarray(np.clip(ov, 0, 255).astype(np.uint8), "RGBA").resize((1024, 1024)), np.float64)
        a = (o[..., 3:4] / 255.0)
        return face * (1 - a) + np.array([255.0, 40.0, 40.0]) * a

    sheet = np.concatenate([paint(van, src_img), paint(ube, out_img)], 1)
    Image.fromarray(sheet.astype(np.uint8)).save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("out")
    ap.add_argument("--size", type=int, default=0, help="output size (default: the source's)")
    ap.add_argument("--preview", default="")
    a = ap.parse_args()
    src = dds_to_rgba(a.src)
    size = a.size or src.shape[0]
    out = remap(src, size)
    rgba_to_dds(out, a.out)
    print("wrote", a.out)
    if a.preview:
        preview(src, out, a.preview)
        print("wrote", a.preview)


if __name__ == "__main__":
    main()
