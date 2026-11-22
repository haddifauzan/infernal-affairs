"""
tools/generate_2d_map_tahap4.py
Generates the definitive, highly detailed 2D Map Visualization for Tahap 4 (Infernal Affairs)
based on Opsi 1 (Sungai Horizontal & 3 Jembatan Rapi) with user enhancements:
- Clean, tidy, large flowing lava river asset (river_grand_horizontal.png, 192 px tall, seamless horizontally, zero rock stripes in river).
- Distinct paved roadways: Sturdy slate stone paver highway for Jalur Utama vs Glowing cracked volcanic basalt for Jalur Pintas.
- Rich environmental obstacles: Charred trees, large rock formations, crystal spires, decorative lava pools.
- Dedicated Southern Sanctuary for elemental altars.
- 100% compliant with 09 Decision under uncertainty (MDP & Bayesian Updating).
"""

import os
import math
from collections import deque
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT_DIR = "C:/Users/MyBook Hype AMD/.gemini/antigravity/brain/07868943-55b7-4b4c-ab20-c1b7547b1bbf"

WIDTH = 52
HEIGHT = 56
TILE_SIZE = 32

CENTER_X = 25
WALL_Y_TOP = 17
GATE_Y = 18
COURTYARD_Y = 20

TileType = {
    "GROUND": 0,
    "OBSTACLE": 1,
    "LAVA": 2,
    "FISSURE": 3
}

def load_sprite(rel_path, size=None):
    p = os.path.join(BASE_DIR, rel_path)
    if os.path.exists(p):
        img = Image.open(p).convert("RGBA")
        if size:
            img = img.resize(size, Image.Resampling.LANCZOS)
        return img
    return None

# Load sprites
tex_castle = load_sprite("assets/sprites/map/ground/ground_castle.png", (64, 64))
tex_wild = load_sprite("assets/sprites/map/ground/ground_wilderness.png", (64, 64))
tex_river_grand = load_sprite("assets/sprites/map/lava/extracted/river_grand_horizontal.png")
tex_river_h = load_sprite("assets/sprites/map/lava/extracted/river_h.png")
tex_wall_str = load_sprite("assets/sprites/map/obstacles/wall_straight_large.png")
tex_wall_crn = load_sprite("assets/sprites/map/obstacles/wall_corner_large.png")
tex_wall_twr = load_sprite("assets/sprites/map/obstacles/wall_tower_large.png")
tex_wall_pil = load_sprite("assets/sprites/map/obstacles/wall_pillar_large.png")
tex_gate = load_sprite("assets/sprites/map/obstacles/gate_hell_closed.png")
tex_throne = load_sprite("assets/sprites/map/obstacles/throne_boss.png")
tex_altar_ignis = load_sprite("assets/sprites/map/obstacles/altar_ignis.png")
tex_altar_sang = load_sprite("assets/sprites/map/obstacles/altar_sanguine.png")
tex_altar_abyss = load_sprite("assets/sprites/map/obstacles/altar_abyssal.png")
tex_fissure_erupt = load_sprite("assets/sprites/map/hazards/fissure_eruption.png", (TILE_SIZE, TILE_SIZE))
tex_fissure_warn = load_sprite("assets/sprites/map/hazards/fissure_warning.png", (TILE_SIZE, TILE_SIZE))
tex_fissure_dorm = load_sprite("assets/sprites/map/hazards/fissure_dormant.png", (TILE_SIZE, TILE_SIZE))
tex_carrier = load_sprite("assets/sprites/characters/minion/minion_carrier.png")
tex_player = load_sprite("assets/sprites/characters/player/player_idle.png")
tex_guard = load_sprite("assets/sprites/characters/guard/guard_knight.png")
tex_demon = load_sprite("assets/sprites/characters/demon/demon_boss.png")
tex_rock_l = load_sprite("assets/sprites/map/obstacles/rock_large.png")
tex_rock_m = load_sprite("assets/sprites/map/obstacles/rock_medium.png")
tex_tree = load_sprite("assets/sprites/map/obstacles/tree_large.png")
tex_crystal = load_sprite("assets/sprites/map/obstacles/crystal_large.png")
tex_crystal_s = load_sprite("assets/sprites/map/obstacles/crystal_small.png")
tex_lava_pool_m = load_sprite("assets/sprites/map/lava/lava_pool_medium.png")
tex_lava_pool_s = load_sprite("assets/sprites/map/lava/lava_pool_small.png")

# Fonts
try:
    font_title = ImageFont.truetype("arialbd.ttf", 26)
    font_sub = ImageFont.truetype("arialbd.ttf", 18)
    font_box = ImageFont.truetype("arial.ttf", 15)
    font_bold = ImageFont.truetype("arialbd.ttf", 15)
    font_small = ImageFont.truetype("arial.ttf", 13)
except Exception:
    font_title = ImageFont.load_default()
    font_sub = font_title
    font_box = font_title
    font_bold = font_title
    font_small = font_title

def draw_flowing_lava_rect(canvas, draw, rect):
    rx1, ry1, rx2, ry2 = rect
    rh = int(ry2 - ry1)
    rw = int(rx2 - rx1)

    # Fiery underglow
    draw.rectangle([rx1, ry1, rx2, ry2], fill=(245, 70, 10, 255), outline=(255, 170, 20, 255), width=2)
    draw.rectangle([rx1 + 3, ry1 + 3, rx2 - 3, ry2 - 3], fill=(255, 120, 15, 230))

    # Tiled seamless grand horizontal river texture (zero internal rock stripes!)
    river_tex = tex_river_grand if tex_river_grand else tex_river_h
    if river_tex:
        tw = river_tex.width
        th = river_tex.height
        for x in range(int(rx1), int(rx2), tw):
            cw = min(tw, int(rx2 - x))
            crop_part = river_tex.crop((0, 0, cw, min(th, rh)))
            canvas.paste(crop_part, (x, int(ry1)), crop_part)

def draw_stone_bridge(canvas, draw, bx, by, bw, bh, is_shortcut=False):
    ts = TILE_SIZE
    if is_shortcut:
        # Volcanic Iron-Grated Causeway for Shortcut (Scorched Basalt & Iron Beams)
        draw.rectangle([bx, by, bx + bw, by + bh], fill=(32, 18, 20, 255), outline=(230, 75, 25, 255), width=3)
        draw.rectangle([bx + 3, by, bx + bw - 3, by + bh], fill=(42, 22, 25, 255))
        # Iron reinforcement cross-beams
        draw.line([(bx, by), (bx + bw, by)], fill=(230, 85, 35, 255), width=5)
        draw.line([(bx, by + bh), (bx + bw, by + bh)], fill=(230, 85, 35, 255), width=5)
        draw.line([(bx, by), (bx, by + bh)], fill=(200, 60, 20, 255), width=4)
        draw.line([(bx + bw, by), (bx + bw, by + bh)], fill=(200, 60, 20, 255), width=4)
    else:
        # Sturdy Ancient Stone Viaduct for Safe Road
        draw.rectangle([bx, by, bx + bw, by + bh], fill=(44, 40, 52, 255), outline=(100, 95, 120, 255), width=3)
        draw.rectangle([bx + 3, by, bx + bw - 3, by + bh], fill=(54, 50, 64, 255))
        for dx in range(ts, bw, ts):
            draw.line([(bx + dx, by + 2), (bx + dx, by + bh - 2)], fill=(24, 20, 30, 200), width=2)
        for dy in range(ts, bh, ts):
            draw.line([(bx + 2, by + dy), (bx + bw - 2, by + dy)], fill=(32, 28, 40, 180), width=1)
        draw.line([(bx, by), (bx + bw, by)], fill=(150, 145, 170, 255), width=4)
        draw.line([(bx, by + bh), (bx + bw, by + bh)], fill=(150, 145, 170, 255), width=4)
        draw.line([(bx, by), (bx, by + bh)], fill=(130, 125, 150, 255), width=4)
        draw.line([(bx + bw, by), (bx + bw, by + bh)], fill=(130, 125, 150, 255), width=4)
        if tex_rock_m:
            sp = tex_rock_m.resize((16, 16), Image.Resampling.LANCZOS)
            canvas.paste(sp, (bx - 4, by - 6), sp)
            canvas.paste(sp, (bx + bw - 12, by - 6), sp)
            canvas.paste(sp, (bx - 4, by + bh - 8), sp)
            canvas.paste(sp, (bx + bw - 12, by + bh - 8), sp)

def draw_badge(draw, x, y, text, bg_col, border_col, txt_col=(255, 255, 255), pad=6):
    bbox = draw.textbbox((0, 0), text, font=font_sub)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.rectangle([x - pad, y - pad, x + tw + pad, y + th + pad], fill=bg_col, outline=border_col, width=2)
    draw.text((x, y), text, font=font_sub, fill=txt_col)

def generate_final_map():
    img_w = WIDTH * TILE_SIZE
    img_h = HEIGHT * TILE_SIZE
    canvas = Image.new("RGBA", (img_w, img_h), (20, 18, 22, 255))
    draw = ImageDraw.Draw(canvas)
    ts = TILE_SIZE

    # 1. Base Castle Floor (y = 0 .. 16)
    for y in range(0, WALL_Y_TOP * ts, 64):
        for x in range(0, img_w, 64):
            if tex_castle: canvas.paste(tex_castle, (x, y))
            else: draw.rectangle([x, y, x + 64, y + 64], fill=(28, 24, 32))
    draw.rectangle([0, 0, img_w, WALL_Y_TOP * ts], fill=(0, 0, 10, 35))

    # 2. Base Wilderness Floor (y = 17 .. 55)
    for y in range(WALL_Y_TOP * ts, img_h, 64):
        for x in range(0, img_w, 64):
            if tex_wild: canvas.paste(tex_wild, (x, y))
            else: draw.rectangle([x, y, x + 64, y + 64], fill=(36, 30, 30))

    # 3. Castle Red Carpet & Throne Room
    carpet_x1 = 24 * ts
    carpet_x2 = 28 * ts
    carpet_y1 = 4 * ts
    carpet_y2 = WALL_Y_TOP * ts
    draw.rectangle([carpet_x1, carpet_y1, carpet_x2, carpet_y2], fill=(140, 15, 25, 200), outline=(225, 185, 55, 230), width=3)

    if tex_throne:
        tw = int(tex_throne.width * 0.45)
        th = int(tex_throne.height * 0.45)
        sthrone = tex_throne.resize((tw, th), Image.Resampling.LANCZOS)
        canvas.paste(sthrone, (int((CENTER_X + 0.5) * ts - tw / 2), int(2.5 * ts - th / 2)), sthrone)

    if tex_demon:
        dw = int(tex_demon.width * 0.38)
        dh = int(tex_demon.height * 0.38)
        sdemon = tex_demon.resize((dw, dh), Image.Resampling.LANCZOS)
        canvas.paste(sdemon, (int((CENTER_X + 0.5) * ts - dw / 2), int(4.0 * ts)), sdemon)

    # Castle Pillars
    if tex_wall_pil:
        spil = tex_wall_pil.resize((int(tex_wall_pil.width * 0.28), int(tex_wall_pil.height * 0.28)), Image.Resampling.LANCZOS)
        for py in [6, 10, 14]:
            for px in [10, 16, 35, 41]:
                canvas.paste(spil, (int((px + 0.5) * ts - spil.width / 2), int((py + 0.9) * ts - spil.height / 2)), spil)

    # Castle Front Wall
    if tex_wall_str:
        swall = tex_wall_str.resize((int(tex_wall_str.width * 0.25), int(tex_wall_str.height * 0.25)), Image.Resampling.LANCZOS)
        for x in range(1, WIDTH - 1, 2):
            if x not in [23, 24, 25, 26, 27]:
                canvas.paste(swall, (int((x + 0.5) * ts - swall.width / 2), int(WALL_Y_TOP * ts - 4)), swall)

    # Gate & Guard
    if tex_gate:
        sgate = tex_gate.resize((int(tex_gate.width * 0.38), int(tex_gate.height * 0.38)), Image.Resampling.LANCZOS)
        canvas.paste(sgate, (int(24 * ts + (4 * ts - sgate.width) / 2), int(WALL_Y_TOP * ts - 12)), sgate)

    if tex_guard:
        sguard = tex_guard.resize((int(tex_guard.width * 0.35), int(tex_guard.height * 0.35)), Image.Resampling.LANCZOS)
        canvas.paste(sguard, (int(26 * ts - sguard.width / 2), int(20 * ts - 8)), sguard)

    # --------------------------------------------------------------------------
    # 4. ROADWAYS & PAVEMENT ("KAYA ASPAL ATAU JEMBATAN KE JALAN TERSEBUT")
    # --------------------------------------------------------------------------
    # A. JALUR UTAMA (MAIN SAFE ROAD): Sturdy Slate Cobblestone Highway
    safe_road_fill = (45, 40, 52, 215)
    safe_kerb_col = (100, 90, 120, 230)

    # West Paved Highway:
    draw.rectangle([6 * ts, 20 * ts, 10 * ts, 43 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=2)
    draw.rectangle([10 * ts, 20 * ts, 24 * ts, 22 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=1)
    draw.rectangle([6 * ts, 41 * ts, 25 * ts, 43 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=1)

    # East Paved Highway:
    draw.rectangle([42 * ts, 20 * ts, 46 * ts, 43 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=2)
    draw.rectangle([28 * ts, 20 * ts, 42 * ts, 22 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=1)
    draw.rectangle([25 * ts, 41 * ts, 46 * ts, 43 * ts], fill=safe_road_fill, outline=safe_kerb_col, width=1)

    # Decorative paver tiles on safe road
    for py in range(21, 42, 3):
        draw.line([(6 * ts + 2, py * ts), (10 * ts - 2, py * ts)], fill=(28, 24, 34, 200), width=1)
        draw.line([(42 * ts + 2, py * ts), (46 * ts - 2, py * ts)], fill=(28, 24, 34, 200), width=1)

    # B. JALUR PINTAS (SHORTCUT ROAD): Scorched Volcanic Basalt Highway (DIBUAT LEBIH BEDA & BERBAHAYA!)
    sc_road_fill = (34, 16, 18, 235)
    sc_kerb_col = (230, 70, 20, 245)
    draw.rectangle([24 * ts, 21 * ts, 28 * ts, 42 * ts], fill=sc_road_fill, outline=sc_kerb_col, width=2)

    # --------------------------------------------------------------------------
    # 5. THE GREAT MOLTEN LAVA RIVER (y = 29 .. 34)
    # --------------------------------------------------------------------------
    river_rect = [1 * ts, 29 * ts, (WIDTH - 1) * ts, 35 * ts]
    draw_flowing_lava_rect(canvas, draw, river_rect)

    # Three Strategic Bridges:
    # West Safe Bridge (x = 6..9, y = 29..34)
    draw_stone_bridge(canvas, draw, 6 * ts, 29 * ts, 4 * ts, 6 * ts, is_shortcut=False)
    # East Safe Bridge (x = 42..45, y = 29..34)
    draw_stone_bridge(canvas, draw, 42 * ts, 29 * ts, 4 * ts, 6 * ts, is_shortcut=False)
    # Central Shortcut Bridge (x = 24..27, y = 29..34) - Scorched & Glowing!
    draw_stone_bridge(canvas, draw, 24 * ts, 29 * ts, 4 * ts, 6 * ts, is_shortcut=True)

    # Magma Hazard Fissures on the Central Shortcut Bridge (y = 30..33, x = 24..27)
    for fy in range(30, 34):
        for fx in [24, 25, 26, 27]:
            px = fx * ts
            py = fy * ts
            tex_f = tex_fissure_dorm if fy == 30 else (tex_fissure_warn if fy == 31 else tex_fissure_erupt)
            if tex_f: canvas.paste(tex_f, (px, py), tex_f)

    # --------------------------------------------------------------------------
    # 6. RICH WILDERNESS OBSTACLES (TREES, ROCKS, CRYSTALS, LAVA POOLS)
    # --------------------------------------------------------------------------
    # A. Riverbank Watchtowers & Fortress Battlements
    if tex_wall_twr:
        stwr = tex_wall_twr.resize((28, 48), Image.Resampling.LANCZOS)
        for bx in [5, 10, 23, 28, 41, 46]:
            canvas.paste(stwr, (bx * ts, int(27.8 * ts)), stwr)
            canvas.paste(stwr, (bx * ts, int(34.8 * ts)), stwr)

    if tex_wall_str:
        sw = tex_wall_str.resize((24, 24), Image.Resampling.LANCZOS)
        for x in [3, 4, 11, 12, 21, 22, 29, 30, 39, 40, 47, 48]:
            canvas.paste(sw, (x * ts, int(28.5 * ts)), sw)
            canvas.paste(sw, (x * ts, int(35.0 * ts)), sw)

    # B. Imposing Charred Trees in Wilderness Wings
    if tex_tree:
        stree = tex_tree.resize((50, 68), Image.Resampling.LANCZOS)
        tree_north = [(3, 24), (12, 25), (15, 22), (36, 22), (39, 25), (48, 24)]
        for tx, ty in tree_north:
            canvas.paste(stree, (tx * ts, ty * ts), stree)
        tree_south = [(3, 37), (13, 38), (38, 38), (48, 37)]
        for tx, ty in tree_south:
            canvas.paste(stree, (tx * ts, ty * ts), stree)

    # C. Ancient Rock Formations (Boulders)
    if tex_rock_l:
        srock_l = tex_rock_l.resize((40, 40), Image.Resampling.LANCZOS)
        rock_pts = [(18, 24), (32, 24), (18, 38), (32, 38), (2, 44), (49, 44)]
        for rx, ry in rock_pts:
            canvas.paste(srock_l, (rx * ts, ry * ts), srock_l)

    if tex_rock_m:
        srock_m = tex_rock_m.resize((26, 26), Image.Resampling.LANCZOS)
        mrock_pts = [(14, 27), (37, 27), (14, 36), (37, 36), (3, 30), (48, 30)]
        for rx, ry in mrock_pts:
            canvas.paste(srock_m, (rx * ts, ry * ts), srock_m)

    # D. Glowing Elemental Crystals (Spreading Volcanic Ambience)
    if tex_crystal:
        scrys = tex_crystal.resize((34, 46), Image.Resampling.LANCZOS)
        crys_pts = [(16, 26), (35, 26), (16, 37), (35, 37), (4, 48), (47, 48)]
        for cx, cy in crys_pts:
            canvas.paste(scrys, (cx * ts, cy * ts), scrys)

    if tex_crystal_s:
        scrys_s = tex_crystal_s.resize((20, 28), Image.Resampling.LANCZOS)
        for cx, cy in [(20, 26), (31, 26), (20, 37), (31, 37)]:
            canvas.paste(scrys_s, (cx * ts, cy * ts), scrys_s)

    # E. Decorative Natural Lava Pools in Outer Corners
    if tex_lava_pool_m:
        mlava = tex_lava_pool_m.resize((64, 48), Image.Resampling.LANCZOS)
        canvas.paste(mlava, (2 * ts, 21 * ts), mlava)
        canvas.paste(mlava, (48 * ts - 24, 21 * ts), mlava)

    if tex_lava_pool_s:
        slava = tex_lava_pool_s.resize((48, 36), Image.Resampling.LANCZOS)
        canvas.paste(slava, (2 * ts + 10, 42 * ts), slava)
        canvas.paste(slava, (48 * ts - 20, 42 * ts), slava)

    # --------------------------------------------------------------------------
    # 7. SOUTHERN SACRED WELL SANCTUARY (y = 42 .. 54)
    # --------------------------------------------------------------------------
    sanct_center = (CENTER_X * ts + ts // 2, 49 * ts + ts // 2)
    draw.ellipse([sanct_center[0] - 470, sanct_center[1] - 145, sanct_center[0] + 470, sanct_center[1] + 145],
                 outline=(200, 70, 130, 170), width=3)
    draw.ellipse([sanct_center[0] - 450, sanct_center[1] - 130, sanct_center[0] + 450, sanct_center[1] + 130],
                 outline=(240, 150, 70, 130), width=2)

    altars = {
        "Ignis Altar (Flame)": (17, 49),
        "Sanguine Well (Blood)": (25, 50),
        "Abyssal Fissure (Shadow)": (33, 49)
    }
    def paste_altar(tex, grid_pt):
        if not tex: return
        aw = int(tex.width * 0.48)
        ah = int(tex.height * 0.48)
        saltar = tex.resize((aw, ah), Image.Resampling.LANCZOS)
        ax = int(grid_pt[0] * ts + (ts - aw) / 2)
        ay = int(grid_pt[1] * ts + (ts - ah) / 2 - 8)
        draw.ellipse([ax + 8, ay + ah - 14, ax + aw - 8, ay + ah + 4], fill=(0, 0, 0, 120))
        canvas.paste(saltar, (ax, ay), saltar)

    paste_altar(tex_altar_ignis, altars["Ignis Altar (Flame)"])
    paste_altar(tex_altar_sang, altars["Sanguine Well (Blood)"])
    paste_altar(tex_altar_abyss, altars["Abyssal Fissure (Shadow)"])

    # Carrier Minion Sprite at Simpang
    if tex_carrier:
        fw = tex_carrier.width // 16
        fh = tex_carrier.height
        frame_carrier = tex_carrier.crop((0, 0, fw, fh))
        scarrier = frame_carrier.resize((int(fw * 1.1), int(fh * 1.1)), Image.Resampling.LANCZOS)
        mx = int(25.5 * ts - scarrier.width / 2)
        my = int(42.5 * ts - scarrier.height / 2)
        draw.ellipse([mx + 6, my + scarrier.height - 10, mx + scarrier.width - 6, my + scarrier.height], fill=(0, 0, 0, 160))
        canvas.paste(scarrier, (mx, my), scarrier)

    # Player Hero Sprite (Near Safe Road Interception Point)
    if tex_player:
        frame_player = tex_player.crop((0, 0, 100, 150))
        splayer = frame_player.resize((40, 60), Image.Resampling.LANCZOS)
        canvas.paste(splayer, (int(8.0 * ts - 20), int(24.0 * ts - 30)), splayer)

    # --------------------------------------------------------------------------
    # 8. ROUTE OVERLAY LINES & CALLOUT BADGES
    # --------------------------------------------------------------------------
    # Red Dashed Line straight through Shortcut
    for y in range(21, 42, 2):
        draw.line([(26.0 * ts, y * ts), (26.0 * ts, (y + 1) * ts)], fill=(255, 60, 20, 255), width=5)

    # Green Solid Line for Safe Roads
    safe_pts_west = [
        (25.5 * ts, 42.0 * ts),
        (8.0 * ts, 42.0 * ts),
        (8.0 * ts, 21.0 * ts),
        (24.0 * ts, 21.0 * ts)
    ]
    for i in range(len(safe_pts_west) - 1):
        draw.line([safe_pts_west[i], safe_pts_west[i+1]], fill=(35, 230, 120, 230), width=5)

    safe_pts_east = [
        (25.5 * ts, 42.0 * ts),
        (44.0 * ts, 42.0 * ts),
        (44.0 * ts, 21.0 * ts),
        (28.0 * ts, 21.0 * ts)
    ]
    for i in range(len(safe_pts_east) - 1):
        draw.line([safe_pts_east[i], safe_pts_east[i+1]], fill=(35, 230, 120, 230), width=5)

    # Outer perimeter walls
    for y in range(HEIGHT):
        draw.rectangle([0, y * ts, ts, (y + 1) * ts], fill=(15, 12, 18))
        draw.rectangle([(WIDTH - 1) * ts, y * ts, WIDTH * ts, (y + 1) * ts], fill=(15, 12, 18))
    for x in range(WIDTH):
        draw.rectangle([x * ts, 0, (x + 1) * ts, ts], fill=(15, 12, 18))
        draw.rectangle([x * ts, (HEIGHT - 1) * ts, (x + 1) * ts, HEIGHT * ts], fill=(15, 12, 18))

    # Zone Badges
    draw_badge(draw, img_w // 2 - 270, 16, "ZONA 1: GRAND OBSIDIAN CASTLE & TAHTA BOS", (15, 12, 20, 235), (180, 150, 40), (255, 220, 100))
    draw_badge(draw, img_w // 2 - 235, 19 * ts - 28, "GERBANG BENTENG & POS PENJAGA (s4 / GOAL)", (25, 20, 35, 240), (120, 80, 220), (200, 180, 255))
    draw_badge(draw, img_w // 2 - 190, 42 * ts - 12, "SIMPANG LEMBAH (s1: TITIK KEPUTUSAN MDP)", (30, 25, 45, 245), (255, 220, 60), (255, 240, 120))
    draw_badge(draw, img_w // 2 - 270, 52 * ts + 8, "SACRED WELL SANCTUARY (AREA SUMUR & ALTAR ELEMEN - s0)", (20, 15, 30, 245), (255, 90, 140), (255, 180, 210))

    # Path Badges
    draw_badge(draw, 21 * ts - 60, 24 * ts, "JALUR PINTAS (JALAN BASALT MERAH BERBAHAYA)", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "LAHAR STOKASTIK MELETUP", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 24 * ts, "JALUR UTAMA BARAT (ASPAL BATU AMAN)\n(100% BEBAS HAMBATAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 34 * ts, 24 * ts, "JALUR UTAMA TIMUR (ASPAL BATU AMAN)\n(100% BEBAS HAMBATAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    # Altar Badges
    draw_badge(draw, altars["Ignis Altar (Flame)"][0] * ts - 35, altars["Ignis Altar (Flame)"][1] * ts + 32, "Ignis Altar (Api)", (30, 15, 10, 220), (255, 100, 20), (255, 180, 100))
    draw_badge(draw, altars["Sanguine Well (Blood)"][0] * ts - 45, altars["Sanguine Well (Blood)"][1] * ts + 32, "Sanguine Well (Darah)", (35, 10, 20, 220), (255, 40, 80), (255, 150, 180))
    draw_badge(draw, altars["Abyssal Fissure (Shadow)"][0] * ts - 60, altars["Abyssal Fissure (Shadow)"][1] * ts + 32, "Abyssal Fissure (Bayangan)", (25, 15, 35, 220), (160, 60, 255), (200, 150, 255))

    # Mathematics & Design Callout (Top Right)
    box_w = 560
    box_h = 245
    bx = img_w - box_w - 20
    by = 35
    draw.rectangle([bx, by, bx + box_w, by + box_h], fill=(15, 12, 22, 245), outline=(220, 180, 60), width=3)
    draw.text((bx + 18, by + 12), "DESAIN FINAL PETA 2D TAHAP 4 (MDP & SUNGAI LAHAR)", font=font_sub, fill=(255, 220, 80))
    draw.line([(bx + 18, by + 36), (bx + box_w - 18, by + 36)], fill=(120, 100, 40), width=1)

    info_lines = [
        ("Sungai Lahar Menyala:", "Mengalir rapi horizontal di y=29..34 (bebas garis pembatas tengah)"),
        ("Jalur Utama (Aspal Batu):", "Ubin abu-abu kokoh, 100% bebas bahaya, jarak ~52 langkah"),
        ("Jalur Pintas (Basalt Merah):", "Jalan batu lahar berurat api & 1 jembatan potong, ~22 langkah"),
        ("Obstacle Alami:", "Pohon hangus, boulder batu, kristal bercahaya & kolam lahar"),
        ("Area Sumur Selatan:", "Kuil terpusat khusus untuk 3 altar tanpa labirin membingungkan"),
        ("Logika Keputusan MDP:", "Normal: a* = PINTAS (Q=7.00) | Asap: a* = RAYA (Q=6.00 > -5.00)"),
        ("Keunggulan Peta:", "Lapang, kaya aset, tidak monoton, dan alur sangat intuitif!")
    ]
    cur_y = by + 46
    for label, val in info_lines:
        draw.text((bx + 18, cur_y), label, font=font_bold, fill=(210, 210, 210))
        draw.text((bx + 225, cur_y), val, font=font_box, fill=(130, 240, 160) if "a*" in val or "Aspal" in label or "Basalt" in val else (255, 235, 140))
        cur_y += 26

    # Legend Box (Top Left)
    leg_w = 420
    leg_h = 230
    lx = 20
    ly = 35
    draw.rectangle([lx, ly, lx + leg_w, ly + leg_h], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 18, ly + 12), "LEGENDA PETA 2D TAHAP 4 (FINAL)", font=font_sub, fill=(140, 190, 255))
    draw.line([(lx + 18, ly + leg_w - 18 if False else ly + 36), (lx + leg_w - 18, ly + 36)], fill=(50, 70, 120), width=1)

    legend_items = [
        ((255, 60, 20), "Jalur Pintas (Basalt Berapi - Letupan Lahar)"),
        ((35, 230, 120), "Jalur Utama (Aspal Batu Ubin - 100% Aman)"),
        ((235, 60, 10), "Sungai Lahar Cair (Molten Lava River)"),
        ((150, 145, 170), "Jembatan Batu Viaduct (Sayap Barat & Timur)"),
        ((220, 80, 40), "Jembatan Besi Cursed (Tengah - Berisiko)"),
        ((255, 90, 140), "Sacred Well Sanctuary (Area Khusus Sumur)")
    ]
    cur_ly = ly + 46
    for col, text in legend_items:
        draw.rectangle([lx + 18, cur_ly + 3, lx + 38, cur_ly + 17], fill=col, outline=(255, 255, 255, 200), width=1)
        draw.text((lx + 48, cur_ly), text, font=font_box, fill=(235, 235, 245))
        cur_ly += 28

    targets = [
        os.path.join(BASE_DIR, "laporan_assets", "peta_2d_tahap_4_mdp.png"),
        os.path.join(ARTIFACT_DIR, "peta_2d_tahap_4_mdp.png"),
        os.path.join("d:/Tugas/KULIAH/SEMESTER 3/Kecerdasan Buatan/Tugas/tubes/hell-pathfinder/laporan_assets", "peta_2d_tahap_4_mdp.png")
    ]
    for target_path in targets:
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        canvas.save(target_path, "PNG")
        print(f"[OK] Saved Final Map to: {target_path}")

if __name__ == "__main__":
    generate_final_map()
