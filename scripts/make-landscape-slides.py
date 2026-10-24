#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds landscape App Store slides (the iPhone Duo sideways) from raw captures.

    python3 scripts/make-landscape-slides.py <raw-dir> <out-dir> <width> <height> [--rotate cw|ccw]

Same layout as the Mac slides, scaled to the canvas: the mascot and full name, headline and
highlights on the left; the real screen on the right in a rounded frame, running off the right
edge. Copy comes from store/slides.json. Captures that come out upright from a sideways device
are turned with --rotate.
"""
import importlib.util, json, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("slides", ROOT / "scripts/make-store-slides.py")
slides = importlib.util.module_from_spec(spec); spec.loader.exec_module(slides)


def rounded(im, r):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0)); out.paste(im, (0, 0), mask); return out


def make(s, raw, mascot, W, H, rotate):
    k = W / 2880
    px = lambda v: int(v * k)
    c = slides.glow_background(W, H).convert("RGBA")
    d = ImageDraw.Draw(c)
    left = px(130)
    m = mascot.resize((px(150), int(px(150) * mascot.height / mascot.width)), Image.LANCZOS)
    c.alpha_composite(m, (left, px(120)))
    f = slides.font(px(58), "Semibold")
    nx, ny = left + m.width + px(28), px(120) + m.height // 2 - px(38)
    d.text((nx, ny), "hYYa", font=f, fill=slides.SAND)
    d.text((nx + d.textlength("hYYa ", font=f), ny), "Footprint Inspector", font=f, fill=slides.INK)
    d.rounded_rectangle((nx, ny + px(84), nx + px(70), ny + px(90)), 3, fill=slides.SAND)
    y = slides.draw_headline(d, s["headline"], left, px(120) + m.height + px(110), px(1000), px(112))
    slides.chips(d, s["highlights"], left, y + px(60), px(1000), px(46))

    shot = Image.open(raw / f"{s['screen']}.png").convert("RGB")
    if rotate == "cw": shot = shot.rotate(-90, expand=True)
    if rotate == "ccw": shot = shot.rotate(90, expand=True)
    sw = px(1650)
    shot = shot.resize((sw, int(shot.height * sw / shot.width)), Image.LANCZOS)
    shot = rounded(shot, px(40))
    x, sy = px(1240), (H - shot.height) // 2
    shadow = Image.new("RGBA", c.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x + px(20), sy + px(40), x + shot.width + px(20), sy + shot.height + px(40)), px(44), fill=(0, 0, 0, 220))
    c.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(px(45))))
    ImageDraw.Draw(c).rounded_rectangle((x - 3, sy - 3, x + shot.width + 2, sy + shot.height + 2), px(42), outline=slides.SAND_DEEP + (255,), width=max(2, px(3)))
    c.alpha_composite(shot, (x, sy))
    return c.convert("RGB")


if __name__ == "__main__":
    raw, out, W, H = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
    rotate = sys.argv[sys.argv.index("--rotate") + 1] if "--rotate" in sys.argv else None
    out.mkdir(parents=True, exist_ok=True)
    data = json.loads((ROOT / "store/slides.json").read_text())
    mascot = Image.open(slides.MASCOT).convert("RGBA")
    for i, s in enumerate(data["slides"], 1):
        path = out / f"{i:02d}-{s['screen'].split('-', 2)[-1]}.png"
        make(s, raw, mascot, W, H, rotate).save(path, optimize=True)
        print(path)
