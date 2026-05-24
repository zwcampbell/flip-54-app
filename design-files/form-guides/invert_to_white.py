"""
Convert all form guide assets from black-lines-on-white to white-lines-on-transparent.

For each pixel: alpha = 255 - luminance, color = white.
Black lines → fully opaque white.
Grey shading → semi-transparent white.
White background → fully transparent.
"""

import os, glob
import numpy as np
from PIL import Image

XCASSETS = "../../Flip54/Assets.xcassets/FormGuides"

def convert(path):
    img = Image.open(path).convert("RGBA")
    arr = np.array(img, dtype=np.float32)

    # Luminance from RGB channels (standard weights)
    lum = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]

    out = np.zeros_like(arr)
    out[:,:,0] = 255          # R = white
    out[:,:,1] = 255          # G = white
    out[:,:,2] = 255          # B = white
    out[:,:,3] = 255 - lum    # A = inverted luminance

    result = Image.fromarray(out.astype(np.uint8), "RGBA")
    result.save(path, optimize=True)

pattern = os.path.join(XCASSETS, "form_*.imageset", "form_*.png")
paths = sorted(glob.glob(pattern))
print(f"Converting {len(paths)} assets…")
for p in paths:
    convert(p)
    print(f"  ✓ {os.path.basename(os.path.dirname(p))}")
print("Done.")
