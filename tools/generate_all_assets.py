import os
import math
import random
from PIL import Image, ImageDraw, ImageFont

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

PREVIEW_DIR = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\laporan_assets\asset_previews"
SPRITES_DIR = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\assets\sprites"
ARTIFACT_DIR = r"C:\Users\MyBook Hype AMD\.gemini\antigravity\brain\07868943-55b7-4b4c-ab20-c1b7547b1bbf"

ensure_dir(PREVIEW_DIR)
ensure_dir(ARTIFACT_DIR)

# ==========================================
# 1. A1: MODULAR STONE BRIDGE TILESET (32x32)
# ==========================================
def generate_stone_bridge_tileset():
    # 4 columns x 2 rows of 32x32 tiles = 128 x 64
    w, h = 128, 64
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Palette
    c_deck_base = (48, 42, 54, 255)
    c_deck_dark = (32, 28, 38, 255)
    c_deck_light = (68, 60, 76, 255)
    c_deck_mortar = (20, 16, 24, 255)

    # Tile (0, 0): Regular Stone Paver Deck
    for y in range(32):
        for x in range(32):
            # Hex-ish / rectangular paver brick pattern
            row_idx = y // 8
            offset = 16 if (row_idx % 2 == 1) else 0
            col_idx = (x + offset) // 16
            
            # Mortar lines
            is_mortar = (y % 8 == 0) or ((x + offset) % 16 == 0)
            if is_mortar:
                c = c_deck_mortar
            else:
                # Stone noise
                noise = ((x * 7 + y * 13) % 11) - 5
                # Bevel
                local_y = y % 8
                local_x = (x + offset) % 16
                if local_y == 1 or local_x == 1:
                    c = tuple(min(255, max(0, val + noise + 18)) for val in c_deck_light[:3]) + (255,)
                elif local_y == 7 or local_x == 15:
                    c = tuple(min(255, max(0, val + noise - 12)) for val in c_deck_dark[:3]) + (255,)
                else:
                    c = tuple(min(255, max(0, val + noise)) for val in c_deck_base[:3]) + (255,)
            im.putpixel((x, y), c)

    # Tile (1, 0): Scorched Volcanic Shortcut Deck (Infused with red magma mortar)
    c_scorch_base = (38, 24, 28, 255)
    c_scorch_light = (58, 36, 42, 255)
    c_magma_glow = (240, 80, 20, 255)
    c_magma_core = (255, 200, 50, 255)
    for y in range(32):
        for x in range(32):
            px = 32 + x
            row_idx = y // 8
            offset = 16 if (row_idx % 2 == 1) else 0
            is_mortar = (y % 8 == 0) or ((x + offset) % 16 == 0)
            if is_mortar:
                # Glowing magma mortar
                if (x * y + x + y) % 5 == 0:
                    c = c_magma_core
                else:
                    c = c_magma_glow
            else:
                noise = ((x * 11 + y * 5) % 9) - 4
                c = tuple(min(255, max(0, val + noise)) for val in c_scorch_base[:3]) + (255,)
            im.putpixel((px, y), c)

    # Tile (2, 0): Top Stone Parapet Railing
    c_rail_stone = (72, 64, 82, 255)
    c_rail_shadow = (25, 20, 30, 255)
    for y in range(32):
        for x in range(32):
            px = 64 + x
            # Top rail lip at y=0..8, posts at x=0..6, 25..31
            if y < 8:
                c = c_rail_stone if y > 1 else (95, 85, 108, 255)
            elif y >= 8 and (x < 6 or x >= 26 or 13 <= x <= 18):
                # Carved balustrade column
                c = c_rail_stone if (x % 5 != 0) else c_rail_shadow
            elif y >= 26:
                # Curb line
                c = c_deck_mortar
            else:
                # Gap through railing showing empty / drop shadow
                c = (15, 12, 18, 160)
            im.putpixel((px, y), c)

    # Tile (3, 0): Bottom Stone Parapet Railing with Cast Drop Shadow
    for y in range(32):
        for x in range(32):
            px = 96 + x
            if y < 6:
                # Curb line
                c = c_deck_mortar
            elif 6 <= y < 24 and (x < 6 or x >= 26 or 13 <= x <= 18):
                c = c_rail_stone if (x % 5 != 0) else c_rail_shadow
            elif 24 <= y <= 31:
                # Bottom handrail edge
                c = c_rail_stone if y < 30 else c_rail_shadow
            else:
                # Ambient abyss shadow under bridge
                shadow_alpha = int(220 * (y / 32.0))
                c = (10, 8, 14, shadow_alpha)
            im.putpixel((px, y), c)

    # Row 1 (y=32..63): Side Edges & Corner Spire Posts
    # Tile (0, 1): Left Bridge Edge Railing (32x32)
    for y in range(32):
        for x in range(32):
            py = 32 + y
            if x < 6:
                # Sturdy outer parapet wall
                c = (85, 75, 98, 255) if x == 1 else (60, 52, 70, 255) if x < 5 else (30, 25, 36, 255)
            else:
                # Deck pavers
                c = c_deck_base if ((x + y) % 7 != 0) else c_deck_mortar
            im.putpixel((x, py), c)

    # Tile (1, 1): Right Bridge Edge Railing (32x32)
    for y in range(32):
        for x in range(32):
            px = 32 + x
            py = 32 + y
            if x >= 26:
                c = (85, 75, 98, 255) if x == 30 else (60, 52, 70, 255) if x > 26 else (30, 25, 36, 255)
            else:
                c = c_deck_base if ((x + y) % 7 != 0) else c_deck_mortar
            im.putpixel((px, py), c)

    # Tile (2, 1): Ornate Gargoyle Spire Pillar Post (Corner Anchor)
    for y in range(32):
        for x in range(32):
            px = 64 + x
            py = 32 + y
            dx = abs(x - 16)
            dy = abs(y - 16)
            dist = math.sqrt(dx*dx + dy*dy)
            if dist <= 12:
                # Octagonal pillar top with red jewel core
                if dist <= 4:
                    c = (230, 45, 30, 255) if dist <= 2 else (160, 20, 15, 255)
                elif dist <= 9:
                    c = (88, 78, 102, 255) if x < 16 else (50, 44, 60, 255)
                else:
                    c = (28, 24, 34, 255)
                im.putpixel((px, py), c)
            elif y >= 20 and dist <= 15:
                # Heavy stone pedestal base
                c = (45, 38, 52, 255)
                im.putpixel((px, py), c)

    # Tile (3, 1): Bridge Approach Ramp (Cobblestone Flaring)
    for y in range(32):
        for x in range(32):
            px = 96 + x
            py = 32 + y
            flare = 16 - abs(x - 16)
            if y < 16:
                # Transition slope
                shade = int(45 + y * 1.5)
                c = (shade, shade - 6, shade + 8, 255)
            else:
                c = c_deck_base if ((x * 3 + y * 7) % 6 != 0) else c_deck_mortar
            im.putpixel((px, py), c)

    # Save master tileset
    tileset_path = os.path.join(PREVIEW_DIR, "A1_bridge_stone_tileset.png")
    im.save(tileset_path)
    print("Generated A1 Tileset ->", tileset_path)

    # Create a 4x5 assembled bridge demo preview (128x160 px) scaled 2x
    demo = Image.new("RGBA", (128, 160), (18, 12, 16, 255))
    # Pavers in middle
    tile_paver = im.crop((0, 0, 32, 32))
    tile_scorch = im.crop((32, 0, 64, 32))
    tile_rail_l = im.crop((0, 32, 32, 32))
    tile_rail_r = im.crop((32, 32, 64, 32))
    tile_pillar = im.crop((64, 32, 96, 32))

    for by in range(5):
        for bx in range(4):
            xpos, ypos = bx * 32, by * 32
            if bx == 0:
                demo.paste(tile_rail_l, (xpos, ypos), tile_rail_l)
            elif bx == 3:
                demo.paste(tile_rail_r, (xpos, ypos), tile_rail_r)
            else:
                demo.paste(tile_paver, (xpos, ypos))

    # Corner pillars
    demo.paste(tile_pillar, (0, 0), tile_pillar)
    demo.paste(tile_pillar, (96, 0), tile_pillar)
    demo.paste(tile_pillar, (0, 128), tile_pillar)
    demo.paste(tile_pillar, (96, 128), tile_pillar)

    demo_scaled = demo.resize((256, 320), Image.NEAREST)
    demo_path = os.path.join(PREVIEW_DIR, "A1_bridge_assembled_demo.png")
    demo_scaled.save(demo_path)
    return tileset_path, demo_path

# ==========================================================
# 2. A2: ANIMATED FLAME COLUMN / MAGMA GEYSER VFX (32x64 x 6 frames)
# ==========================================================
def generate_flame_column_sheet():
    frames = 6
    fw, fh = 32, 64
    w, h = fw * frames, fh
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Flame palette
    c_core_white = (255, 255, 220, 255)
    c_core_yellow = (255, 225, 40, 255)
    c_magma_orange = (255, 110, 15, 255)
    c_deep_red = (200, 30, 10, 255)
    c_dark_smoke = (40, 20, 25, 180)

    for f in range(frames):
        fx_offset = f * fw
        # Frame height progression: 10px -> 25px -> 52px -> 60px -> 45px -> 20px
        heights = [12, 28, 54, 62, 48, 22]
        cur_h = heights[f]
        
        for y in range(fh):
            from_bottom = fh - 1 - y
            if from_bottom > cur_h:
                # Smoke or embers near top
                if f in [3, 4, 5] and from_bottom <= cur_h + 14:
                    smoke_noise = (f * 17 + y * 7) % 6
                    if smoke_noise == 0:
                        im.putpixel((fx_offset + 14 + (y % 5) - 2, y), c_dark_smoke)
                continue
            
            # Width taper towards top
            progress = from_bottom / float(cur_h)  # 0 at bottom, 1 at top
            max_r = (14.0 if from_bottom < 15 else (14.0 * (1.1 - 0.7 * progress)))
            # Sinuous wiggle
            center_x = 16 + int(3.5 * math.sin((y * 0.4) + f * 1.2))

            for x in range(fw):
                dx = abs(x - center_x)
                if dx > max_r:
                    continue
                norm_d = dx / max_r  # 0 at center, 1 at edge
                
                # Core vs outer rim
                if norm_d < 0.25 and progress < 0.6:
                    c = c_core_white
                elif norm_d < 0.50 and progress < 0.8:
                    c = c_core_yellow
                elif norm_d < 0.80:
                    c = c_magma_orange
                else:
                    c = c_deep_red
                
                # Ember dissipation
                if progress > 0.85 and (x + y + f) % 3 == 0:
                    c = (c[0], c[1], c[2], 120)

                im.putpixel((fx_offset + x, y), c)

    out_path = os.path.join(PREVIEW_DIR, "A2_vfx_flame_column_sheet.png")
    im.save(out_path)
    print("Generated A2 Flame Column ->", out_path)
    return out_path

# ==========================================================
# 3. A3: WARNING MAGMA CRACKS & STEAM TELEGRAPH (32x32 x 4 frames)
# ==========================================================
def generate_warning_cracks_sheet():
    frames = 4
    fw, fh = 32, 32
    w, h = fw * frames, fh
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    for f in range(frames):
        fx = f * fw
        # Glow intensity rises across frames
        glow_alpha = [90, 160, 230, 255][f]
        core_col = [
            (180, 50, 10, glow_alpha),
            (240, 90, 15, glow_alpha),
            (255, 170, 30, glow_alpha),
            (255, 235, 90, glow_alpha),
        ][f]

        # Draw dark cracked basalt bed
        for y in range(32):
            for x in range(32):
                # Jagged fissure line from (6, 26) to (26, 6)
                cx = 16 + int(5 * math.sin((y - 16) / 3.5)) + (1 if y % 4 == 0 else -1)
                dist = abs(x - cx)
                
                if dist == 0:
                    c = core_col
                elif dist == 1:
                    c = (core_col[0] // 2 + 50, core_col[1] // 2, 10, int(glow_alpha * 0.8))
                elif dist == 2:
                    c = (35, 15, 12, int(glow_alpha * 0.6))
                elif dist <= 4 and f >= 2:
                    # Ambient magma heat aura
                    aura = int((5 - dist) * 20)
                    c = (120, 35, 10, aura)
                else:
                    c = (0, 0, 0, 0)
                
                # Steam puff at top during f >= 1
                if f >= 1 and y < 12:
                    steam_cx = 16 + int(3 * math.sin(y * 0.7 + f))
                    if abs(x - steam_cx) <= (f):
                        steam_a = int(60 * (1.0 - y / 12.0) * (f / 3.0))
                        c = (200, 190, 180, steam_a)

                im.putpixel((fx + x, y), c)

    out_path = os.path.join(PREVIEW_DIR, "A3_vfx_warning_crack_sheet.png")
    im.save(out_path)
    print("Generated A3 Warning Cracks ->", out_path)
    return out_path

# ==========================================================
# 4. A8: SPINNING ELEMENTAL SHARDS SPRITESHEET (32x32 x 4 frames x 3 types)
# ==========================================================
def generate_spinning_shards_sheet():
    frames = 4
    fw, fh = 32, 32
    w, h = fw * frames, fh * 3  # 128 x 96
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    elements = [
        # (name, core, mid, dark, glow)
        ("Flame", (255, 240, 120), (255, 110, 20), (160, 25, 10), (255, 80, 10, 70)),
        ("Shadow", (240, 180, 255), (160, 50, 220), (70, 15, 120), (140, 30, 200, 70)),
        ("Blood", (255, 140, 150), (210, 25, 45), (105, 10, 20), (190, 15, 30, 70)),
    ]

    for row, (el_name, c_core, c_mid, c_dark, c_glow) in enumerate(elements):
        fy = row * fh
        for f in range(frames):
            fx = f * fw
            # Rotation angle: 0, 45, 90 (thin), 135
            # Apparent width factor based on angle
            angle = (f / float(frames)) * math.pi
            scale_x = max(0.25, abs(math.cos(angle)))
            half_w = 9.0 * scale_x
            half_h = 12.0

            for y in range(32):
                for x in range(32):
                    dx = abs(x - 16)
                    dy = abs(y - 16)
                    # Octagonal crystal facet
                    if (dx / half_w) + (dy / half_h) <= 1.0:
                        # Facet shading based on x and rotation
                        norm_x = (x - 16) / half_w
                        norm_y = (y - 16) / half_h
                        if norm_x < -0.2:
                            c = c_mid + (255,)
                        elif norm_x > 0.2:
                            c = c_dark + (255,)
                        else:
                            # Center ridge shine
                            c = c_core + (255,) if dy < 6 else c_mid + (255,)
                        im.putpixel((fx + x, fy + y), c)
                    elif (dx / (half_w + 2.5)) + (dy / (half_h + 2.5)) <= 1.0:
                        # Soft outer glow aura
                        im.putpixel((fx + x, fy + y), c_glow)

    out_path = os.path.join(PREVIEW_DIR, "A8_shards_spinning_sheet.png")
    im.save(out_path)
    print("Generated A8 Spinning Shards ->", out_path)
    return out_path

# ==========================================================
# 5. A9: DROPPED CRYSTAL ITEM (32x32) & A10: SPARKLE VFX (32x32 x 4)
# ==========================================================
def generate_crystal_and_sparkle():
    # A9: Dropped Crystal with Shadow
    cryst = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # 1. Oval drop shadow at y=23..28, x=8..24
    for y in range(23, 29):
        for x in range(8, 25):
            dx = (x - 16) / 7.0
            dy = (y - 25.5) / 2.5
            if dx*dx + dy*dy <= 1.0:
                alpha = int(140 * (1.0 - (dx*dx + dy*dy)))
                cryst.putpixel((x, y), (10, 6, 12, alpha))
    
    # 2. Resting faceted crystal pointing diagonally up-right
    # Center around (16, 18)
    for y in range(8, 25):
        for x in range(9, 24):
            # Rotated ellipse/diamond
            rx = (x - 16) * 0.8 - (y - 17) * 0.6
            ry = (x - 16) * 0.6 + (y - 17) * 0.8
            if abs(rx) / 5.0 + abs(ry) / 9.0 <= 1.0:
                if rx < 0:
                    c = (255, 120, 25, 255)
                elif rx > 1.0:
                    c = (170, 35, 10, 255)
                else:
                    c = (255, 230, 90, 255)
                cryst.putpixel((x, y), c)

    a9_path = os.path.join(PREVIEW_DIR, "A9_crystal_dropped.png")
    cryst.save(a9_path)
    print("Generated A9 Dropped Crystal ->", a9_path)

    # A10: Sparkle VFX (32x32 x 4 frames = 128 x 32)
    sparkle = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    sparkle_sizes = [3, 7, 11, 4]
    for f in range(4):
        fx = f * 32
        sr = sparkle_sizes[f]
        cx, cy = fx + 16, 16
        
        for y in range(32):
            for x in range(32):
                px = fx + x
                dx = abs(x - 16)
                dy = abs(y - 16)
                
                # Cross rays
                if (dx == 0 and dy <= sr) or (dy == 0 and dx <= sr):
                    intensity = 1.0 - max(dx, dy) / float(sr + 1)
                    c = (255, 255, 200, int(255 * intensity))
                    sparkle.putpixel((px, y), c)
                # Diagonal secondary rays on peak frame
                elif f == 2 and dx == dy and dx <= sr // 2:
                    c = (180, 240, 255, 200)
                    sparkle.putpixel((px, y), c)
                # Core gleam
                elif dx <= 1 and dy <= 1:
                    sparkle.putpixel((px, y), (255, 255, 255, 255))

    a10_path = os.path.join(PREVIEW_DIR, "A10_item_sparkle_sheet.png")
    sparkle.save(a10_path)
    print("Generated A10 Sparkle VFX ->", a10_path)
    return a9_path, a10_path

# ==========================================================
# 6. A12: PIXEL EMOTE REACTION BALLOONS (32x32 x 3 icons)
# ==========================================================
def generate_emote_balloons():
    # 3 icons of 32x32 = 96 x 32
    im = Image.new("RGBA", (96, 32), (0, 0, 0, 0))

    emotes = [
        ("Alert", (255, 100, 20), (255, 220, 40), "!"),
        ("Question", (30, 140, 255), (160, 230, 255), "?"),
        ("Panic", (180, 30, 220), (240, 160, 255), "X"),
    ]

    for idx, (name, bg_col, fg_col, symbol) in enumerate(emotes):
        fx = idx * 32
        # Draw speech bubble with border: rounded rect at x=4..27, y=3..24, tail at (16, 27)
        for y in range(32):
            for x in range(32):
                px = fx + x
                # Balloon body
                in_body = (5 <= x <= 26 and 4 <= y <= 23)
                is_border = (x in [4, 27] and 6 <= y <= 21) or (y in [3, 24] and 6 <= x <= 25) or \
                            (x in [5, 26] and y in [4, 5, 22, 23])
                # Tail
                in_tail = (y >= 24 and y <= 28 and 13 <= x <= 18 and (x - 16) <= (28 - y))
                is_tail_border = (y == 28 and x == 16) or (y in [25, 26, 27] and (x == 13 or x == 18))

                if is_border or is_tail_border:
                    im.putpixel((px, y), (20, 15, 25, 255))
                elif in_body or in_tail:
                    im.putpixel((px, y), bg_col + (255,))

        # Draw glyph in balloon
        # '!' Alert
        if symbol == "!":
            for y in range(8, 17):
                im.putpixel((fx + 15, y), fg_col + (255,))
                im.putpixel((fx + 16, y), fg_col + (255,))
            im.putpixel((fx + 15, 19), fg_col + (255,))
            im.putpixel((fx + 16, 19), fg_col + (255,))
        # '?' Question
        elif symbol == "?":
            q_points = [
                (14, 8), (15, 8), (16, 8), (17, 8),
                (17, 9), (18, 9), (18, 10), (17, 11),
                (16, 12), (16, 13), (16, 15),
                (15, 18), (16, 18)
            ]
            for qx, qy in q_points:
                im.putpixel((fx + qx, qy), fg_col + (255,))
                im.putpixel((fx + qx - 1, qy), (fg_col[0] // 2, fg_col[1] // 2, fg_col[2] // 2, 255))
        # 'X' Panic / Sweat Skull
        elif symbol == "X":
            # Stylized skull / sweat
            for y in range(8, 18):
                for x in range(12, 20):
                    if (x in [13, 14, 17, 18] and y in [10, 11]):
                        continue # eye sockets
                    im.putpixel((fx + x, y), fg_col + (255,))
            # Sweat drop
            im.putpixel((fx + 22, 7), (100, 220, 255, 255))
            im.putpixel((fx + 23, 8), (100, 220, 255, 255))
            im.putpixel((fx + 22, 9), (100, 220, 255, 255))

    out_path = os.path.join(PREVIEW_DIR, "A12_emote_balloons.png")
    im.save(out_path)
    print("Generated A12 Emote Balloons ->", out_path)
    return out_path

# ==========================================================
# 7. B2: CANYON / CLIFF EDGE AUTOTILE (32x32 x 4 tiles = 128x32)
# ==========================================================
def generate_cliff_edge_tileset():
    w, h = 128, 32
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Tile 0: Top Cliff Edge (Ground on top, sheer rock face dropping down)
    for y in range(32):
        for x in range(32):
            if y < 8:
                # Upper ground level
                c = (52, 45, 58, 255) if (x + y) % 5 != 0 else (38, 32, 44, 255)
            elif y in [8, 9]:
                # Overhang lip highlight
                c = (85, 75, 96, 255)
            else:
                # Vertical craggy cliff face
                crag = ((x * 13 + y * 7) % 9) - 4
                shade = max(18, 42 - y + crag)
                c = (shade + 6, shade, shade + 8, 255)
            im.putpixel((x, y), c)

    # Tile 1: Left Cliff Wall (Abyss on left, rock face on right)
    for y in range(32):
        for x in range(32):
            px = 32 + x
            if x < 8:
                c = (0, 0, 0, 0)
            elif x in [8, 9]:
                c = (75, 65, 88, 255)
            else:
                crag = ((x * 7 + y * 11) % 9) - 4
                shade = max(20, 48 - x // 2 + crag)
                c = (shade, shade - 4, shade + 4, 255)
            im.putpixel((px, y), c)

    # Tile 2: Right Cliff Wall (Rock face on left, abyss on right)
    for y in range(32):
        for x in range(32):
            px = 64 + x
            if x >= 24:
                c = (0, 0, 0, 0)
            elif x in [22, 23]:
                c = (75, 65, 88, 255)
            else:
                crag = ((x * 7 + y * 11) % 9) - 4
                shade = max(20, 36 + x // 2 + crag)
                c = (shade, shade - 4, shade + 4, 255)
            im.putpixel((px, y), c)

    # Tile 3: Bottom Cliff Base (Rock meets lava shore / black talus)
    for y in range(32):
        for x in range(32):
            px = 96 + x
            if y < 22:
                crag = ((x * 9 + y * 5) % 9) - 4
                shade = max(16, 32 - y // 2 + crag)
                c = (shade + 4, shade, shade + 4, 255)
            else:
                # Magma shoreline glow
                c = (140, 40, 15, 255) if y >= 29 else (60, 22, 18, 255)
            im.putpixel((px, y), c)

    out_path = os.path.join(PREVIEW_DIR, "B2_cliff_edge_tileset.png")
    im.save(out_path)
    print("Generated B2 Cliff Edge ->", out_path)
    return out_path

# Run all generators
generate_stone_bridge_tileset()
generate_flame_column_sheet()
generate_warning_cracks_sheet()
generate_spinning_shards_sheet()
generate_crystal_and_sparkle()
generate_emote_balloons()
generate_cliff_edge_tileset()
print("All missing procedural pixel assets successfully synthesized!")
