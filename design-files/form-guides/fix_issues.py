"""
Targeted fix for 5 reported issues:
  1. sitUp        — y1 raised to 720 (was 750) to capture head in seated frame
  2. russianTwist — y2 lowered to 845 (was 858) to exclude jumping-jacks shoes
  3. bicepCurl    — alignment fixed via content-centroid centering (front mode)
  4. weightedSitUp— alignment fixed via content-left-edge anchoring (side mode)
  5. burpee       — expanded to 4 frames (standing / plank / floor / jump)

Alignment root-cause: the old tight_crop used max(0, c0-PAD) which clipped padding
unevenly when a figure was near the split edge, causing asymmetric bounding boxes.
Fix: extract raw content bbox (no padding at all), resize content directly, then
place using content centroid (front) or content left-edge (side).
"""

import os, json
import numpy as np
from PIL import Image

SRC      = "source/all_exercises.png"
XCASSETS = "../../Flip54/Assets.xcassets/FormGuides"

OUT_W    = 1600
OUT_H    = 720
FLOOR_PAD = 30


# ── Helpers ───────────────────────────────────────────────────────────────────

def get_content_bbox(img):
    """Return (x0,y0,x1,y1) tight bounding box of non-white content."""
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    rows, cols = np.any(mask, axis=1), np.any(mask, axis=0)
    if not rows.any():
        return (0, 0, img.size[0], img.size[1])
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    return (int(c0), int(r0), int(c1) + 1, int(r1) + 1)


def hcenter(img_s):
    """Horizontal centroid of non-transparent pixels (for front-mode centering)."""
    arr = np.array(img_s.convert("RGBA"))
    col_w = (arr[:,:,3] > 10).sum(axis=0).astype(float)
    total = col_w.sum()
    if total == 0:
        return img_s.size[0] / 2.0
    return float((np.arange(len(col_w)) * col_w).sum() / total)


def split_pair(pair_img):
    """Split a two-figure crop at the widest white vertical gap in the middle third."""
    arr = np.array(pair_img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    col_counts = mask.sum(axis=0).astype(float)
    col_smooth = np.convolve(col_counts, np.ones(5)/5, mode='same')
    W = pair_img.size[0]
    mid_s, mid_e = W//4, 3*W//4
    gap_x = mid_s + int(col_smooth[mid_s:mid_e].argmin())
    a = pair_img.crop((0, 0, gap_x, pair_img.size[1]))
    b = pair_img.crop((gap_x, 0, W, pair_img.size[1]))
    return a, b


def make_aligned(a_img, b_img, mode):
    """
    Scale both frames by a common factor; anchor by content bbox, not padded crop.
    front mode: align by horizontal centroid → body stays fixed when arms move.
    side  mode: align by left edge of content → feet planted at same canvas X.
    """
    a_box = get_content_bbox(a_img)
    b_box = get_content_bbox(b_img)

    aw, ah = a_box[2] - a_box[0], a_box[3] - a_box[1]
    bw, bh = b_box[2] - b_box[0], b_box[3] - b_box[1]

    usable_h = OUT_H - FLOOR_PAD
    scale = min(OUT_W / max(aw, bw), usable_h / max(ah, bh)) * 0.92

    def crop_resize(img, box):
        c = img.crop(box)
        return c.resize(
            (max(1, int((box[2]-box[0]) * scale)),
             max(1, int((box[3]-box[1]) * scale))),
            Image.LANCZOS
        )

    a_s = crop_resize(a_img, a_box)
    b_s = crop_resize(b_img, b_box)

    if mode == "front":
        def place(img_s):
            cx = hcenter(img_s)
            iw, ih = img_s.size
            canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))
            ox = int(OUT_W / 2 - cx)
            oy = OUT_H - FLOOR_PAD - ih
            canvas.paste(img_s, (ox, oy), img_s)
            return canvas
    else:
        left_anchor = (OUT_W - int(max(aw, bw) * scale)) // 2

        def place(img_s):
            iw, ih = img_s.size
            canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))
            oy = OUT_H - FLOOR_PAD - ih
            canvas.paste(img_s, (left_anchor, oy), img_s)
            return canvas

    return place(a_s), place(b_s)


def make_aligned_multi(imgs, mode="side"):
    """
    Align N frames with a single common scale and floor anchor.
    Used for burpee (4 frames).
    """
    boxes = [get_content_bbox(img) for img in imgs]
    widths  = [b[2]-b[0] for b in boxes]
    heights = [b[3]-b[1] for b in boxes]

    usable_h = OUT_H - FLOOR_PAD
    scale = min(OUT_W / max(widths), usable_h / max(heights)) * 0.92

    def crop_resize(img, box):
        c = img.crop(box)
        return c.resize(
            (max(1, int((box[2]-box[0]) * scale)),
             max(1, int((box[3]-box[1]) * scale))),
            Image.LANCZOS
        )

    resized = [crop_resize(img, box) for img, box in zip(imgs, boxes)]

    if mode == "side":
        left_anchor = (OUT_W - int(max(widths) * scale)) // 2

        def place(img_s):
            iw, ih = img_s.size
            canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))
            oy = OUT_H - FLOOR_PAD - ih
            canvas.paste(img_s, (left_anchor, oy), img_s)
            return canvas
    else:
        def place(img_s):
            cx = hcenter(img_s)
            iw, ih = img_s.size
            canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))
            ox = int(OUT_W / 2 - cx)
            oy = OUT_H - FLOOR_PAD - ih
            canvas.paste(img_s, (ox, oy), img_s)
            return canvas

    return [place(r) for r in resized]


def write_imageset(name, img):
    iset = os.path.join(XCASSETS, f"{name}.imageset")
    os.makedirs(iset, exist_ok=True)
    fname = f"{name}.png"
    img.convert("RGB").save(os.path.join(iset, fname), optimize=True)
    contents = {
        "images": [
            {"filename": fname, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(iset, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  ✓ {name}")


def invert_to_white(path):
    """Black-lines-on-white → white-lines-on-transparent."""
    img = Image.open(path).convert("RGBA")
    arr = np.array(img, dtype=np.float32)
    lum = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]
    out = np.zeros_like(arr)
    out[:,:,0] = 255
    out[:,:,1] = 255
    out[:,:,2] = 255
    out[:,:,3] = 255 - lum
    Image.fromarray(out.astype(np.uint8), "RGBA").save(path, optimize=True)


# ── Main ──────────────────────────────────────────────────────────────────────

src = Image.open(SRC).convert("RGBA")
updated_paths = []

# 1. sitUp — y1=733 clears the dead hang's feet (row 3 ends at y=730) while
#           keeping enough height for the seated figure's head
print("Fixing sitUp…")
pair = src.crop((287, 733, 587, 858))
left, right = split_pair(pair)
a, b = make_aligned(left, right, "side")
write_imageset("form_sitUp_a", a)
write_imageset("form_sitUp_b", b)
for s in ["a", "b"]:
    updated_paths.append(
        os.path.join(XCASSETS, f"form_sitUp_{s}.imageset", f"form_sitUp_{s}.png"))

# 2. russianTwist — lower y2 to 845 to exclude jumping-jacks shoes artifact
print("Fixing russianTwist…")
pair = src.crop((587, 725, 914, 845))
left, right = split_pair(pair)
a, b = make_aligned(left, right, "side")
write_imageset("form_russianTwist_a", a)
write_imageset("form_russianTwist_b", b)
for s in ["a", "b"]:
    updated_paths.append(
        os.path.join(XCASSETS, f"form_russianTwist_{s}.imageset", f"form_russianTwist_{s}.png"))

# 3. bicepCurl — front mode with centroid alignment (fixes left-right body shift)
print("Fixing bicepCurl…")
pair = src.crop((688, 252, 992, 492))
left, right = split_pair(pair)
a, b = make_aligned(left, right, "front")
write_imageset("form_bicepCurl_a", a)
write_imageset("form_bicepCurl_b", b)
for s in ["a", "b"]:
    updated_paths.append(
        os.path.join(XCASSETS, f"form_bicepCurl_{s}.imageset", f"form_bicepCurl_{s}.png"))

# 4. weightedSitUp — side mode with content-left-edge anchoring
print("Fixing weightedSitUp…")
pair = src.crop((914, 725, 1267, 858))
left, right = split_pair(pair)
a, b = make_aligned(left, right, "side")
write_imageset("form_weightedSitUp_a", a)
write_imageset("form_weightedSitUp_b", b)
for s in ["a", "b"]:
    updated_paths.append(
        os.path.join(XCASSETS, f"form_weightedSitUp_{s}.imageset", f"form_weightedSitUp_{s}.png"))

# 5. burpee — 4 individual frames with common scale+floor anchor
print("Fixing burpee (4 frames)…")
burpee_crops = [
    (438, 494, 530, 730),   # standing — y1=494 skips the floating glasses blob
    (530, 487, 692, 730),   # plank (push-up top)
    (692, 487, 858, 730),   # chest-to-floor (push-up bottom)
    (858, 487, 936, 730),   # jump
]
burpee_imgs = [src.crop(box) for box in burpee_crops]
burpee_frames = make_aligned_multi(burpee_imgs, "side")
for suffix, frame in zip(["a", "b", "c", "d"], burpee_frames):
    name = f"form_burpee_{suffix}"
    write_imageset(name, frame)
    updated_paths.append(
        os.path.join(XCASSETS, f"{name}.imageset", f"{name}.png"))

# ── Invert all updated files to white-on-transparent ─────────────────────────
print("\nInverting updated assets to white-on-transparent…")
for p in updated_paths:
    invert_to_white(p)
    print(f"  ✓ {os.path.basename(os.path.dirname(p))}")

print(f"\nDone. {len(updated_paths)} assets updated.")
