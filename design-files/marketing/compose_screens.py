"""
Compose 3 App Store preview screenshots for Flip 54.
Output: 1290x2796 PNGs in /tmp/flip54-screens/
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

W, H = 1320, 2868
DESIGN_FILES = "/Users/zcampbell/Claude/Flip 54/design-files"
FONTS = "/Users/zcampbell/Claude/Flip 54/Flip54/Resources/Fonts"
HEADLINE_FONT = f"{FONTS}/BarlowCondensed-ExtraBold.ttf"
SUBHEAD_FONT = "/Users/zcampbell/Claude/Flip 54/design-files/marketing/BarlowCondensed-LightItalic.ttf"  # same family, true italic at light weight
OUT = "/tmp/flip54-screens"
os.makedirs(OUT, exist_ok=True)

BRAND_RED = (200, 38, 44)
BRAND_RED_DARK = (42, 18, 20)  # redSoft from DS.swift
WHITE = (254, 254, 254)
CREAM = (240, 234, 224)  # goldLight from DS.swift
SUBHEAD_BG = (15, 15, 15)
LOGO_PATH = "/Users/zcampbell/Claude/Flip 54/Flip-54-Logo.png"


def smart_crop_to_portrait(img: Image.Image, target_w: int, target_h: int, focus_y_ratio: float = 0.4) -> Image.Image:
    """Crop image to target aspect ratio, scaling up so it fills, with a vertical focus point."""
    src_w, src_h = img.size
    target_ratio = target_w / target_h
    src_ratio = src_w / src_h

    if src_ratio > target_ratio:
        # source wider than target — fit by height, crop sides
        scale = target_h / src_h
        new_w = int(src_w * scale)
        new_h = target_h
        img2 = img.resize((new_w, new_h), Image.LANCZOS)
        x0 = (new_w - target_w) // 2
        return img2.crop((x0, 0, x0 + target_w, target_h))
    else:
        # source taller than target — fit by width, crop top/bottom around focus
        scale = target_w / src_w
        new_w = target_w
        new_h = int(src_h * scale)
        img2 = img.resize((new_w, new_h), Image.LANCZOS)
        focus = int(new_h * focus_y_ratio)
        y0 = max(0, min(new_h - target_h, focus - target_h // 2))
        return img2.crop((0, y0, target_w, y0 + target_h))


def vertical_gradient(width: int, height: int, top_alpha: int, bottom_alpha: int) -> Image.Image:
    """Black gradient from top_alpha at top to bottom_alpha at bottom."""
    grad = Image.new("L", (1, height))
    for y in range(height):
        t = y / max(1, height - 1)
        a = int(top_alpha + (bottom_alpha - top_alpha) * t)
        grad.putpixel((0, y), a)
    grad = grad.resize((width, height))
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out.putalpha(grad)
    black = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    black.putalpha(grad)
    return black


def wrap_lines(draw, text, font, max_width):
    """Greedy word wrap to fit max_width."""
    words = text.split()
    lines = []
    cur = ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textbbox((0, 0), trial, font=font)[2] <= max_width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def load_subhead_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(SUBHEAD_FONT, size)


def render_subhead_line(text: str, font: ImageFont.FreeTypeFont, fill) -> Image.Image:
    """Render one line of subhead text using the font's natural italic (no synthetic skew)."""
    tmp = Image.new("RGBA", (1, 1))
    d = ImageDraw.Draw(tmp)
    bbox = d.textbbox((0, 0), text, font=font)
    pad = 4
    canvas_w = bbox[2] - bbox[0] + pad * 2
    canvas_h = bbox[3] - bbox[1] + pad * 2
    img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.text((pad - bbox[0], pad - bbox[1]), text, font=font, fill=fill)
    return img


def draw_subhead_bar(img: Image.Image, text: str, font: ImageFont.FreeTypeFont, *, top_y: int, side_pad: int):
    """Render subhead as italic cream text inside a solid dark bar.
    Bars left-aligned to headline (start at side_pad). Each bar sized to its line + padding.
    Text inside bar: left-aligned horizontally, middle-aligned (vertically centered)."""
    draw = ImageDraw.Draw(img)
    max_w = img.width - side_pad * 2
    pad_x, pad_y = 36, 28
    inner_max_w = max_w - pad_x * 2

    lines = wrap_lines(draw, text, font, inner_max_w)
    rendered = [render_subhead_line(line, font, CREAM) for line in lines]

    line_h = max(r.height for r in rendered)
    bar_h = line_h + pad_y * 2

    y = top_y
    for r in rendered:
        bar_w = min(r.width + pad_x * 2, max_w)
        bx = side_pad
        by = y
        draw.rectangle([bx, by, bx + bar_w, by + bar_h], fill=SUBHEAD_BG)
        # Text: left-aligned with pad_x, vertically centered
        tx = bx + pad_x
        ty = by + (bar_h - r.height) // 2
        img.alpha_composite(r, (tx, ty))
        y += bar_h + 16


def draw_text_block(img: Image.Image, headline: str, subhead: str, *, headline_size: int = 200, subhead_size: int = 76,
                     top_y: int = 240, side_pad: int = 80, line_gap: float = 0.92, gap_after_headline: int = 60):
    """Draw an all-caps headline + dark-bar italic subhead block."""
    draw = ImageDraw.Draw(img)
    h_font = ImageFont.truetype(HEADLINE_FONT, headline_size)
    s_font = load_subhead_font(subhead_size)
    max_w = img.width - side_pad * 2

    headline_lines = []
    for raw_line in headline.split("\n"):
        headline_lines.extend(wrap_lines(draw, raw_line.upper(), h_font, max_w))

    y = top_y
    for line in headline_lines:
        bbox = draw.textbbox((0, 0), line, font=h_font)
        line_h = bbox[3] - bbox[1]
        draw.text((side_pad + 4, y + 6), line, font=h_font, fill=(0, 0, 0, 180))
        draw.text((side_pad, y), line, font=h_font, fill=WHITE)
        y += int(line_h * line_gap) + 18

    y += gap_after_headline + 10
    draw_subhead_bar(img, subhead, s_font, top_y=y, side_pad=side_pad)


def extract_wordmark(logo_path: str, threshold: int = 90) -> Image.Image:
    """Extract bright cream wordmark from the logo, dropping dark background + suit ghost."""
    logo = Image.open(logo_path).convert("RGBA")
    # Use luminance to alpha — bright pixels (the FLIP 54 wordmark) stay opaque, dark drops out
    luminance = logo.convert("L")
    alpha_mask = luminance.point(lambda v: v if v > threshold else 0)
    rgba = logo.copy()
    rgba.putalpha(alpha_mask)
    # Trim to bounding box of non-transparent pixels
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)
    return rgba


def draw_logo(img: Image.Image, *, max_width: int = 920, bottom_pad: int = 200):
    """Composite the Flip 54 wordmark (no background) as a large bottom element."""
    logo = extract_wordmark(LOGO_PATH)
    scale = max_width / logo.width
    new_size = (max_width, int(logo.height * scale))
    logo = logo.resize(new_size, Image.LANCZOS)
    x = (img.width - logo.width) // 2
    y = img.height - bottom_pad - logo.height
    img.alpha_composite(logo, (x, y))


def overlay_ui_card(img: Image.Image, screenshot_path: str, *, width: int = 580, rotation: float = -8,
                     bottom_offset: int = 220, x_offset: int = 0, shadow: bool = True):
    """Composite an app screenshot as a tilted floating card near the bottom-right."""
    ss = Image.open(screenshot_path).convert("RGBA")
    scale = width / ss.width
    new_size = (width, int(ss.height * scale))
    ss = ss.resize(new_size, Image.LANCZOS)

    # Round corners
    mask = Image.new("L", ss.size, 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, ss.width, ss.height], radius=44, fill=255)
    ss.putalpha(mask)

    # Add a subtle white border ring
    bordered = Image.new("RGBA", (ss.width + 12, ss.height + 12), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bordered)
    bdraw.rounded_rectangle([0, 0, bordered.width, bordered.height], radius=50, fill=(255, 255, 255, 220))
    bordered.alpha_composite(ss, (6, 6))

    # Shadow
    if shadow:
        shadow_layer = Image.new("RGBA", (bordered.width + 80, bordered.height + 80), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow_layer)
        sdraw.rounded_rectangle([40, 40, shadow_layer.width - 40, shadow_layer.height - 40],
                                radius=50, fill=(0, 0, 0, 160))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(28))
    else:
        shadow_layer = None

    # Rotate
    rotated = bordered.rotate(rotation, resample=Image.BICUBIC, expand=True)
    if shadow_layer is not None:
        shadow_rot = shadow_layer.rotate(rotation, resample=Image.BICUBIC, expand=True)

    # Position
    x = (img.width - rotated.width) // 2 + x_offset
    y = img.height - bottom_offset - rotated.height
    if shadow_layer is not None:
        sx = x - (shadow_rot.width - rotated.width) // 2
        sy = y - (shadow_rot.height - rotated.height) // 2 + 18
        img.alpha_composite(shadow_rot, (sx, sy))
    img.alpha_composite(rotated, (x, y))


def compose(photo_path: str, headline: str, subhead: str, out_path: str, *, focus_y: float = 0.35,
            top_overlay_alpha: int = 230, headline_size: int = 200,
            logo=False, ui_card=None):
    src = Image.open(photo_path).convert("RGB")
    canvas = smart_crop_to_portrait(src, W, H, focus_y_ratio=focus_y).convert("RGBA")

    # Top darken gradient (for headline legibility) — covers top ~58% of image
    grad_h = int(H * 0.58)
    grad = vertical_gradient(W, grad_h, top_overlay_alpha, 0)
    canvas.alpha_composite(grad, (0, 0))

    # Bottom vignette to anchor logo/footer area
    bottom_h = int(H * 0.28)
    bottom_grad = vertical_gradient(W, bottom_h, 0, 200)
    canvas.alpha_composite(bottom_grad, (0, H - bottom_h))

    draw_text_block(canvas, headline, subhead, headline_size=headline_size)

    if ui_card:
        overlay_ui_card(canvas, **ui_card)

    if logo:
        draw_logo(canvas)

    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path}")


screens = [
    {
        "photo": "man-front-raising.jpg",
        "headline": "Fifty-four cards.\nOne workout.",
        "subhead": "Never the same twice.",
        "out": "01-hook.png",
        "focus_y": 0.5,
        "logo": True,
    },
    {
        "photo": "woman-crunching.jpg",
        "headline": "Four suits.\nEvery area.",
        "subhead": "Each suit is a body target. Match it to whatever exercise fits your space and gear.",
        "out": "02-mechanic.png",
        "focus_y": 0.55,
        "top_overlay_alpha": 235,
        "ui_card": {
            "screenshot_path": "/tmp/flip54-shots/suit-mapping.png",
            "width": 640,
            "rotation": -7,
            "bottom_offset": 240,
            "x_offset": 80,
        },
    },
    {
        "photo": "man-high-knees.jpg",
        "headline": "Cardio. Strength.\nAnywhere.",
        "subhead": "Fast for HIIT. Slow for strength. Always different.",
        "out": "03-versatility.png",
        "focus_y": 0.45,
        "ui_card": {
            "screenshot_path": "/tmp/flip54-shots/active-card.png",
            "width": 620,
            "rotation": 6,
            "bottom_offset": 240,
            "x_offset": -90,
        },
    },
]

for s in screens:
    compose(
        os.path.join(DESIGN_FILES, s["photo"]),
        s["headline"],
        s["subhead"],
        os.path.join(OUT, s["out"]),
        focus_y=s.get("focus_y", 0.4),
        top_overlay_alpha=s.get("top_overlay_alpha", 230),
        headline_size=s.get("headline_size", 200),
        logo=s.get("logo", False),
        ui_card=s.get("ui_card"),
    )

print("done")
