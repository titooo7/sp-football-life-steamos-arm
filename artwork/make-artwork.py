#!/usr/bin/env python3
"""Original Steam library artwork for SP Football Life <year> (drawn from scratch: night stadium, pitch, title).
Usage: python3 make-artwork.py <year> [out_dir]   e.g. python3 make-artwork.py 2027  -> artwork/2027/
Writes {grid,portrait,hero,logo,icon}.png + logo-position.json, and the same in settings/. Needs Pillow + Fira Sans fonts."""
import sys, os, math, random, json
from PIL import Image, ImageDraw, ImageFilter, ImageFont

F = "/usr/share/fonts/TTF/"
HEAVY = F + "FiraSansCondensed-Heavy.ttf"
XB = F + "FiraSansCondensed-ExtraBold.ttf"
SEMI = F + "FiraSansCondensed-SemiBold.ttf"
RED = (214, 24, 32); WHITE = (255, 255, 255)
YEAR = sys.argv[1] if len(sys.argv) > 1 else "2027"
SEASON = "SEASON %d/%s" % (int(YEAR) - 1, YEAR[2:])


def font(path, size): return ImageFont.truetype(path, max(8, int(size)))


def stadium(w, h, horizon=0.48, seed=7, dark=1.0):
    """Night stadium: dark sky, floodlight glows, crowd band, striped pitch in perspective with lines."""
    rnd = random.Random(seed)
    img = Image.new("RGB", (w, h))
    px = img.load()
    hy = int(h * horizon)
    # sky gradient
    for y in range(hy):
        t = y / max(1, hy)
        c = (int(3 + 10 * t), int(4 + 8 * t), int(10 + 16 * t))
        for x in range(w): px[x, y] = c
    d = ImageDraw.Draw(img)
    # crowd band (stands) with speckle
    sb_top = int(hy - h * 0.16)
    d.rectangle([0, sb_top, w, hy], fill=(22, 18, 26))
    for _ in range(int(w * h * 0.012)):
        x = rnd.randrange(w); y = rnd.randrange(sb_top, hy)
        v = rnd.randrange(30, 90)
        r = v + (40 if rnd.random() < 0.18 else 0)
        px[x, y] = (min(255, r), v // 2, v // 2) if rnd.random() < 0.3 else (v, v, v + 10)
    # red advertising board line
    d.rectangle([0, hy - max(2, h // 140), w, hy], fill=RED)
    # pitch: perspective stripes
    for y in range(hy, h):
        t = (y - hy) / max(1, h - hy)
        depth = 1 / (0.12 + t)                         # perspective: stripes get bigger towards the viewer
        stripe = int(depth * 3) % 2
        g = 38 + int(70 * t) + (12 if stripe else 0)
        c = (int(g * 0.28), g, int(g * 0.30))
        d.line([(0, y), (w, y)], fill=c)
    # pitch lines (halfway line + centre circle in perspective)
    lw = max(2, w // 500)
    cx, cy = w // 2, int(hy + (h - hy) * 0.55)
    d.line([(cx, hy), (cx, h)], fill=(200, 215, 200), width=lw)
    ew, eh = int(w * 0.16), int((h - hy) * 0.22)
    d.ellipse([cx - ew, cy - eh, cx + ew, cy + eh], outline=(230, 240, 230), width=lw)
    d.line([(0, hy + int((h - hy) * 0.08)), (w, hy + int((h - hy) * 0.08))], fill=(210, 225, 210), width=max(1, lw - 1))
    # floodlight glows
    glow = Image.new("RGB", (w, h), (0, 0, 0)); gd = ImageDraw.Draw(glow)
    for fx in (0.06, 0.28, 0.72, 0.94):
        x = int(w * fx); y = int(sb_top - h * 0.10)
        r = int(min(w, h) * 0.09)
        gd.ellipse([x - r, y - r, x + r, y + r], fill=(70, 72, 90))
        # cone of light down to the pitch
        gd.polygon([(x - r // 3, y), (x + r // 3, y), (int(w * 0.5 + (x - w * 0.5) * 0.4) + r * 3, h), (int(w * 0.5 + (x - w * 0.5) * 0.4) - r * 3, h)], fill=(26, 28, 34))
    glow = glow.filter(ImageFilter.GaussianBlur(min(w, h) * 0.04))
    lamps = Image.new("RGB", (w, h), (0, 0, 0)); ld = ImageDraw.Draw(lamps)
    for fx in (0.06, 0.28, 0.72, 0.94):
        x = int(w * fx); y = int(sb_top - h * 0.10); a = max(2, int(min(w, h) * 0.012))
        for k in range(-2, 3):
            for j in range(2):
                ld.rectangle([x + k * a * 2 - a // 2, y + j * a * 2 - a // 2, x + k * a * 2 + a // 2, y + j * a * 2 + a // 2], fill=(255, 255, 245))
    glow = _add(glow, lamps.filter(ImageFilter.GaussianBlur(max(1, a // 3))))
    img = _add(img, glow)
    # red haze over the stands (flares)
    haze = Image.new("RGB", (w, h), (0, 0, 0)); hd = ImageDraw.Draw(haze)
    for _ in range(6):
        x = rnd.randrange(w); r = int(h * 0.12)
        hd.ellipse([x - r, sb_top - r // 2, x + r, hy + r // 3], fill=(150, 20, 15))
    haze = haze.filter(ImageFilter.GaussianBlur(h * 0.06))
    img = _add(img, haze)
    # vignette
    vig = Image.new("L", (w, h), 0); vd = ImageDraw.Draw(vig)
    vd.ellipse([-w * 0.25, -h * 0.35, w * 1.25, h * 1.35], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(min(w, h) * 0.15))
    img = Image.composite(img, Image.new("RGB", (w, h), (0, 0, 0)), vig)
    # dark band at the bottom so a title stays readable over the pitch lines
    band = Image.new("L", (w, h), 0); bd = ImageDraw.Draw(band)
    for y in range(int(h * 0.55), h):
        bd.line([(0, y), (w, y)], fill=int(200 * max(0.0, (y - h * 0.55) / (h * 0.45)) ** 1.4))
    img = Image.composite(Image.new("RGB", (w, h), (4, 6, 8)), img, band)
    if dark < 1.0:
        img = Image.blend(Image.new("RGB", (w, h), (0, 0, 0)), img, dark)
    return img


def _add(a, b):
    from PIL import ImageChops
    return ImageChops.add(a, b)


def title_block(width, settings=False):
    """Transparent title: 'SP FOOTBALL LIFE' white + red box with the year (+ 'SETTINGS' line)."""
    s = width / 900
    big = font(HEAVY, 120 * s); small = font(SEMI, 40 * s)
    t1, t2 = "SP FOOTBALL LIFE", YEAR
    tmp = ImageDraw.Draw(Image.new("L", (1, 1)))
    b1 = tmp.textbbox((0, 0), t1, font=big); b2 = tmp.textbbox((0, 0), t2, font=big)
    pad = int(18 * s); gap = int(22 * s)
    w1, w2 = b1[2] - b1[0], b2[2] - b2[0]
    th = max(b1[3], b2[3]) - min(b1[1], b2[1])
    W = w1 + gap + w2 + 2 * pad + pad
    sub = "SETTINGS" if settings else SEASON
    bs = tmp.textbbox((0, 0), sub, font=small); sh = bs[3] - bs[1]
    H = th + 2 * pad + sh + int(16 * s)
    img = Image.new("RGBA", (W + 8, H + 8), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    top = int(4 * s)
    # red box for the year
    bx0 = w1 + gap
    d.rectangle([bx0, top, bx0 + w2 + 2 * pad, top + th + 2 * pad], fill=RED)
    d.text((0 - b1[0], top + pad - b1[1]), t1, font=big, fill=WHITE)
    d.text((bx0 + pad - b2[0], top + pad - b2[1]), t2, font=big, fill=WHITE)
    # thin red underline + subtitle
    ly = top + th + 2 * pad + int(6 * s)
    d.rectangle([0, ly, bx0 - int(8 * s), ly + max(2, int(4 * s))], fill=RED)
    d.text((bx0 + w2 + 2 * pad - (bs[2] - bs[0]) - bs[0], ly + int(8 * s) - bs[1]), sub, font=small, fill=(235, 235, 235))
    # soft shadow for legibility on any background
    a = img.split()[3]
    sh_img = Image.new("RGBA", img.size, (0, 0, 0, 0)); sh_img.putalpha(a.filter(ImageFilter.GaussianBlur(6 * s)).point(lambda v: v * 0.8))
    out = Image.alpha_composite(sh_img, img)
    return out.crop(out.getbbox())


def gear(d, cx, cy, r, color, width=None, hole=(12, 12, 14)):
    """Solid gear: 8 square teeth, body, round hole (hole drawn in the given colour)."""
    teeth = 8; tw = r * 0.42
    for k in range(teeth):
        a = 2 * math.pi * k / teeth; ca, sa = math.cos(a), math.sin(a)
        pts = []
        for (u, v) in ((0.70, -tw / 2), (1.18, -tw / 2), (1.18, tw / 2), (0.70, tw / 2)):
            pts.append((cx + ca * r * u - sa * v, cy + sa * r * u + ca * v))
        d.polygon(pts, fill=color)
    d.ellipse([cx - r * 0.92, cy - r * 0.92, cx + r * 0.92, cy + r * 0.92], fill=color)
    d.ellipse([cx - r * 0.36, cy - r * 0.36, cx + r * 0.36, cy + r * 0.36], fill=hole)


def place(bg, logo, rel_w, ax, ay, settings=False):
    lw = int(bg.width * rel_w); lh = int(logo.height * lw / logo.width)
    lg = logo.resize((lw, lh), Image.LANCZOS)
    x = int((bg.width - lw) * ax); y = int((bg.height - lh) * ay)
    bg = bg.convert("RGBA"); bg.alpha_composite(lg, (x, y)); return bg.convert("RGB")


def icon(size, settings=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    m = size * 0.03; r = size * 0.14
    d.rounded_rectangle([m, m, size - m, size - m], r, fill=(12, 12, 14), outline=RED, width=max(2, int(size * 0.035)))
    if settings:
        gear(d, size / 2, size * 0.40, size * 0.22, WHITE)
        f = font(HEAVY, size * 0.2); t = "FL" + YEAR[2:]
        b = d.textbbox((0, 0), t, font=f); d.text(((size - (b[2] - b[0])) / 2 - b[0], size * 0.70 - b[1]), t, font=f, fill=RED)
        return img
    f = font(HEAVY, size * 0.47)
    for t, yy, col in (("FL", 0.10, WHITE), (YEAR[2:], 0.49, RED)):
        b = d.textbbox((0, 0), t, font=f); d.text(((size - (b[2] - b[0])) / 2 - b[0], size * yy - b[1]), t, font=f, fill=col)
    return img


def make(out, settings=False):
    os.makedirs(out, exist_ok=True)
    dark = 0.55 if settings else 1.0
    logo_big = title_block(1800, settings)
    # grid (horizontal capsule) 920x430
    g = place(stadium(920, 430, 0.50, 11, dark), logo_big, 0.80, 0.5, 0.86)
    if settings: gear(ImageDraw.Draw(g), 460, 150, 72, WHITE, hole=(8, 9, 16))
    g.save(f"{out}/grid.png")
    # portrait 600x900
    p = stadium(600, 900, 0.42, 5, dark)
    p = p.convert("RGBA"); p.alpha_composite(icon(340, settings), (130, 120)); p = p.convert("RGB")
    p = place(p, logo_big, 0.90, 0.5, 0.93)
    p.save(f"{out}/portrait.png")
    # hero 3840x1240 (no text: Steam draws the logo on top, bottom-left)
    stadium(3840, 1240, 0.46, 3, dark).save(f"{out}/hero.png")
    # logo (transparent)
    logo_big.save(f"{out}/logo.png")
    json.dump({"nVersion": 1, "logoPosition": {"pinnedPosition": "BottomLeft", "nWidthPct": 50, "nHeightPct": 50}},
              open(f"{out}/logo-position.json", "w"), separators=(",", ":"))
    icon(512 if settings else 256, settings).save(f"{out}/icon.png")


if __name__ == "__main__":
    o = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), YEAR)
    make(o); make(os.path.join(o, "settings"), settings=True)
