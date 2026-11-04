"""Draw the original OneChat outline glyphs on a shared 32px grid.

Requires Pillow. Outputs power-of-two DDS textures with transparent backgrounds.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "OneChat/art"
DEST.mkdir(exist_ok=True)
SCALE = 4

def glyph(kind):
    image = Image.new("RGBA", (128, 128))
    draw = ImageDraw.Draw(image)
    white = (255, 255, 255, 255)

    def line(points):
        points = [(round(x * SCALE), round(y * SCALE)) for x, y in points]
        draw.line(points, fill=white, width=2 * SCALE, joint="curve")
        for x, y in (points[0], points[-1]):
            draw.ellipse((x - SCALE, y - SCALE, x + SCALE, y + SCALE), fill=white)

    def ellipse(box):
        draw.ellipse(tuple(v * SCALE for v in box), outline=white, width=2 * SCALE)

    if kind == "home":
        line([(4, 14), (16, 4), (28, 14)])
        line([(7, 12), (7, 27), (25, 27), (25, 12)])
        line([(13, 27), (13, 19), (19, 19), (19, 27)])
    elif kind == "reload":
        draw.arc((5 * SCALE, 5 * SCALE, 27 * SCALE, 27 * SCALE), 40, 320,
                 fill=white, width=2 * SCALE)
        line([(26, 5), (26, 11), (20, 11)])
    else:
        ellipse((4, 4, 28, 28))
        ellipse((11, 4, 21, 28))
        line([(5, 16), (27, 16)])
    return image.resize((32, 32), Image.Resampling.LANCZOS)

preview = Image.new("RGB", (240, 80), (30, 29, 25))
for index, kind in enumerate(("home", "reload", "language")):
    image = glyph(kind)
    image.save(DEST / f"{kind}.dds", pixel_format="DXT5")
    # Reopen the shipped textures, not the drawing canvas, for visual QA.
    shipped = Image.open(DEST / f"{kind}.dds").convert("RGBA")
    tinted = Image.new("RGBA", shipped.size, (197, 194, 158, 255))
    tinted.putalpha(shipped.getchannel("A"))
    preview.paste(tinted.resize((48, 48), Image.Resampling.NEAREST), (index * 80 + 16, 16),
                  tinted.resize((48, 48), Image.Resampling.NEAREST))
preview_path = ROOT / ".tools/icon-preview.png"
preview_path.parent.mkdir(exist_ok=True)
preview.save(preview_path)
