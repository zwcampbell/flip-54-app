"""
Crop the 2×2 composite illustration into 4 individual frames, align them
with the shared floor-anchor/common-scale logic, and export to xcassets.

Source:  source/ab_exercises_composite.png
  Top-left:     vSit frame A  (legs extended)
  Top-right:    vSit frame B  (knees tucked)
  Bottom-left:  bicycleCrunch frame A
  Bottom-right: bicycleCrunch frame B

Output (same pipeline as batch_crop_exercises.py):
  ../../Flip54/Assets.xcassets/FormGuides/form_vSit_a.imageset/
  ../../Flip54/Assets.xcassets/FormGuides/form_vSit_b.imageset/
  ../../Flip54/Assets.xcassets/FormGuides/form_bicycleCrunch_a.imageset/
  ../../Flip54/Assets.xcassets/FormGuides/form_bicycleCrunch_b.imageset/

Then run invert_to_white.py to flip black-on-white → white-on-transparent.
"""

import os, json
from PIL import Image
import numpy as np

SRC      = "v-sits-and-bicycle-crunches.png"
XCASSETS = "../../Flip54/Assets.xcassets/FormGuides"
CROPS_DIR = "exercise_crops"
os.makedirs(CROPS_DIR, exist_ok=True)

OUT_W     = 1600
OUT_H     = 720
FLOOR_PAD = 30
TIGHT_PAD = 16


# ── Helpers (identical to batch_crop_exercises.py) ───────────────────────────

def tight_crop(img):
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    rows, cols = np.any(mask, axis=1), np.any(mask, axis=0)
    if not rows.any():
        return img
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    W, H = img.size
    return img.crop((max(0, c0 - TIGHT_PAD), max(0, r0 - TIGHT_PAD),
                     min(W, c1 + TIGHT_PAD), min(H, r1 + TIGHT_PAD)))


def get_content_bbox(img):
    """Tight bounding box with no padding — used for alignment."""
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    rows, cols = np.any(mask, axis=1), np.any(mask, axis=0)
    if not rows.any():
        return (0, 0, img.size[0], img.size[1])
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    return (c0, r0, c1 + 1, r1 + 1)


def make_aligned(a_img, b_img, mode="side"):
    """Scale both frames by a common factor, floor-anchor them."""
    a = tight_crop(a_img)
    b = tight_crop(b_img)
    aw, ah = a.size
    bw, bh = b.size

    usable_h = OUT_H - FLOOR_PAD
    scale = min(OUT_W / max(aw, bw), usable_h / max(ah, bh)) * 0.92

    def resize(img):
        w, h = img.size
        return img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)

    a_s, b_s = resize(a), resize(b)

    def place(img_s):
        iw, ih = img_s.size
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))
        oy = OUT_H - FLOOR_PAD - ih
        if mode == "front":
            ox = (OUT_W - iw) // 2
        else:
            ox = (OUT_W - int(max(aw, bw) * scale)) // 2
        canvas.paste(img_s, (ox, oy), img_s)
        return canvas

    return place(a_s), place(b_s)


def invert_to_white(img):
    """Convert black-on-white RGBA → white-on-transparent (same logic as invert_to_white.py)."""
    arr = np.array(img.convert("RGBA"), dtype=np.float32)
    lum = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]
    out = np.zeros_like(arr)
    out[:,:,0] = 255
    out[:,:,1] = 255
    out[:,:,2] = 255
    out[:,:,3] = 255 - lum
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def write_imageset(name, img):
    iset = os.path.join(XCASSETS, f"{name}.imageset")
    os.makedirs(iset, exist_ok=True)
    fname = f"{name}.png"
    inverted = invert_to_white(img)
    inverted.save(os.path.join(iset, fname), optimize=True)
    contents = {
        "images": [
            {"filename": fname, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(iset, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  ✓ {name}")


# ── Find grid split lines ────────────────────────────────────────────────────

def find_split(arr_1d, lo_frac, hi_frac):
    """
    Return the index of the minimum density in the band [lo_frac, hi_frac].
    Works for both row-density (horizontal split) and col-density (vertical split).
    """
    n = len(arr_1d)
    lo, hi = int(n * lo_frac), int(n * hi_frac)
    band = arr_1d[lo:hi].astype(float)
    smoothed = np.convolve(band, np.ones(9) / 9, mode="same")
    return lo + int(smoothed.argmin())


def split_2x2(img):
    """
    Find the whitespace midlines in a 2×2 composite and return
    (top_left, top_right, bottom_left, bottom_right) as PIL Images.
    """
    arr = np.array(img.convert("RGBA"))
    # Non-white mask
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))

    row_density = mask.sum(axis=1)   # ink per row → find horizontal gap
    col_density = mask.sum(axis=0)   # ink per col → find vertical gap

    split_row = find_split(row_density, 0.3, 0.7)
    split_col = find_split(col_density, 0.3, 0.7)

    W, H = img.size
    tl = img.crop((0,         0,         split_col, split_row))
    tr = img.crop((split_col, 0,         W,         split_row))
    bl = img.crop((0,         split_row, split_col, H))
    br = img.crop((split_col, split_row, W,         H))

    print(f"  Grid split at col={split_col}, row={split_row} (image {W}×{H})")
    return tl, tr, bl, br


# ── Main ─────────────────────────────────────────────────────────────────────

src = Image.open(SRC).convert("RGBA")

vsit_a_raw, vsit_b_raw, bicycle_a_raw, bicycle_b_raw = split_2x2(src)

# Debug crops
vsit_a_raw.convert("RGB").save(f"{CROPS_DIR}/vSit_a_raw.png")
vsit_b_raw.convert("RGB").save(f"{CROPS_DIR}/vSit_b_raw.png")
bicycle_a_raw.convert("RGB").save(f"{CROPS_DIR}/bicycleCrunch_a_raw.png")
bicycle_b_raw.convert("RGB").save(f"{CROPS_DIR}/bicycleCrunch_b_raw.png")
print(f"  Debug crops saved to {CROPS_DIR}/")

# V-sit: side view (torso upright, legs extended — both from same direction)
vsit_a, vsit_b = make_aligned(vsit_a_raw, vsit_b_raw, mode="side")
write_imageset("form_vSit_a", vsit_a)
write_imageset("form_vSit_b", vsit_b)

# Bicycle crunch: flip frame B horizontally so the two frames show opposite sides
# of the rotation (left-leg-extended vs right-leg-extended), making the alternating
# motion legible from a pure side-view illustration.
bicycle_b_flipped = bicycle_b_raw.transpose(Image.FLIP_LEFT_RIGHT)
bicycle_a, bicycle_b = make_aligned(bicycle_a_raw, bicycle_b_flipped, mode="side")
write_imageset("form_bicycleCrunch_a", bicycle_a)
write_imageset("form_bicycleCrunch_b", bicycle_b)

print("\nDone. Check exercise_crops/ to verify raw quadrant crops.")
print("Inversion already applied inline — no need to run invert_to_white.py separately.")
