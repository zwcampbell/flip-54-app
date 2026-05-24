"""
Produce a 2-frame looping animation from two exercise pose PNGs.

Alignment strategy:
  - Both frames scaled by the SAME factor (so anatomy stays proportional)
  - Bottom-aligned: floor contact point at the same Y in every frame
  - Horizontal: 'side' mode → left-aligned (feet stay planted)
                'front' mode → center-aligned (symmetric exercises)

Usage:
    python3 make_exercise_gif.py <a.png> <b.png> <out.gif> [side|front]
"""

import sys
from PIL import Image
import numpy as np

OUT_W     = 1600
OUT_H     = 720
FLOOR_PAD = 30    # px from canvas bottom to floor line
HOLD_MS   = 900
BLEND_MS  = 130
N_BLEND   = 3
TIGHT_PAD = 20    # px padding around tight crop


def tight_crop(img: Image.Image) -> Image.Image:
    arr = np.array(img.convert("RGBA"))
    mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    if not rows.any():
        return img
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    W, H = img.size
    return img.crop((
        max(0, c0 - TIGHT_PAD), max(0, r0 - TIGHT_PAD),
        min(W, c1 + TIGHT_PAD), min(H, r1 + TIGHT_PAD)
    ))


def make_frames(a_path: str, b_path: str, mode: str = "side"):
    """
    Return (frame_a, frame_b) as RGBA images on OUT_W×OUT_H canvases,
    both anchored so the floor line is consistent across frames.
    """
    a = tight_crop(Image.open(a_path).convert("RGBA"))
    b = tight_crop(Image.open(b_path).convert("RGBA"))

    aw, ah = a.size
    bw, bh = b.size

    # Usable canvas height above the floor margin
    usable_h = OUT_H - FLOOR_PAD
    usable_w = OUT_W

    # Common scale: fit the LARGER of the two figures, apply to both
    scale = min(usable_w / max(aw, bw), usable_h / max(ah, bh)) * 0.92

    def resize(img):
        w, h = img.size
        return img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)

    a_s = resize(a)
    b_s = resize(b)

    def place(img_s):
        iw, ih = img_s.size
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (255, 255, 255, 255))

        # Y: bottom of figure sits on the floor line
        oy = OUT_H - FLOOR_PAD - ih

        if mode == "front":
            # Center horizontally
            ox = (OUT_W - iw) // 2
        else:
            # 'side': left-align — feet stay at the same X anchor
            left_margin = (OUT_W - int(max(aw, bw) * scale)) // 2
            ox = left_margin

        canvas.paste(img_s, (ox, oy), img_s)
        return canvas

    return place(a_s), place(b_s)


def make_gif(a_path: str, b_path: str, out_path: str, mode: str = "side"):
    frame_a, frame_b = make_frames(a_path, b_path, mode)

    def blend_seq(x, y):
        return [Image.blend(x, y, t / (N_BLEND + 1)).convert("RGBA")
                for t in range(1, N_BLEND + 1)]

    frames = (
        [frame_a] +
        blend_seq(frame_a, frame_b) +
        [frame_b] +
        blend_seq(frame_b, frame_a)
    )
    durations = [HOLD_MS] + [BLEND_MS] * N_BLEND + [HOLD_MS] + [BLEND_MS] * N_BLEND

    pals = [f.convert("P", palette=Image.ADAPTIVE, colors=256) for f in frames]
    pals[0].save(out_path, save_all=True, append_images=pals[1:],
                 loop=0, duration=durations, disposal=2)
    print(f"  → {out_path}  ({len(frames)} frames, mode={mode})")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: make_exercise_gif.py <a.png> <b.png> <out.gif> [side|front]")
        sys.exit(1)
    mode = sys.argv[4] if len(sys.argv) > 4 else "side"
    make_gif(sys.argv[1], sys.argv[2], sys.argv[3], mode)
