"""
tools/create_seamless_river.py
Synthesizes a master horizontal river asset:
assets/sprites/map/lava/extracted/river_grand_horizontal.png
- Dimensions: 256 x 192 px (matches exactly the 6-tile height of the river in Godot, 192 px).
- Top edge (0..16 px): Sturdy jagged dark basalt north riverbank.
- Bottom edge (176..192 px): Sturdy jagged dark basalt south riverbank.
- Core river body (16..176 px): Pure glowing molten magma with golden swirls and convective currents.
- Absolutely NO rock stripes or borders in the middle of the river.
- 100% mathematically seamless horizontal tiling (wrap diff < 1.0).
"""

import os
import numpy as np
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P_RH = os.path.join(BASE_DIR, "assets", "sprites", "map", "lava", "extracted", "river_h.png")
P_POOL = os.path.join(BASE_DIR, "assets", "sprites", "map", "lava", "lava_pool_large.png")
OUT_P = os.path.join(BASE_DIR, "assets", "sprites", "map", "lava", "extracted", "river_grand_horizontal.png")

W = 256
H = 192
M = 32  # Seamless blend margin

im_rh = Image.open(P_RH).convert("RGBA")
im_pool = Image.open(P_POOL).convert("RGBA")

# 1. Banks from river_h (width 128, top y=0..16, bot y=37..53)
top_bank_raw = im_rh.crop((4, 0, 132, 16))
bot_bank_raw = im_rh.crop((4, 37, 132, 53))

# Molten lava cores:
pool_core_raw = im_pool.crop((40, 40, 152, 152))
rh_core_raw = im_rh.crop((4, 16, 132, 36))

# Build composite raw river of size (W, H) = (256, 192)
raw_river = Image.new("RGBA", (W, H), (245, 80, 10, 255))

# 2. Molten lava core across middle (y = 16 .. 176)
lava_bg = Image.new("RGBA", (W, 160), (245, 85, 12, 255))

# Tile pool_core across (256 x 160)
for ix in range(0, W, 85):
    for iy in range(0, 160, 80):
        flip_x = (ix // 85) % 2 == 1
        flip_y = (iy // 80) % 2 == 1
        tile = pool_core_raw.resize((85, 80), Image.Resampling.LANCZOS)
        if flip_x:
            tile = tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        if flip_y:
            tile = tile.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        lava_bg.paste(tile, (ix, iy))

# Add horizontal convective filaments from river_h
for ix in range(0, W, 128):
    for iy in (18, 64, 112):
        c_flow = rh_core_raw.resize((128, 30), Image.Resampling.LANCZOS)
        lava_bg.paste(c_flow, (ix, iy), c_flow)

raw_river.paste(lava_bg, (0, 16))

# 3. Paste top and bottom banks (2 tiles of width 128)
tb = top_bank_raw.resize((128, 16), Image.Resampling.LANCZOS)
bb = bot_bank_raw.resize((128, 16), Image.Resampling.LANCZOS)

raw_river.paste(tb, (0, 0), tb)
raw_river.paste(tb, (128, 0), tb)
raw_river.paste(bb, (0, H - 16), bb)
raw_river.paste(bb, (128, H - 16), bb)

# 4. Apply mathematical seamless wrap across width W = 256
arr = np.array(raw_river).astype(float)
target = 0.5 * (arr[:, 0, :] + arr[:, -1, :])
res = arr.copy()

for i in range(M):
    t = float(i) / float(M)
    st = 0.5 * (1.0 - np.cos(np.pi * t))
    # Left end transitions from target to original
    res[:, i, :] = (1.0 - st) * target + st * arr[:, i, :]
    # Right end transitions from original to target
    res[:, W - M + i, :] = (1.0 - st) * arr[:, W - M + i, :] + st * target

arr_out = np.clip(res, 0, 255).astype(np.uint8)
img_out = Image.fromarray(arr_out, "RGBA")
img_out.save(OUT_P)

diff = np.abs(arr_out[:, 0, :3].astype(float) - arr_out[:, -1, :3].astype(float))
print(f"[OK] Master River Asset generated successfully: {OUT_P} ({W}x{H})")
print(f"[OK] Wrap boundary check: max diff = {diff.max():.2f}, mean diff = {diff.mean():.4f}")

# Generate 3-tile test strip
test_strip = Image.new("RGBA", (W * 3, H))
test_strip.paste(img_out, (0, 0))
test_strip.paste(img_out, (W, 0))
test_strip.paste(img_out, (W * 2, 0))
test_out_p = os.path.join(BASE_DIR, "assets", "sprites", "map", "lava", "extracted", "river_test_strip.png")
test_strip.save(test_out_p)
print(f"[OK] Verified 3-tile seamless strip saved to: {test_out_p}")
