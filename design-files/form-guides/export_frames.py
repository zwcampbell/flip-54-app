"""
Export aligned PNG frames for a pair of pose images and copy them into xcassets.

Uses the same floor-anchor + common-scale logic as make_exercise_gif.py so
the two frames composite correctly in the app's SwiftUI crossfade.

Usage:
    python3 export_frames.py <exercise_rawValue> <a.png> <b.png> [side|front]

Writes:
    Flip54/Assets.xcassets/FormGuides/form_<name>_a.imageset/form_<name>_a.png
    Flip54/Assets.xcassets/FormGuides/form_<name>_b.imageset/form_<name>_b.png
"""

import sys, os, json
from PIL import Image
import numpy as np

XCASSETS = os.path.join(os.path.dirname(__file__),
                        "../../Flip54/Assets.xcassets/FormGuides")

OUT_W     = 1600
OUT_H     = 720
FLOOR_PAD = 30
TIGHT_PAD = 20


def tight_crop(img):
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    rows, cols = np.any(mask, axis=1), np.any(mask, axis=0)
    if not rows.any():
        return img
    r0, r1 = np.where(rows)[0][[0,-1]]
    c0, c1 = np.where(cols)[0][[0,-1]]
    W, H = img.size
    return img.crop((max(0,c0-TIGHT_PAD), max(0,r0-TIGHT_PAD),
                     min(W,c1+TIGHT_PAD), min(H,r1+TIGHT_PAD)))


def make_aligned_frames(a_path, b_path, mode="side"):
    a = tight_crop(Image.open(a_path).convert("RGBA"))
    b = tight_crop(Image.open(b_path).convert("RGBA"))
    aw, ah = a.size
    bw, bh = b.size

    usable_h = OUT_H - FLOOR_PAD
    scale = min(OUT_W / max(aw, bw), usable_h / max(ah, bh)) * 0.92

    def resize(img):
        w, h = img.size
        return img.resize((int(w*scale), int(h*scale)), Image.LANCZOS)

    a_s, b_s = resize(a), resize(b)

    def place(img_s):
        iw, ih = img_s.size
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (255,255,255,255))
        oy = OUT_H - FLOOR_PAD - ih
        if mode == "front":
            ox = (OUT_W - iw) // 2
        else:
            ox = (OUT_W - int(max(aw, bw) * scale)) // 2
        canvas.paste(img_s, (ox, oy), img_s)
        return canvas

    return place(a_s), place(b_s)


def write_imageset(name, img):
    iset_dir = os.path.join(XCASSETS, f"{name}.imageset")
    os.makedirs(iset_dir, exist_ok=True)
    fname = f"{name}.png"
    img.convert("RGB").save(os.path.join(iset_dir, fname), optimize=True)
    contents = {
        "images": [
            {"filename": fname, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(iset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  ✓ {name}")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: export_frames.py <rawValue> <a.png> <b.png> [side|front]")
        sys.exit(1)
    name  = sys.argv[1]
    a_png = sys.argv[2]
    b_png = sys.argv[3]
    mode  = sys.argv[4] if len(sys.argv) > 4 else "side"

    frame_a, frame_b = make_aligned_frames(a_png, b_png, mode)
    write_imageset(f"form_{name}_a", frame_a)
    write_imageset(f"form_{name}_b", frame_b)
