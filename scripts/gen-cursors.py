#!/usr/bin/env python3
# Uso: python3 scripts/gen-cursors.py assets/cursors/Construct   (necesita python-pillow)
# Genera el tema de cursor "Construct" (Xcursor): fósforo con contorno negro, estilo HUD. Original.
import os, struct, math, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
SIZES = [24, 32, 48, 64]
SS = 8                      # supermuestreo: se dibuja 8× y se reduce (bordes suaves)
U = 32.0                    # cuadrícula de diseño 32×32 (la misma del canvas)

ACCENT = (57, 255, 136, 255)    # #39ff88
BRIGHT = (234, 255, 242, 255)   # #eafff2
MAGENTA = (255, 46, 136, 255)   # #ff2e88
DARK = (2, 4, 3, 255)           # #020403
OUTLINE = 1.6                   # contorno negro (en unidades de la cuadrícula)

def canvas(size):
    return Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))

def S(size):
    return size * SS / U

def P(size, pts):
    s = S(size)
    return [(x * s, y * s) for x, y in pts]

def W(size, w):
    return max(1, round(w * S(size)))

def rot(pts, deg, c=(16, 16)):
    a = math.radians(deg)
    return [(c[0] + (x - c[0]) * math.cos(a) - (y - c[1]) * math.sin(a),
             c[1] + (x - c[0]) * math.sin(a) + (y - c[1]) * math.cos(a)) for x, y in pts]

# ── Primitivas: siempre primero el negro engordado y luego el color encima ──
def solid(d, size, pts, fill=ACCENT):
    p = P(size, pts)
    d.polygon(p, fill=DARK, outline=DARK, width=W(size, OUTLINE * 2))
    d.polygon(p, fill=fill)

def hollow(d, size, pts, line=ACCENT, w=1.8):
    p = P(size, pts)
    d.polygon(p, fill=DARK, outline=DARK, width=W(size, w + OUTLINE * 2))
    d.polygon(p, fill=DARK, outline=line, width=W(size, w))

def lines(d, size, segs, color=ACCENT, w=2.0):
    for layer, width in ((DARK, w + OUTLINE * 2), (color, w)):
        for seg in segs:
            d.line(P(size, seg), fill=layer, width=W(size, width), joint="curve")

def box(d, size, x0, y0, x1, y1, color=ACCENT, outline=1.0):
    s = S(size)
    if outline:
        o = outline
        d.rectangle([(x0 - o) * s, (y0 - o) * s, (x1 + o) * s, (y1 + o) * s], fill=DARK)
    d.rectangle([x0 * s, y0 * s, x1 * s, y1 * s], fill=color)

def ring(d, size, cx, cy, r, w, frame):
    s = S(size)
    bb = [(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s]
    for layer in ("dark", "color"):
        for i in range(8):
            a0 = i * 45 + 6 + frame * 45
            a1 = i * 45 + 39 + frame * 45
            if layer == "dark":
                d.arc(bb, a0 - 3, a1 + 3, fill=DARK, width=W(size, w + OUTLINE * 2))
            else:
                k = (i - frame) % 8           # 0 = cabeza (la más brillante)
                col = BRIGHT if k == 0 else ACCENT[:3] + (int(255 * (1 - k * 0.1)),)
                d.arc(bb, a0, a1, fill=col, width=W(size, w))

# ── Formas (las del canvas) ──
ARROW = [(4, 2), (4, 25), (9.6, 19.8), (13.3, 28), (17.2, 26.2), (13.5, 18.3), (21, 18.3)]
ARROW_S = [(3, 2), (3, 18), (7, 14.3), (9.6, 20), (12.3, 18.8), (9.7, 13.2), (15, 13.2)]
DBL = [(16, 3), (22, 10), (18, 10), (18, 22), (22, 22), (16, 29), (10, 22), (14, 22), (14, 10), (10, 10)]
MOVE = [(16, 2), (21, 8), (18, 8), (18, 14), (24, 14), (24, 11), (30, 16), (24, 21), (24, 18), (18, 18), (18, 24), (21, 24),
        (16, 30), (11, 24), (14, 24), (14, 18), (8, 18), (8, 21), (2, 16), (8, 11), (8, 14), (14, 14), (14, 8), (11, 8)]

def c_default(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    solid(d, size, ARROW)
    d.line(P(size, [(6.4, 8), (6.4, 18.5)]), fill=DARK[:3] + (115,), width=W(size, 1))   # scanline interior
    lines(d, size, [[(1, 2), (1, 7)]], w=1.4)                                                # marca de HUD
    return img, (4, 2)

def c_pointer(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    hollow(d, size, ARROW)
    box(d, size, 7, 11, 10, 14, outline=0)
    lines(d, size, [[(19, 2), (23, 2), (23, 6)], [(23, 10), (23, 14)]], w=1.6)              # corchete de mira
    return img, (4, 2)

def c_text(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    lines(d, size, [[(11, 4), (15, 4), (16, 5), (17, 4), (21, 4)], [(16, 5), (16, 27)],
                    [(11, 28), (15, 28), (16, 27), (17, 28), (21, 28)]])
    box(d, size, 18.5, 13, 21, 19)                                                           # bloque de terminal
    return img, (16, 16)

def c_cross(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    lines(d, size, [[(16, 2), (16, 11)], [(16, 21), (16, 30)], [(2, 16), (11, 16)], [(21, 16), (30, 16)],
                    [(6, 9), (6, 6), (9, 6)], [(23, 6), (26, 6), (26, 9)],
                    [(6, 23), (6, 26), (9, 26)], [(23, 26), (26, 26), (26, 23)]], w=1.6)
    box(d, size, 15, 15, 17, 17, MAGENTA, outline=0.6)
    return img, (16, 16)

def c_progress(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    solid(d, size, ARROW_S)
    ring(d, size, 24, 24, 5.5, 2, f)
    return img, (3, 2)

def c_wait(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    ring(d, size, 16, 16, 10, 3, f)
    box(d, size, 14.5, 14.5, 17.5, 17.5)
    return img, (16, 16)

def c_move(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    solid(d, size, MOVE)
    return img, (16, 16)

def c_resize(deg):
    def fn(size, f):
        img = canvas(size); d = ImageDraw.Draw(img)
        solid(d, size, rot(DBL, deg))
        return img, (16, 16)
    return fn

def c_forbidden(size, f):
    img = canvas(size); d = ImageDraw.Draw(img)
    s = S(size)
    bb = [6 * s, 6 * s, 26 * s, 26 * s]
    d.ellipse(bb, outline=DARK, width=W(size, 2.6 + OUTLINE * 2))
    d.line(P(size, [(9, 9), (23, 23)]), fill=DARK, width=W(size, 2.6 + OUTLINE * 2))
    d.ellipse(bb, outline=MAGENTA, width=W(size, 2.6))
    d.line(P(size, [(9, 9), (23, 23)]), fill=MAGENTA, width=W(size, 2.6))
    return img, (16, 16)

# ── Formato Xcursor ──
def finish(img, size):
    return img.resize((size, size), Image.LANCZOS)

def argb(img):
    # Xcursor guarda cada píxel como ARGB premultiplicado (little-endian)
    raw = img.tobytes()
    out = bytearray()
    for i in range(0, len(raw), 4):
        r, g, b, a = raw[i], raw[i + 1], raw[i + 2], raw[i + 3]
        out += struct.pack("<I", (a << 24) | ((r * a // 255) << 16) | ((g * a // 255) << 8) | (b * a // 255))
    return bytes(out)

def write_cursor(name, frames_fn, nframes=1, delay=0):
    chunks = []
    for size in SIZES:
        for i in range(nframes):
            img, hot = frames_fn(size, i)
            im = finish(img, size)
            hx, hy = [min(size - 1, int(round(h * size / U))) for h in hot]
            hdr = struct.pack("<9I", 36, 0xfffd0002, size, 1, size, size, hx, hy, delay)
            chunks.append((size, hdr + argb(im)))
    pos = 16 + len(chunks) * 12
    toc, data = b"", b""
    for size, ch in chunks:
        toc += struct.pack("<3I", 0xfffd0002, size, pos)
        pos += len(ch); data += ch
    with open(os.path.join(OUT, "cursors", name), "wb") as f:
        f.write(b"Xcur" + struct.pack("<3I", 16, 0x10000, len(chunks)) + toc + data)

def link(target, *names):
    for n in names:
        p = os.path.join(OUT, "cursors", n)
        if os.path.lexists(p): os.remove(p)
        os.symlink(target, p)

os.makedirs(os.path.join(OUT, "cursors"), exist_ok=True)
with open(os.path.join(OUT, "index.theme"), "w") as f:
    f.write("[Icon Theme]\nName=Construct\nComment=Cursor fósforo de construct (Quickshell, cyberpunk / Matrix)\nInherits=Adwaita\n")

# Nombres alternativos: los mismos que usa ancient
write_cursor("left_ptr", c_default)
link("left_ptr", "default", "arrow", "top_left_arrow", "context-menu", "copy", "alias", "cell", "help", "question_arrow", "dnd-none", "dnd-move", "dnd-copy", "vertical-text")
write_cursor("pointer", c_pointer)
link("pointer", "hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822")
write_cursor("text", c_text)
link("text", "xterm", "ibeam")
write_cursor("crosshair", c_cross)
link("crosshair", "cross", "tcross", "cross_reverse", "diamond_cross")
write_cursor("not-allowed", c_forbidden)
link("not-allowed", "no-drop", "crossed_circle", "forbidden", "circle", "03b6e0fcb3499374a867c041f52298f0")
write_cursor("move", c_move)
link("move", "fleur", "all-scroll", "grab", "grabbing", "closedhand", "openhand", "size_all", "dnd-ask")
write_cursor("ew-resize", c_resize(90))
link("ew-resize", "sb_h_double_arrow", "col-resize", "e-resize", "w-resize", "h_double_arrow", "size_hor", "split_h", "left_side", "right_side")
write_cursor("ns-resize", c_resize(0))
link("ns-resize", "sb_v_double_arrow", "row-resize", "n-resize", "s-resize", "v_double_arrow", "size_ver", "split_v", "top_side", "bottom_side")
write_cursor("nwse-resize", c_resize(-45))
link("nwse-resize", "nw-resize", "se-resize", "bd_double_arrow", "size_fdiag", "top_left_corner", "bottom_right_corner")
write_cursor("nesw-resize", c_resize(45))
link("nesw-resize", "ne-resize", "sw-resize", "fd_double_arrow", "size_bdiag", "top_right_corner", "bottom_left_corner")
write_cursor("wait", c_wait, 8, 80)
link("wait", "watch")
write_cursor("progress", c_progress, 8, 80)
link("progress", "left_ptr_watch", "half-busy", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599")

# Hoja de muestra (para revisar sin instalar): preview.png
if "--preview" in sys.argv:
    fns = [c_default, c_pointer, c_text, c_cross, c_progress, c_wait, c_move, c_resize(0), c_resize(90), c_resize(-45), c_resize(45), c_forbidden]
    sheet = Image.new("RGBA", (12 * 80, 2 * 80 + 10), (11, 20, 16, 255))
    light = Image.new("RGBA", (12 * 80, 80), (220, 228, 222, 255))
    sheet.paste(light, (0, 90))
    for i, fn in enumerate(fns):
        im = finish(fn(64, 0)[0], 64)
        sheet.alpha_composite(im, (i * 80 + 8, 8))
        sheet.alpha_composite(finish(fn(32, 0)[0], 32), (i * 80 + 24, 114))
    sheet.save(os.path.join(OUT, "preview.png"))
print("ok")
