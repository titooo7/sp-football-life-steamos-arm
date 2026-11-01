#!/usr/bin/env python3
"""Rebuild artwork/2027/{grid,portrait,hero}.png: player cut-outs placed on the stadium drawn by make-artwork.py.
Usage: python3 compose-players.py <cutout_dir> [out_dir]
<cutout_dir> holds Diomande.png, Bellingham.png, Vinicius.png, Mbappe.png, Yamal.png, Kane.png, Haaland.png: transparent
cut-outs of the Wikimedia Commons photos listed in 2027/CREDITS.md (made with rembg, model birefnet-portrait; they
are not stored in the repo). Logo, icon, logo-position.json and settings/ come from make-artwork.py and are not touched."""
import importlib.util, os, sys
from PIL import Image, ImageFilter, ImageDraw, ImageChops

REPO_ART = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("mk", f"{REPO_ART}/make-artwork.py")
_argv = sys.argv; sys.argv = ["x", "2027"]
mk = importlib.util.module_from_spec(spec); spec.loader.exec_module(mk); sys.argv = _argv

CUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else sys.exit(__doc__)
OUT = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(REPO_ART, "2027")


def head_height(im):
    """Height of the head (top of hair to neck) in px: the first blob before the shoulders widen."""
    a = im.split()[3].point(lambda v: 255 if v > 128 else 0)
    w, h = a.size; px = a.load(); hm = 0; top = None
    for y in range(h):
        xs = [x for x in range(0, w, 2) if px[x, y]]
        if not xs: continue
        width = xs[-1] - xs[0]
        if top is None: top = y
        if y - top > h * 0.03 and width > 1.8 * max(hm, 1): return y - top
        hm = max(hm, width)
    return h * 0.2


def load(name, head_px):
    im = Image.open(f"{CUT}/{name}.png").convert("RGBA")
    s = head_px / head_height(im)
    return im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)


def fade_bottom(im, frac=0.30):
    """Fade the lower part of a figure to transparent, so every player melts into the dark bottom band."""
    w, h = im.size; m = Image.new("L", (w, h), 255); d = ImageDraw.Draw(m)
    y0 = int(h * (1 - frac))
    for y in range(y0, h): d.line([(0, y), (w, y)], fill=int(255 * (1 - (y - y0) / max(1, h - y0)) ** 1.2))
    a = ImageChops.multiply(im.split()[3], m); im = im.copy(); im.putalpha(a); return im


def paste_player(bg, im, cx, top, dim=1.0, glow=True):
    """Paste with a soft dark shadow and a faint red rim light; dim<1 darkens players in the back row."""
    if dim < 1.0:
        rgb = Image.blend(Image.new("RGB", im.size, (0, 0, 0)), im.convert("RGB"), dim); a = im.split()[3]
        im = rgb.convert("RGBA"); im.putalpha(a)
    x = int(cx - im.width / 2); y = int(top)
    a = im.split()[3]
    if glow:
        r = max(4, im.width // 30)
        rim = Image.new("RGBA", im.size, mk.RED + (0,)); rim.putalpha(a.filter(ImageFilter.GaussianBlur(r)).point(lambda v: int(v * 0.55)))
        bg.alpha_composite(rim, (x, y))
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0)); sh.putalpha(a.filter(ImageFilter.GaussianBlur(max(3, im.width // 40))).point(lambda v: int(v * 0.7)))
    bg.alpha_composite(sh, (x + im.width // 60, y + im.width // 80))
    bg.alpha_composite(im, (x, y))


def bottom_band(bg, start=0.62, strength=235):
    w, h = bg.size; m = Image.new("L", (w, h), 0); d = ImageDraw.Draw(m)
    for y in range(int(h * start), h): d.line([(0, y), (w, y)], fill=int(strength * max(0.0, (y - h * start) / (h * (1 - start))) ** 1.3))
    dark = Image.new("RGBA", (w, h), (4, 6, 8, 255)); bg.paste(dark, (0, 0), m)


# back-to-front drawing order; Yamal in the centre, front
ORDER = ["Diomande", "Haaland", "Kane", "Vinicius", "Bellingham", "Mbappe", "Yamal"]


def lineup(bg, positions, head):
    """positions: {name: (cx_frac, top_frac, scale, dim)} drawn in ORDER."""
    W, H = bg.size
    for n in ORDER:
        if n not in positions: continue
        cx, top, sc, dim = positions[n]
        im = fade_bottom(load(n, head * sc))
        paste_player(bg, im, W * cx, H * top, dim)


def make():
    os.makedirs(OUT, exist_ok=True)
    logo = mk.title_block(1800)
    # HERO 3840x1240 (Steam puts the logo bottom-left, so the players lean to the right)
    hero = mk.stadium(3840, 1240, 0.46, 3).convert("RGBA")
    lineup(hero, {
        "Diomande": (0.27, 0.10, 0.92, 0.80), "Haaland": (0.95, 0.08, 0.95, 0.80),
        "Kane": (0.39, 0.06, 0.97, 0.88), "Vinicius": (0.84, 0.05, 0.98, 0.88),
        "Bellingham": (0.51, 0.03, 1.03, 0.95), "Mbappe": (0.73, 0.03, 1.03, 0.95),
        "Yamal": (0.62, 0.01, 1.10, 1.0)}, head=330)
    bottom_band(hero, 0.62, 225); hero.convert("RGB").save(f"{OUT}/hero.png")
    # GRID 920x430: all seven behind the title
    grid = mk.stadium(920, 430, 0.50, 11).convert("RGBA")
    lineup(grid, {
        "Diomande": (0.08, 0.13, 0.90, 0.80), "Haaland": (0.92, 0.10, 0.93, 0.80),
        "Kane": (0.22, 0.09, 0.95, 0.88), "Vinicius": (0.78, 0.08, 0.96, 0.88),
        "Bellingham": (0.35, 0.05, 1.0, 0.95), "Mbappe": (0.65, 0.05, 1.0, 0.95),
        "Yamal": (0.50, 0.02, 1.08, 1.0)}, head=58)
    bottom_band(grid, 0.55, 240)
    grid = mk.place(grid.convert("RGB"), logo, 0.80, 0.5, 0.93); grid.save(f"{OUT}/grid.png")
    # PORTRAIT 600x900: Yamal front, Mbappe + Bellingham beside him, the other four behind
    por = mk.stadium(600, 900, 0.42, 5).convert("RGBA")
    lineup(por, {
        "Diomande": (0.12, 0.22, 0.80, 0.70), "Haaland": (0.88, 0.21, 0.82, 0.70),
        "Kane": (0.31, 0.19, 0.85, 0.78), "Vinicius": (0.69, 0.18, 0.85, 0.78),
        "Bellingham": (0.18, 0.32, 1.0, 0.95), "Mbappe": (0.82, 0.32, 1.0, 0.95),
        "Yamal": (0.50, 0.34, 1.12, 1.0)}, head=100)
    bottom_band(por, 0.70, 245)
    por = mk.place(por.convert("RGB"), logo, 0.90, 0.5, 0.95); por.save(f"{OUT}/portrait.png")


if __name__ == "__main__":
    make()
