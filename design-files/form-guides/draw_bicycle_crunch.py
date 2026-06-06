"""
Bicycle crunch form guide illustrations — 3/4 elevated side view.

Frame A: Right knee pulled toward chest, left leg fully extended.
         Right elbow reaches toward raised right knee (left elbow stays back).
Frame B: Left knee pulled toward chest, right leg fully extended.
         Left elbow reaches toward raised left knee (right elbow stays back).

The 3/4 view means we see both sides of the body, making the alternating
leg motion unambiguous across both frames.

Output: source/bicycle_crunch_a.png, source/bicycle_crunch_b.png
Run process_ab_exercises.py next to export these into xcassets.
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, Polygon, FancyBboxPatch
from matplotlib.path import Path
from matplotlib.patches import PathPatch
import numpy as np
from PIL import Image
import io, os

BASE   = os.path.dirname(os.path.abspath(__file__))
STROKE = '#1A1A1A'
FILL   = '#FFFFFF'
LW     = 3.2
LW_TH  = 1.9
FW, FH = 16.0, 7.2   # inches @ 100dpi → 1600×720 px


# ── Canvas ────────────────────────────────────────────────────────────────────

def make_canvas():
    fig, ax = plt.subplots(figsize=(FW, FH), dpi=100)
    ax.set_xlim(0, FW); ax.set_ylim(0, FH)
    ax.set_aspect('equal'); ax.axis('off')
    fig.patch.set_facecolor(FILL); ax.set_facecolor(FILL)
    return fig, ax


# ── Primitives ────────────────────────────────────────────────────────────────

def limb(ax, p1, p2, w, zo=2, lw=None):
    """Rounded rectangle connecting two joint centres."""
    lw = lw or LW
    p1, p2 = np.array(p1, float), np.array(p2, float)
    d = p2 - p1; ln = np.hypot(*d)
    if ln < 0.01: return
    n = np.array([-d[1], d[0]]) / ln * w
    ax.add_patch(Polygon([p1+n, p2+n, p2-n, p1-n],
                          fc=FILL, ec=STROKE, lw=lw, zorder=zo))
    for p in (p1, p2):
        ax.add_patch(Ellipse(p, w*2.1, w*2.1,
                              fc=FILL, ec=STROKE, lw=lw, zorder=zo+1))

def oval(ax, centre, rx, ry, angle=0, zo=3):
    ax.add_patch(Ellipse(centre, rx*2, ry*2, angle=angle,
                          fc=FILL, ec=STROKE, lw=LW, zorder=zo))

def shoe(ax, ankle, direction, zo=3):
    """Simple athletic shoe shape."""
    ankle = np.array(ankle, float)
    # direction: unit vector pointing the way the foot faces
    d = np.array(direction, float); d /= np.hypot(*d)
    p = np.array([-d[1], d[0]])          # perpendicular
    tip   = ankle + d*0.70
    heel  = ankle - d*0.20
    sole_h = 0.22
    verts = [
        heel  - p*sole_h*0.5,
        heel  + p*sole_h*0.8,
        tip   + p*sole_h*0.9,
        tip   + p*sole_h*0.3,
        tip   - p*sole_h*0.1,
        heel  - p*sole_h*0.5,
    ]
    ax.add_patch(Polygon(verts, fc=FILL, ec=STROKE, lw=LW_TH, zorder=zo))


# ── Figure ────────────────────────────────────────────────────────────────────
#
# 3/4 elevated side view.  The person lies on their back.  We look at them
# from roughly 30° above and 20° to the right of their head-to-foot axis.
# This makes BOTH legs independently visible and the shoulder rotation legible.
#
# Coordinate layout (canvas units, x right, y up):
#   - Person's head-to-foot axis runs roughly left→right.
#   - Person's right side is ABOVE the centre line.
#   - Person's left  side is BELOW the centre line.
#   - Ground plane is at y ≈ 1.8, back (floor contact) at y ≈ 2.3.
#
# Frame A  (right_knee_up = True):
#   Right thigh  → rises ABOVE centre line toward head, prominent
#   Left  leg    → extends away to the right, BELOW centre line, low
#   Right elbow  → reaches toward the raised right knee (active arm)
#   Left  elbow  → stays behind head (passive arm)
#
# Frame B  (right_knee_up = False):
#   Left  thigh  → rises BELOW centre line toward head
#   Right leg    → extends away to the right, ABOVE centre line, low
#   Left  elbow  → reaches toward the raised left knee
#   Right elbow  → stays behind head

def draw_figure(ax, right_knee_up: bool):
    GND = 2.0      # floor y
    CX  = FW / 2   # horizontal centre ≈ 8

    # ── Fixed landmarks ──────────────────────────────────────────────────────
    hips      = np.array([8.4, GND + 0.35])
    shoulders = np.array([4.8, GND + 2.40])   # lifted in the crunch
    head_c    = np.array([3.2, GND + 3.55])

    # ── Leg geometry ─────────────────────────────────────────────────────────
    if right_knee_up:
        # Right (near / above-centre-line) knee raised toward chest
        raised_hip   = hips   + np.array([ 0.0,  0.45])   # right hip
        raised_knee  = np.array([6.0, GND + 4.20])        # high, near head
        raised_ankle = np.array([7.0, GND + 5.60])        # foot tucked above knee

        # Left (far / below-centre-line) leg fully extended
        ext_hip      = hips   + np.array([ 0.0, -0.35])   # left hip
        ext_knee     = np.array([12.0, GND + 0.20])       # far right, very low
        ext_ankle    = np.array([14.8, GND + 0.00])       # nearly at floor level
        ext_foot_dir = np.array([1.0, -0.1])              # pointing right/slightly down

        # Arms: right elbow active (reaches toward raised right knee)
        sh_active  = shoulders + np.array([ 0.3,  0.35])  # right shoulder (near side)
        sh_passive = shoulders + np.array([-0.3, -0.20])  # left shoulder (far side)
        elb_active = np.array([5.6, GND + 3.80])          # right elbow forward
        hand_active= np.array([6.0, GND + 3.30])          # hand near raised knee
        elb_passive= np.array([2.6, GND + 5.00])          # left elbow behind head
        hand_passive=np.array([3.8, GND + 4.50])

    else:
        # Left (far / below-centre-line) knee raised toward chest
        raised_hip   = hips   + np.array([ 0.0, -0.45])   # left hip
        raised_knee  = np.array([6.5, GND + 3.50])        # raised, but below centre
        raised_ankle = np.array([8.0, GND + 4.90])        # foot tucked

        # Right (near / above-centre-line) leg fully extended
        ext_hip      = hips   + np.array([ 0.0,  0.35])
        ext_knee     = np.array([12.0, GND + 0.50])
        ext_ankle    = np.array([14.8, GND + 0.30])
        ext_foot_dir = np.array([1.0,  0.05])

        # Arms: left elbow active (reaches toward raised left knee)
        sh_active  = shoulders + np.array([-0.3, -0.30])  # left shoulder
        sh_passive = shoulders + np.array([ 0.3,  0.25])  # right shoulder
        elb_active = np.array([5.2, GND + 3.20])
        hand_active= np.array([6.3, GND + 3.70])
        elb_passive= np.array([2.4, GND + 4.70])
        hand_passive=np.array([3.6, GND + 4.20])

    # ── Draw order: far elements first ───────────────────────────────────────

    # Extended leg (far side, low, drawn behind torso)
    limb(ax, ext_hip, ext_knee,  0.30, zo=1)
    limb(ax, ext_knee, ext_ankle, 0.21, zo=1)
    shoe(ax, ext_ankle, ext_foot_dir, zo=2)

    # Passive arm (far side / behind head)
    limb(ax, sh_passive, elb_passive,  0.14, zo=2)
    limb(ax, elb_passive, hand_passive, 0.10, zo=2)

    # Torso
    d_t = shoulders - hips; ln_t = np.hypot(*d_t)
    n_t = np.array([-d_t[1], d_t[0]]) / ln_t
    tw  = 0.42
    ax.add_patch(Polygon([hips+n_t*tw*1.0, shoulders+n_t*tw*0.80,
                           shoulders-n_t*tw*0.65, hips-n_t*tw*0.85],
                           fc=FILL, ec=STROKE, lw=LW, zorder=3))

    # Neck
    neck_base = shoulders + np.array([-0.08,  0.18])
    neck_top  = head_c    + np.array([ 0.22, -0.52])
    limb(ax, neck_base, neck_top, 0.19, zo=4)

    # Head
    oval(ax, head_c, 0.52, 0.63, zo=5)

    # Raised leg (near side, prominent)
    limb(ax, raised_hip, raised_knee,  0.31, zo=4)
    limb(ax, raised_knee, raised_ankle, 0.22, zo=4)
    # Foot for raised leg — direction from knee to ankle
    rk_dir = raised_ankle - raised_knee; rk_dir /= np.hypot(*rk_dir)
    shoe(ax, raised_ankle, rk_dir, zo=5)

    # Active arm (near side, reaches toward raised knee)
    limb(ax, sh_active, elb_active,  0.15, zo=5)
    limb(ax, elb_active, hand_active, 0.11, zo=5)


# ── Export ────────────────────────────────────────────────────────────────────

def save(right_knee_up: bool, suffix: str):
    fig, ax = make_canvas()
    draw_figure(ax, right_knee_up)
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=100, bbox_inches='tight',
                facecolor=FILL, edgecolor='none')
    plt.close(fig)
    buf.seek(0)
    path = os.path.join(BASE, 'source', f'bicycle_crunch_{suffix}.png')
    Image.open(buf).save(path)
    print(f"  Saved {path}")

os.makedirs(os.path.join(BASE, 'source'), exist_ok=True)
save(right_knee_up=True,  suffix='a')   # right knee raised
save(right_knee_up=False, suffix='b')   # left knee raised
print("Done.")
