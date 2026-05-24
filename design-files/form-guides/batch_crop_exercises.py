"""
Batch crop all 21 remaining exercises from source/all_exercises.png,
split each into two pose frames (A and B), align them with a consistent
floor anchor, and export into Assets.xcassets/FormGuides.

Single-pose exercises (holds) duplicate the same frame for A and B.
"""

import os, json
from PIL import Image
import numpy as np

SRC       = "source/all_exercises.png"
XCASSETS  = "../../Flip54/Assets.xcassets/FormGuides"
CROPS_DIR = "exercise_crops"   # intermediate crops for debugging
os.makedirs(CROPS_DIR, exist_ok=True)

# ── Manual crop map ───────────────────────────────────────────────────────────
# (rawValue, (x1,y1,x2,y2), mode, single_pose)
# mode: 'front' = center-aligned, 'side' = left-aligned (feet anchor)
# single_pose: True = only one frame exists, duplicate it

CROP_MAP = [
    # Row 1 — lower body
    ("bodyweightSquat", (40,    0,  350,  248), "front", False),
    ("lunge",           (388,   0,  658,  248), "side",  False),
    ("jumpingSquat",    (693,   0,  942,  248), "side",  False),
    ("gobletSquat",     (992,   0, 1272,  248), "front", False),
    ("wallSit",         (1298,  0, 1455,  248), "side",  True),

    # Row 2 — upper body
    ("hinduPushUp",     (0,    252,  402,  492), "side",  False),
    ("pullUp",          (392,  252,  648,  492), "front", False),
    ("bicepCurl",       (688,  252,  992,  492), "front", False),
    ("shoulderPress",   (998,  252, 1268,  492), "front", False),
    ("tricepExtension", (1268, 252, 1498,  492), "front", False),

    # Row 3 — total body / holds
    ("pushUpHold",      (11,   487,  294,  730), "side",  True),
    ("deadHang",        (294,  487,  438,  730), "front", True),
    ("burpee",          (438,  487,  936,  730), "side",  False),
    ("mountainClimber", (936,  487, 1285,  730), "side",  False),
    ("thruster",        (1285, 487, 1512,  730), "side",  False),

    # Row 4 — core
    ("plank",           (15,   725,  287,  858), "side",  True),
    ("sitUp",           (287,  750,  587,  858), "side",  False),
    ("russianTwist",    (587,  725,  914,  858), "side",  False),
    ("weightedSitUp",   (914,  725, 1267,  858), "side",  False),
    ("hollowBodyHold",  (1267, 725, 1519, 1024), "side",  True),

    # Row 5 — conditioning
    ("jumpingJacks",    (648,  848,  838, 1024), "front", False),
]

# ── Helpers ───────────────────────────────────────────────────────────────────

TIGHT_PAD = 16
OUT_W     = 1600
OUT_H     = 720
FLOOR_PAD = 30


def tight_crop(img):
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0]>240)&(arr[:,:,1]>240)&(arr[:,:,2]>240))
    rows, cols = np.any(mask,axis=1), np.any(mask,axis=0)
    if not rows.any(): return img
    r0,r1 = np.where(rows)[0][[0,-1]]
    c0,c1 = np.where(cols)[0][[0,-1]]
    W,H = img.size
    return img.crop((max(0,c0-TIGHT_PAD),max(0,r0-TIGHT_PAD),
                     min(W,c1+TIGHT_PAD),min(H,r1+TIGHT_PAD)))


def split_pair(pair_img):
    """Split a two-figure crop at the widest white vertical gap in the middle third."""
    arr = np.array(pair_img.convert("RGBA"))
    mask = ~((arr[:,:,0]>240)&(arr[:,:,1]>240)&(arr[:,:,2]>240))
    col_counts = mask.sum(axis=0).astype(float)
    col_smooth = np.convolve(col_counts, np.ones(5)/5, mode='same')
    W = pair_img.size[0]
    mid_s, mid_e = W//4, 3*W//4
    gap_x = mid_s + int(col_smooth[mid_s:mid_e].argmin())
    a = pair_img.crop((0, 0, gap_x, pair_img.size[1]))
    b = pair_img.crop((gap_x, 0, W, pair_img.size[1]))
    return a, b


def make_aligned(a_img, b_img, mode):
    """Scale both by the same factor, floor-anchor, return canvas-sized RGBA images."""
    a = tight_crop(a_img)
    b = tight_crop(b_img)
    aw, ah = a.size
    bw, bh = b.size

    usable_h = OUT_H - FLOOR_PAD
    scale = min(OUT_W / max(aw, bw), usable_h / max(ah, bh)) * 0.92

    def resize(img):
        w,h = img.size
        return img.resize((int(w*scale),int(h*scale)), Image.LANCZOS)

    a_s, b_s = resize(a), resize(b)

    def place(img_s):
        iw, ih = img_s.size
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (255,255,255,255))
        oy = OUT_H - FLOOR_PAD - ih
        if mode == "front":
            ox = (OUT_W - iw) // 2
        else:
            ox = (OUT_W - int(max(aw,bw)*scale)) // 2
        canvas.paste(img_s, (ox, oy), img_s)
        return canvas

    return place(a_s), place(b_s)


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


# ── Main ──────────────────────────────────────────────────────────────────────

src = Image.open(SRC).convert("RGBA")

for rawValue, box, mode, single_pose in CROP_MAP:
    pair = src.crop(box)
    pair.convert("RGB").save(f"{CROPS_DIR}/{rawValue}_pair.png")   # debug

    if single_pose:
        fig = tight_crop(pair)
        frame_a, frame_b = make_aligned(fig, fig, mode)
    else:
        left, right = split_pair(pair)
        left.convert("RGB").save(f"{CROPS_DIR}/{rawValue}_a_raw.png")
        right.convert("RGB").save(f"{CROPS_DIR}/{rawValue}_b_raw.png")
        frame_a, frame_b = make_aligned(left, right, mode)

    write_imageset(f"form_{rawValue}_a", frame_a)
    write_imageset(f"form_{rawValue}_b", frame_b)
    print(f"  ✓ {rawValue}  (mode={mode}, {'single' if single_pose else 'pair'})")

print(f"\nDone. Check {CROPS_DIR}/ to verify pair crops.")
