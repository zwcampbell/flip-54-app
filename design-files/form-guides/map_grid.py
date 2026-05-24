"""
Analyse all_exercises.png, find exercise pair bounding boxes,
draw a labelled overlay image for visual verification.
"""

from PIL import Image, ImageDraw, ImageFont
import numpy as np

SRC = "source/all_exercises.png"
img = Image.open(SRC).convert("RGB")
W, H = img.size
arr = np.array(img)

# Non-white mask
mask = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))

# ── Detect horizontal band rows ──────────────────────────────────────────────
# For each row of pixels, count how many non-white pixels exist.
# A row with zero (or near-zero) pixels = a gap between exercise rows.

row_counts = mask.sum(axis=1).astype(float)

# Smooth to avoid noise
from numpy.lib.stride_tricks import sliding_window_view
SMOOTH = 5
row_smooth = np.convolve(row_counts, np.ones(SMOOTH)/SMOOTH, mode='same')

# Find transitions: gap→content (start of row) and content→gap (end of row)
THRESH = 8
in_band = row_smooth > THRESH
transitions = np.diff(in_band.astype(int))
band_starts = np.where(transitions == 1)[0] + 1
band_ends   = np.where(transitions == -1)[0] + 1

print(f"Image: {W}×{H}")
print(f"\nHorizontal bands (exercise rows):")
bands = list(zip(band_starts, band_ends))
for i, (s, e) in enumerate(bands):
    print(f"  Band {i}: y={s}–{e}  (h={e-s})")

# ── Detect column splits within each band ────────────────────────────────────
# For each band, project non-white pixels onto X axis, find gaps.

def find_col_groups(band_mask, min_gap=12):
    col_counts = band_mask.sum(axis=0).astype(float)
    col_smooth = np.convolve(col_counts, np.ones(5)/5, mode='same')
    in_group = col_smooth > 3
    trans = np.diff(in_group.astype(int))
    starts = list(np.where(trans == 1)[0] + 1)
    ends   = list(np.where(trans == -1)[0] + 1)
    if in_group[0]:  starts.insert(0, 0)
    if in_group[-1]: ends.append(len(in_group))

    # Merge groups that are close together (belong to same exercise pair)
    groups = []
    i = 0
    while i < len(starts):
        gs, ge = starts[i], ends[i]
        # Merge with next group if gap is small
        while i+1 < len(starts) and starts[i+1] - ge < min_gap:
            i += 1
            ge = ends[i]
        groups.append((gs, ge))
        i += 1
    return groups

print(f"\nExercise groups per band:")
all_boxes = []  # (x1,y1,x2,y2)
for bi, (ys, ye) in enumerate(bands):
    band_mask = mask[ys:ye, :]
    groups = find_col_groups(band_mask, min_gap=20)
    print(f"  Band {bi} (y={ys}-{ye}): {len(groups)} groups")
    for gi, (xs, xe) in enumerate(groups):
        print(f"    Group {gi}: x={xs}–{xe}")
        all_boxes.append((xs, ys, xe, ye))

# ── Draw overlay ──────────────────────────────────────────────────────────────
COLORS = ["#e74c3c","#3498db","#2ecc71","#f39c12","#9b59b6",
          "#1abc9c","#e67e22","#e91e63","#00bcd4","#8bc34a"]

overlay = img.copy().convert("RGBA")
draw = ImageDraw.Draw(overlay, "RGBA")

for i, (x1,y1,x2,y2) in enumerate(all_boxes):
    c = COLORS[i % len(COLORS)]
    draw.rectangle([x1,y1,x2,y2], outline=c+"ff", width=3)
    draw.text((x1+4, y1+4), str(i), fill=c+"ff")

overlay.convert("RGB").save("grid_overlay.png")
print(f"\nSaved grid_overlay.png  ({len(all_boxes)} boxes detected)")
