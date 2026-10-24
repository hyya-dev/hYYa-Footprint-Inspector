#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds landscape App Store slides (the iPhone Duo sideways) from raw captures.

    python3 scripts/make-landscape-slides.py <raw-dir> <out-dir> <width> <height> [--rotate cw|ccw]

The mascot and full name, the headline with its highlights beside it, and the whole real
screen below in a rounded frame, so the Duo's side strip of pages stays in view. Copy comes from store/slides.json. Captures that come out upright from a sideways device
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
    k = W / 2853
    px = lambda v: int(v * k)
    c = slides.glow_background(W, H).convert("RGBA")
    d = ImageDraw.Draw(c)
    left = px(140)
    # Top band: mascot and name, then the headline with its chips beside it.
    m = mascot.resize((px(130), int(px(130) * mascot.height / mascot.width)), Image.LANCZOS)
    c.alpha_composite(m, (left, px(90)))
    f = slides.font(px(56), "Semibold")
    nx, ny = left + m.width + px(26), px(90) + m.height // 2 - px(36)
    d.text((nx, ny), "hYYa", font=f, fill=slides.SAND)
    d.text((nx + d.textlength("hYYa ", font=f), ny), "Footprint Inspector", font=f, fill=slides.INK)
    d.rounded_rectangle((nx, ny + px(80), nx + px(66), ny + px(86)), 3, fill=slides.SAND)
    top = px(90) + m.height + px(70)
    y = slides.draw_headline(d, s["headline"], left, top, px(1300), px(104))
    slides.chips(d, s["highlights"], left + px(1420), top + px(10), W - (left + px(1420)) - left, px(44))
    # The real screen, large, running off the bottom edge.
    shot = Image.open(raw / f"{s['screen']}.png").convert("RGB")
    if rotate == "cw": shot = shot.rotate(-90, expand=True)
    if rotate == "ccw": shot = shot.rotate(90, expand=True)
    # The whole screen fits, so the Duo's side strip of pages stays in view.
    sy = max(y, top + px(330)) + px(60)
    fit = min((W - 2 * left) / shot.width, (H - sy - px(70)) / shot.height)
    shot = shot.resize((int(shot.width * fit), int(shot.height * fit)), Image.LANCZOS)
    shot = rounded(shot, px(48))
    x = (W - shot.width) // 2
    shadow = Image.new("RGBA", c.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x, sy + px(30), x + shot.width, sy + shot.height + px(30)), px(52), fill=(0, 0, 0, 220))
    c.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(px(45))))
    ImageDraw.Draw(c).rounded_rectangle((x - 3, sy - 3, x + shot.width + 2, sy + shot.height + 2), px(50), outline=slides.SAND_DEEP + (255,), width=max(2, px(3)))
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
