"""
tools/generate_river_variations.py
Generates 2 rich, vibrant River-Integrated map options for Tahap 4:
River Option 1: The Great River Divide (Sungai Lahar Horizontal Membelah + 1 Jembatan Pintas Stokastik & 2 Jembatan Aman)
River Option 2: Twin Lava Chasms (Dua Sungai Lahar Mengapit Lorong Tengah + Danau Lahar Altar)
"""

import os
import math
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

def load_sprite(rel_path, size=None):
    p = os.path.join(BASE_DIR, rel_path)
    if os.path.exists(p):
        img = Image.open(p).convert("RGBA")
        if size:
            img = img.resize(size, Image.Resampling.LANCZOS)
        return img
    return None

# Textures
tex_castle = load_sprite("assets/sprites/map/ground/ground_castle.png", (64, 64))
tex_wild = load_sprite("assets/sprites/map/ground/ground_wilderness.png", (64, 64))
tex_river_h = load_sprite("assets/sprites/map/lava/extracted/river_h.png")
tex_river_v = load_sprite("assets/sprites/map/lava/extracted/river_v.png")
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
tex_lava_pool_m = load_sprite("assets/sprites/map/lava/lava_pool_medium.png")
tex_lava_pool_s = load_sprite("assets/sprites/map/lava/lava_pool_small.png")

# Fonts
try:
    font_title = ImageFont.truetype("arialbd.ttf", 26)
    font_sub = ImageFont.truetype("arialbd.ttf", 18)
    font_box = ImageFont.truetype("arial.ttf", 15)
    font_bold = ImageFont.truetype("arialbd.ttf", 15)
except Exception:
    font_title = ImageFont.load_default()
    font_sub = font_title
    font_box = font_title
    font_bold = font_title

def render_base_world(title_text, subtitle_text):
    img_w = WIDTH * TILE_SIZE
    img_h = HEIGHT * TILE_SIZE
    canvas = Image.new("RGBA", (img_w, img_h), (20, 18, 22, 255))
    draw = ImageDraw.Draw(canvas)

    # 1. Castle Floor (y = 0 .. 16)
    for y in range(0, WALL_Y_TOP * TILE_SIZE, 64):
        for x in range(0, img_w, 64):
            if tex_castle:
                canvas.paste(tex_castle, (x, y))
            else:
                draw.rectangle([x, y, x + 64, y + 64], fill=(28, 24, 32))
    draw.rectangle([0, 0, img_w, WALL_Y_TOP * TILE_SIZE], fill=(0, 0, 10, 35))

    # 2. Wilderness Floor (y = 17 .. 55)
    for y in range(WALL_Y_TOP * TILE_SIZE, img_h, 64):
        for x in range(0, img_w, 64):
            if tex_wild:
                canvas.paste(tex_wild, (x, y))
            else:
                draw.rectangle([x, y, x + 64, y + 64], fill=(36, 30, 30))

    # 3. Castle Red Carpet
    carpet_x1 = 24 * TILE_SIZE
    carpet_x2 = 28 * TILE_SIZE
    carpet_y1 = 4 * TILE_SIZE
    carpet_y2 = WALL_Y_TOP * TILE_SIZE
    draw.rectangle([carpet_x1, carpet_y1, carpet_x2, carpet_y2], fill=(140, 15, 25, 200), outline=(225, 185, 55, 230), width=3)

    # 4. Throne & Demon Boss
    if tex_throne:
        tw = int(tex_throne.width * 0.45)
        th = int(tex_throne.height * 0.45)
        sthrone = tex_throne.resize((tw, th), Image.Resampling.LANCZOS)
        tx = int((CENTER_X + 0.5) * TILE_SIZE - tw / 2)
        ty = int(2.5 * TILE_SIZE - th / 2)
        canvas.paste(sthrone, (tx, ty), sthrone)

    if tex_demon:
        dw = int(tex_demon.width * 0.38)
        dh = int(tex_demon.height * 0.38)
        sdemon = tex_demon.resize((dw, dh), Image.Resampling.LANCZOS)
        canvas.paste(sdemon, (int((CENTER_X + 0.5) * TILE_SIZE - dw / 2), int(4.0 * TILE_SIZE)), sdemon)

    # 5. Castle Pillars
    if tex_wall_pil:
        pw = int(tex_wall_pil.width * 0.28)
        ph = int(tex_wall_pil.height * 0.28)
        spil = tex_wall_pil.resize((pw, ph), Image.Resampling.LANCZOS)
        for py in [6, 10, 14]:
            for px in [10, 16, 35, 41]:
                pos_x = int((px + 0.5) * TILE_SIZE - pw / 2)
                pos_y = int((py + 0.9) * TILE_SIZE - ph / 2)
                canvas.paste(spil, (pos_x, pos_y), spil)

    # 6. Castle Front Wall
    if tex_wall_str:
        ww = int(tex_wall_str.width * 0.25)
        wh = int(tex_wall_str.height * 0.25)
        swall = tex_wall_str.resize((ww, wh), Image.Resampling.LANCZOS)
        for x in range(1, WIDTH - 1, 2):
            if x not in [23, 24, 25, 26, 27]:
                wx = int((x + 0.5) * TILE_SIZE - ww / 2)
                wy = int(WALL_Y_TOP * TILE_SIZE - 4)
                canvas.paste(swall, (wx, wy), swall)

    # 7. Gate
    if tex_gate:
        gw = int(tex_gate.width * 0.38)
        gh = int(tex_gate.height * 0.38)
        sgate = tex_gate.resize((gw, gh), Image.Resampling.LANCZOS)
        canvas.paste(sgate, (int(24 * TILE_SIZE + (4*TILE_SIZE - gw)/2), int(WALL_Y_TOP * TILE_SIZE - 12)), sgate)

    # 8. Guard Knight
    if tex_guard:
        gw_w = int(tex_guard.width * 0.35)
        gw_h = int(tex_guard.height * 0.35)
        sguard = tex_guard.resize((gw_w, gw_h), Image.Resampling.LANCZOS)
        canvas.paste(sguard, (int(26 * TILE_SIZE - gw_w/2), int(20 * TILE_SIZE - 8)), sguard)

    # 9. Outer Borders
    for y in range(HEIGHT):
        draw.rectangle([0, y * TILE_SIZE, TILE_SIZE, (y + 1) * TILE_SIZE], fill=(15, 12, 18))
        draw.rectangle([(WIDTH - 1) * TILE_SIZE, y * TILE_SIZE, WIDTH * TILE_SIZE, (y + 1) * TILE_SIZE], fill=(15, 12, 18))
    for x in range(WIDTH):
        draw.rectangle([x * TILE_SIZE, 0, (x + 1) * TILE_SIZE, TILE_SIZE], fill=(15, 12, 18))
        draw.rectangle([x * TILE_SIZE, (HEIGHT - 1) * TILE_SIZE, (x + 1) * TILE_SIZE, HEIGHT * TILE_SIZE], fill=(15, 12, 18))

    # 10. Southern Dedicated Sanctuary (y = 42 .. 54)
    sanct_center = (CENTER_X * TILE_SIZE + TILE_SIZE//2, 49 * TILE_SIZE + TILE_SIZE//2)
    draw.ellipse([sanct_center[0] - 470, sanct_center[1] - 145, sanct_center[0] + 470, sanct_center[1] + 145],
                 outline=(190, 70, 130, 160), width=3)
    draw.ellipse([sanct_center[0] - 450, sanct_center[1] - 130, sanct_center[0] + 450, sanct_center[1] + 130],
                 outline=(230, 150, 70, 120), width=2)

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
        ax = int(grid_pt[0] * TILE_SIZE + (TILE_SIZE - aw)/2)
        ay = int(grid_pt[1] * TILE_SIZE + (TILE_SIZE - ah)/2 - 8)
        draw.ellipse([ax + 8, ay + ah - 14, ax + aw - 8, ay + ah + 4], fill=(0, 0, 0, 120))
        canvas.paste(saltar, (ax, ay), saltar)

    paste_altar(tex_altar_ignis, altars["Ignis Altar (Flame)"])
    paste_altar(tex_altar_sang, altars["Sanguine Well (Blood)"])
    paste_altar(tex_altar_abyss, altars["Abyssal Fissure (Shadow)"])

    # 11. Carrier Minion Sprite at Simpang
    if tex_carrier:
        fw = tex_carrier.width // 16
        fh = tex_carrier.height
        frame_carrier = tex_carrier.crop((0, 0, fw, fh))
        scarrier = frame_carrier.resize((int(fw * 1.1), int(fh * 1.1)), Image.Resampling.LANCZOS)
        mx = int(25.5 * TILE_SIZE - scarrier.width / 2)
        my = int(42.5 * TILE_SIZE - scarrier.height / 2)
        draw.ellipse([mx + 6, my + scarrier.height - 10, mx + scarrier.width - 6, my + scarrier.height], fill=(0, 0, 0, 160))
        canvas.paste(scarrier, (mx, my), scarrier)

    # 12. Player Hero Sprite (Near Left Road)
    if tex_player:
        frame_player = tex_player.crop((0, 0, 100, 150))
        splayer = frame_player.resize((40, 60), Image.Resampling.LANCZOS)
        canvas.paste(splayer, (int(8.0 * TILE_SIZE - 20), int(24.0 * TILE_SIZE - 30)), splayer)

    # Header Badges
    def draw_badge(x, y, text, bg_col, border_col, txt_col=(255, 255, 255), pad=6):
        bbox = draw.textbbox((0, 0), text, font=font_sub)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.rectangle([x - pad, y - pad, x + tw + pad, y + th + pad], fill=bg_col, outline=border_col, width=2)
        draw.text((x, y), text, font=font_sub, fill=txt_col)

    draw_badge(img_w // 2 - 270, 16, "ZONA 1: GRAND OBSIDIAN CASTLE & TAHTA BOS", (15, 12, 20, 235), (180, 150, 40), (255, 220, 100))
    draw_badge(img_w // 2 - 235, 19 * TILE_SIZE - 28, "GERBANG BENTENG & POS PENJAGA (s4 / GOAL)", (25, 20, 35, 240), (120, 80, 220), (200, 180, 255))
    draw_badge(img_w // 2 - 190, 42 * TILE_SIZE - 12, "SIMPANG LEMBAH (s1: TITIK KEPUTUSAN MDP)", (30, 25, 45, 245), (255, 220, 60), (255, 240, 120))
    draw_badge(img_w // 2 - 270, 52 * TILE_SIZE + 8, "SACRED WELL SANCTUARY (AREA SUMUR & ALTAR ELEMEN - s0)", (20, 15, 30, 245), (255, 90, 140), (255, 180, 210))

    banner_w = 660
    banner_h = 70
    bx = img_w - banner_w - 20
    by = 35
    draw.rectangle([bx, by, bx + banner_w, by + banner_h], fill=(15, 12, 22, 245), outline=(220, 180, 60), width=3)
    draw.text((bx + 18, by + 10), title_text, font=font_title, fill=(255, 220, 80))
    draw.text((bx + 18, by + 42), subtitle_text, font=font_box, fill=(180, 230, 255))

    return canvas, draw

def draw_flowing_lava_rect(canvas, draw, rect):
    # Fiery underglow
    draw.rectangle([rect[0], rect[1], rect[2], rect[3]], fill=(235, 60, 10, 255), outline=(255, 170, 20, 255), width=2)
    # Inner brighter core
    draw.rectangle([rect[0] + 4, rect[1] + 4, rect[2] - 4, rect[3] - 4], fill=(255, 130, 20, 220))
    # Tiled lava texture
    if tex_river_h:
        rw = tex_river_h.width
        rh = tex_river_h.height
        for y in range(int(rect[1]), int(rect[3]), rh):
            for x in range(int(rect[0]), int(rect[2]), rw):
                cw = min(rw, int(rect[2] - x))
                ch = min(rh, int(rect[3] - y))
                crop_part = tex_river_h.crop((0, 0, cw, ch))
                canvas.paste(crop_part, (x, y), crop_part)

def draw_stone_bridge(canvas, draw, bx, by, bw, bh, is_shortcut=False):
    # Solid stone bridge deck
    deck_col = (48, 42, 54, 255)
    border_col = (140, 60, 40, 255) if is_shortcut else (120, 110, 140, 255)
    draw.rectangle([bx, by, bx + bw, by + bh], fill=deck_col, outline=border_col, width=3)

    # Stone pavers lines
    ts = TILE_SIZE
    for dx in range(ts, bw, ts):
        draw.line([(bx + dx, by + 2), (bx + dx, by + bh - 2)], fill=(25, 20, 30, 200), width=2)

    # Parapet railings (Top & Bottom)
    rail_col = (180, 80, 50, 255) if is_shortcut else (160, 150, 180, 255)
    draw.line([(bx, by), (bx + bw, by)], fill=rail_col, width=4)
    draw.line([(bx, by + bh), (bx + bw, by + bh)], fill=rail_col, width=4)

    # Corner stone posts
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

# ==============================================================================
# RIVER OPTION 1: THE GREAT RIVER DIVIDE & THREE STRATEGIC BRIDGES
# ==============================================================================
def generate_river_option_1():
    canvas, draw = render_base_world(
        "OPSI 1: THE GREAT RIVER DIVIDE",
        "Sungai Lahar Mengalir Horizontal Membelah Peta + 1 Jembatan Pintas & 2 Jembatan Aman"
    )
    ts = TILE_SIZE

    # A Grand, Glowing Molten Lava River flows horizontally at y = 29 .. 34 across the entire map!
    # River Rect: x = 1*ts .. 51*ts, y = 29*ts .. 34*ts (Width: 50 tiles, Height: 5 tiles of liquid magma!)
    river_rect = [1 * ts, 29 * ts, (WIDTH - 1) * ts, 35 * ts]
    draw_flowing_lava_rect(canvas, draw, river_rect)

    # 1. THE SINGLE CENTRAL SHORTCUT BRIDGE (x = 24..27, y = 29..34)
    # A stone bridge crossing the lava river, but CURSED with stochastic eruption fissures!
    bridge_center_w = 4 * ts
    bridge_center_h = 6 * ts
    bc_x = 24 * ts
    bc_y = 29 * ts
    draw_stone_bridge(canvas, draw, bc_x, bc_y, bridge_center_w, bridge_center_h, is_shortcut=True)

    # Stochastic Magma Fissures on the Central Bridge (y = 30..33, x = 24..27)
    for fy in range(30, 34):
        for fx in [24, 25, 26, 27]:
            px = fx * ts
            py = fy * ts
            tex_f = tex_fissure_dorm if fy == 30 else (tex_fissure_warn if fy == 31 else tex_fissure_erupt)
            if tex_f:
                canvas.paste(tex_f, (px, py), tex_f)

    # 2. TWO FLANKING SAFE BRIDGES (100% Free of Fissures / Magma Hazards)
    # West Safe Bridge: x = 6..9, y = 29..34
    draw_stone_bridge(canvas, draw, 6 * ts, 29 * ts, 4 * ts, 6 * ts, is_shortcut=False)
    # East Safe Bridge: x = 42..45, y = 29..34
    draw_stone_bridge(canvas, draw, 42 * ts, 29 * ts, 4 * ts, 6 * ts, is_shortcut=False)

    # 3. Clean Shoreline Fortress Walls (y = 28 and y = 35)
    # Solid low walls along the riverbanks to guide traffic strictly through the 3 bridges
    if tex_wall_str:
        sw = tex_wall_str.resize((24, 24), Image.Resampling.LANCZOS)
        for x in range(2, WIDTH - 2, 2):
            if x not in [5, 6, 7, 8, 9, 23, 24, 25, 26, 27, 41, 42, 43, 44, 45]:
                canvas.paste(sw, (x * ts, int(28.5 * ts)), sw)
                canvas.paste(sw, (x * ts, int(35.0 * ts)), sw)

    # Watchtowers on Riverbank bridge entrances
    if tex_wall_twr:
        stwr = tex_wall_twr.resize((28, 48), Image.Resampling.LANCZOS)
        for bx in [5, 10, 23, 28, 41, 46]:
            canvas.paste(stwr, (bx * ts, int(27.8 * ts)), stwr)
            canvas.paste(stwr, (bx * ts, int(34.8 * ts)), stwr)

    # Riverbank Charred Trees & Glowing Crystals
    if tex_tree:
        stree = tex_tree.resize((48, 64), Image.Resampling.LANCZOS)
        canvas.paste(stree, (14 * ts, 26 * ts), stree)
        canvas.paste(stree, (35 * ts, 26 * ts), stree)
        canvas.paste(stree, (14 * ts, 36 * ts), stree)
        canvas.paste(stree, (35 * ts, 36 * ts), stree)

    if tex_crystal:
        scrys = tex_crystal.resize((32, 44), Image.Resampling.LANCZOS)
        canvas.paste(scrys, (18 * ts, 27 * ts), scrys)
        canvas.paste(scrys, (32 * ts, 27 * ts), scrys)

    # Route Overlay Lines:
    # A. Red Shortcut Line: Straight north across the central bridge
    for y in range(21, 42, 2):
        draw.line([(25.5 * ts, y * ts), (25.5 * ts, (y + 1) * ts)], fill=(255, 60, 20, 240), width=5)

    # B. Green Safe Lines: West & East safe bridges
    safe_pts_west = [
        (25.5 * ts, 42.5 * ts),
        (8.0 * ts, 42.5 * ts),
        (8.0 * ts, 20.5 * ts),
        (24.0 * ts, 20.5 * ts)
    ]
    for i in range(len(safe_pts_west) - 1):
        draw.line([safe_pts_west[i], safe_pts_west[i+1]], fill=(35, 230, 120, 220), width=5)

    safe_pts_east = [
        (25.5 * ts, 42.5 * ts),
        (44.0 * ts, 42.5 * ts),
        (44.0 * ts, 20.5 * ts),
        (28.0 * ts, 20.5 * ts)
    ]
    for i in range(len(safe_pts_east) - 1):
        draw.line([safe_pts_east[i], safe_pts_east[i+1]], fill=(35, 230, 120, 220), width=5)

    # Badges
    draw_badge(draw, 21 * ts - 60, 24 * ts, "JALUR PINTAS (1 JEMBATAN TENGAH)", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "LAHAR STOKASTIK MELETUP", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 23 * ts, "JEMBATAN BARAT (AMAN)\n(100% BEBAS HAMBATAN)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 36 * ts, 23 * ts, "JEMBATAN TIMUR (AMAN)\n(100% BEBAS HAMBATAN)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    # Notes Box
    lx, ly = 20, 35
    draw.rectangle([lx, ly, lx + 440, ly + 140], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 15, ly + 10), "FITUR OPSI 1: THE GREAT RIVER DIVIDE", font=font_sub, fill=(140, 190, 255))
    draw.text((lx + 15, ly + 38), "- Sungai lahar besar mengalir horizontal: visual neraka membara & megah!", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 62), "- Penyeberangan super jelas: 1 Jembatan Tengah Pintas vs 2 Jembatan Aman.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 86), "- Area sumur selatan tetap tenang & terpisah sakral di seberang sungai.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 110), "- Mengembalikan elemen sungai tanpa kekacauan labirin masa lalu.", font=font_box, fill=(130, 240, 160))

    out_path = os.path.join(ARTIFACT_DIR, "preview_river_option_1.png")
    canvas.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

# ==============================================================================
# RIVER OPTION 2: TWIN LAVA CHASM (DUA SUNGAI LAHAR VERTIKAL MENGAPIT LORONG TENGAH)
# ==============================================================================
def generate_river_option_2():
    canvas, draw = render_base_world(
        "OPSI 2: TWIN LAVA CHASMS",
        "Dua Sungai Lahar Vertikal Mengalir di Sisi Kiri & Kanan Lorong Tengah"
    )
    ts = TILE_SIZE

    # Two grand glowing molten lava rivers flow vertically at x = 16..20 and x = 31..35 (y = 21..41)
    # West River Chasm:
    river_w_rect = [17 * ts, 21 * ts, 21 * ts, 42 * ts]
    draw_flowing_lava_rect(canvas, draw, river_w_rect)

    # East River Chasm:
    river_e_rect = [31 * ts, 21 * ts, 35 * ts, 42 * ts]
    draw_flowing_lava_rect(canvas, draw, river_e_rect)

    # Center Shortcut Causeway / Island: x = 22..30 (width = 9 tiles)
    # In the middle: Magma fissures (y = 27..35, x = 24..27)
    fiss_box = [24 * ts, 27 * ts, 28 * ts, 36 * ts]
    draw.rectangle(fiss_box, fill=(240, 55, 15, 170), outline=(255, 160, 20, 230), width=3)
    for fy in range(27, 36):
        for fx in [24, 25, 26, 27]:
            tex_f = tex_fissure_dorm if fy in [27, 28] else (tex_fissure_warn if fy in [29, 30] else tex_fissure_erupt)
            if tex_f:
                canvas.paste(tex_f, (fx * ts, fy * ts), tex_f)

    # Outer Highland Riverbanks (Safe Roads) at West (x = 3..15) and East (x = 36..48)
    # Shoreline stone borders
    if tex_rock_l:
        srock = tex_rock_l.resize((32, 32), Image.Resampling.LANCZOS)
        for y in range(21, 42, 2):
            canvas.paste(srock, (int(16.2 * ts), y * ts), srock)
            canvas.paste(srock, (int(21.2 * ts), y * ts), srock)
            canvas.paste(srock, (int(30.2 * ts), y * ts), srock)
            canvas.paste(srock, (int(35.2 * ts), y * ts), srock)

    # Lava waterfalls or pool accents in southern sanctuary shores
    if tex_lava_pool_m:
        mlava = tex_lava_pool_m.resize((64, 48), Image.Resampling.LANCZOS)
        canvas.paste(mlava, (18 * ts, 43 * ts), mlava)
        canvas.paste(mlava, (30 * ts, 43 * ts), mlava)

    # Trees and crystals on the wide outer highland banks
    if tex_tree:
        stree = tex_tree.resize((48, 64), Image.Resampling.LANCZOS)
        canvas.paste(stree, (8 * ts, 26 * ts), stree)
        canvas.paste(stree, (10 * ts, 35 * ts), stree)
        canvas.paste(stree, (42 * ts, 26 * ts), stree)
        canvas.paste(stree, (40 * ts, 35 * ts), stree)

    if tex_crystal:
        scrys = tex_crystal.resize((32, 44), Image.Resampling.LANCZOS)
        canvas.paste(scrys, (5 * ts, 31 * ts), scrys)
        canvas.paste(scrys, (45 * ts, 31 * ts), scrys)

    # Route Overlay Lines
    for y in range(21, 42, 2):
        draw.line([(25.5 * ts, y * ts), (25.5 * ts, (y + 1) * ts)], fill=(255, 60, 20, 240), width=5)

    safe_pts_west = [
        (25.5 * ts, 42.5 * ts),
        (8.0 * ts, 42.5 * ts),
        (8.0 * ts, 20.5 * ts),
        (24.0 * ts, 20.5 * ts)
    ]
    for i in range(len(safe_pts_west) - 1):
        draw.line([safe_pts_west[i], safe_pts_west[i+1]], fill=(35, 230, 120, 220), width=5)

    safe_pts_east = [
        (25.5 * ts, 42.5 * ts),
        (44.0 * ts, 42.5 * ts),
        (44.0 * ts, 20.5 * ts),
        (28.0 * ts, 20.5 * ts)
    ]
    for i in range(len(safe_pts_east) - 1):
        draw.line([safe_pts_east[i], safe_pts_east[i+1]], fill=(35, 230, 120, 220), width=5)

    # Badges
    draw_badge(draw, 21 * ts - 60, 23 * ts, "CAUSEWAY JALUR PINTAS TENGAH", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "PERANGKAP LAHAR MELETUP", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 30 * ts, "DATARAN TEPI LAHAR BARAT\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 35 * ts, 30 * ts, "DATARAN TEPI LAHAR TIMUR\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    # Notes Box
    lx, ly = 20, 35
    draw.rectangle([lx, ly, lx + 440, ly + 140], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 15, ly + 10), "FITUR OPSI 2: TWIN LAVA CHASMS", font=font_sub, fill=(140, 190, 255))
    draw.text((lx + 15, ly + 38), "- Dua sungai lahar vertikal membelah tengah dan sayap luar secara dramatis.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 62), "- Jalur pintas tengah adalah lidah daratan tinggi (causeway) diapit lahar.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 86), "- Sayap luar adalah dataran tinggi lapang di seberang sungai lahar.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 110), "- Warna pijar lahar membuat peta sangat hidup, tidak sepi, dan tetap lapang.", font=font_box, fill=(130, 240, 160))

    out_path = os.path.join(ARTIFACT_DIR, "preview_river_option_2.png")
    canvas.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

if __name__ == "__main__":
    generate_river_option_1()
    generate_river_option_2()
