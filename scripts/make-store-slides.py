#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds the App Store marketing slides from raw Simulator screens.

    python3 scripts/make-store-slides.py <raw-dir> <out-dir> <width> <height>

Layout (Quiet Noir): black ground with a soft sand glow; the mascot and the full name
"hYYa Footprint Inspector" at the top; a benefit headline with one sand phrase; three highlight
chips; and the real app screen in a device frame that runs off the bottom edge. The mascot
appears once, in the header lockup (owner: repeating it is overkill). Copy comes from
store/slides.json.
"""
import json, re, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = "/System/Library/Fonts/SFNS.ttf"
SAND = (210, 174, 136)
SAND_DEEP = (143, 117, 96)
INK = (245, 245, 247)
MUTED = (161, 161, 168)
MASCOT = ROOT / "App/Resources/Assets.xcassets/MascotCutout.imageset/mascot-cutout.png"


def font(size, weight="Bold"):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def glow_background(w, h):
    bg = Image.new("RGB", (w, h), (0, 0, 0))
    layer = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((-w * 0.3, -h * 0.18, w * 1.3, h * 0.38), fill=(36, 28, 20))
    d.ellipse((w * 0.2, h * 0.82, w * 1.4, h * 1.25), fill=(22, 16, 13))
    return Image.blend(bg, layer.filter(ImageFilter.GaussianBlur(w * 0.16)), 1.0)


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def device(screen, width):
    """The screen in a slim titanium-dark frame."""
    s = screen.convert("RGB")
    scale = width / s.width
    s = s.resize((width, int(s.height * scale)), Image.LANCZOS)
    tablet = s.width / s.height > 0.6
    bezel = int(width * (0.016 if tablet else 0.022))
    r = int(width * (0.035 if tablet else 0.115))
    frame = Image.new("RGBA", (s.width + bezel * 2, s.height + bezel * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), r + bezel, fill=(38, 36, 34))
    d.rounded_rectangle((2, 2, frame.width - 3, frame.height - 3), r + bezel - 2, outline=(110, 96, 82), width=3)
    frame.alpha_composite(rounded(s, r), (bezel, bezel))
    return frame


def draw_headline(d, text, x, y, max_w, size):
    """Wraps the headline; *starred* words are sand."""
    f = font(size, "Bold")
    tokens = []
    for part in re.split(r"(\*[^*]+\*)", text):
        if not part:
            continue
        accent = part.startswith("*")
        for word in part.strip("*").split(" "):
            if word:
                tokens.append((word, accent))
    lines, cur, cur_w = [], [], 0
    space = d.textlength(" ", font=f)
    for word, accent in tokens:
        wl = d.textlength(word, font=f)
        if cur and cur_w + space + wl > max_w:
            lines.append(cur); cur, cur_w = [], 0
        cur.append((word, accent)); cur_w += (space if cur_w else 0) + wl
    if cur:
        lines.append(cur)
    line_h = int(size * 1.12)
    for i, line in enumerate(lines):
        cx = x
        for word, accent in line:
            d.text((cx, y + i * line_h), word, font=f, fill=SAND if accent else INK)
            cx += d.textlength(word + " ", font=f)
    return y + len(lines) * line_h


def chips(d, items, x, y, max_w, size):
    f = font(size, "Semibold")
    pad_x, pad_y, gap = int(size * 0.75), int(size * 0.42), int(size * 0.45)
    cx, cy = x, y
    h = size + pad_y * 2
    for text in items:
        w = d.textlength(text, font=f) + pad_x * 2 + size * 0.75
        if cx > x and cx + w > x + max_w:
            cx, cy = x, cy + h + gap
        d.rounded_rectangle((cx, cy, cx + w, cy + h), h // 2, fill=(26, 22, 18), outline=SAND_DEEP, width=2)
        dot = size * 0.32
        d.ellipse((cx + pad_x, cy + h / 2 - dot / 2, cx + pad_x + dot, cy + h / 2 + dot / 2), fill=SAND)
        d.text((cx + pad_x + size * 0.75, cy + pad_y - size * 0.08), text, font=f, fill=INK)
        cx += w + gap
    return cy + h


def make_slide(spec, raw_dir, w, h, mascot):
    canvas = glow_background(w, h).convert("RGBA")
    d = ImageDraw.Draw(canvas)
    margin = int(w * 0.075)
    unit = w / 1320

    # Brand lockup: small mascot + full name
    m_small = mascot.resize((int(150 * unit), int(150 * unit * mascot.height / mascot.width)), Image.LANCZOS)
    top = int(110 * unit)
    canvas.alpha_composite(m_small, (margin, top))
    name_f = font(int(54 * unit), "Semibold")
    nx = margin + m_small.width + int(24 * unit)
    ny = top + m_small.height // 2 - int(34 * unit)
    d.text((nx, ny), "hYYa", font=name_f, fill=SAND)
    d.text((nx + d.textlength("hYYa ", font=name_f), ny), "Footprint Inspector", font=name_f, fill=INK)
    d.rounded_rectangle((nx, ny + int(78 * unit), nx + int(64 * unit), ny + int(84 * unit)), 3, fill=SAND)

    # Headline and highlights
    y = top + m_small.height + int(70 * unit)
    y = draw_headline(d, spec["headline"], margin, y, w - margin * 2, int(108 * unit))
    y = chips(d, spec["highlights"], margin, y + int(48 * unit), w - margin * 2, int(46 * unit))

    # Device, running off the bottom edge
    dev_w = int(w * (0.70 if w / h < 0.6 else 0.84))
    frame = device(Image.open(raw_dir / f"{spec['screen']}.png"), dev_w)
    dev_y = y + int(80 * unit)
    dev_x = (w - frame.width) // 2
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((dev_x + 20, dev_y + 40, dev_x + frame.width + 20, dev_y + frame.height + 40), 80, fill=(0, 0, 0, 200))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40)))
    canvas.alpha_composite(frame, (dev_x, dev_y))

    return canvas.convert("RGB")


def main():
    raw_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    w, h = int(sys.argv[3]), int(sys.argv[4])
    out_dir.mkdir(parents=True, exist_ok=True)
    spec = json.loads((ROOT / "store/slides.json").read_text())
    mascot = Image.open(MASCOT).convert("RGBA")
    for i, s in enumerate(spec["slides"], 1):
        img = make_slide(s, raw_dir, w, h, mascot)
        path = out_dir / f"{i:02d}-{s['screen'].split('-', 2)[-1]}.png"
        img.save(path, optimize=True)
        print(path)


if __name__ == "__main__":
    main()
