"""
tools/generate_map_variations.py
Generates 3 distinct, highly detailed map architecture options for Tahap 4:
Option A: Infernal Ramparts (Dinding Benteng Tipis 2-Petak, Plaza Runtuhan & Jalur Paving)
Option B: Volcanic Caldera (Tebing Basalt Berkelok Alami, Celah Lahar & Pohon Hangus)
Option C: Obsidian Colonnade (Barisan Pilar Megah, Jalur Upacara & Balustrade Katedral)
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
SANCTUARY_Y_START = 41

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

def render_base_scene(title_text, subtitle_text):
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

    # 13. Titles & Header Badge
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

    # Top Option Banner
    banner_w = 640
    banner_h = 70
    bx = img_w - banner_w - 20
    by = 35
    draw.rectangle([bx, by, bx + banner_w, by + banner_h], fill=(15, 12, 22, 245), outline=(220, 180, 60), width=3)
    draw.text((bx + 18, by + 10), title_text, font=font_title, fill=(255, 220, 80))
    draw.text((bx + 18, by + 42), subtitle_text, font=font_box, fill=(180, 230, 255))

    return canvas, draw

def render_shortcut_fissures(canvas, draw):
    # Single Shortcut Corridor Magma Fissure (y = 27..35, x = 24..27)
    fiss_box = [24 * TILE_SIZE, 27 * TILE_SIZE, 28 * TILE_SIZE, 36 * TILE_SIZE]
    draw.rectangle(fiss_box, fill=(240, 55, 15, 170), outline=(255, 160, 20, 230), width=3)
    for fy in range(27, 36):
        for fx in [24, 25, 26, 27]:
            px = fx * TILE_SIZE
            py = fy * TILE_SIZE
            tex_f = tex_fissure_dorm if fy in [27, 28] else (tex_fissure_warn if fy in [29, 30] else tex_fissure_erupt)
            if tex_f:
                canvas.paste(tex_f, (px, py), tex_f)

    # Route Overlay Lines
    for y in range(21, 42, 2):
        draw.line([(25.5 * TILE_SIZE, y * TILE_SIZE), (25.5 * TILE_SIZE, (y + 1) * TILE_SIZE)], fill=(255, 60, 20, 240), width=5)

    safe_pts_west = [
        (25.5 * TILE_SIZE, 42.5 * TILE_SIZE),
        (7.0 * TILE_SIZE, 42.5 * TILE_SIZE),
        (7.0 * TILE_SIZE, 20.5 * TILE_SIZE),
        (24.0 * TILE_SIZE, 20.5 * TILE_SIZE)
    ]
    for i in range(len(safe_pts_west) - 1):
        draw.line([safe_pts_west[i], safe_pts_west[i+1]], fill=(35, 230, 120, 220), width=5)

    safe_pts_east = [
        (25.5 * TILE_SIZE, 42.5 * TILE_SIZE),
        (45.0 * TILE_SIZE, 42.5 * TILE_SIZE),
        (45.0 * TILE_SIZE, 20.5 * TILE_SIZE),
        (28.0 * TILE_SIZE, 20.5 * TILE_SIZE)
    ]
    for i in range(len(safe_pts_east) - 1):
        draw.line([safe_pts_east[i], safe_pts_east[i+1]], fill=(35, 230, 120, 220), width=5)

def draw_badge(draw, x, y, text, bg_col, border_col, txt_col=(255, 255, 255), pad=6):
    bbox = draw.textbbox((0, 0), text, font=font_sub)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.rectangle([x - pad, y - pad, x + tw + pad, y + th + pad], fill=bg_col, outline=border_col, width=2)
    draw.text((x, y), text, font=font_sub, fill=txt_col)

# ==============================================================================
# OPTION A: INFERNAL RAMPARTS (TEMBOK TIPIS 2-PETAK + PAVING ROAD + COURTYARD RUINS)
# ==============================================================================
def generate_option_a():
    canvas, draw = render_base_scene(
        "OPSI A: INFERNAL RAMPARTS",
        "Tembok benteng tipis (2 petak), paving road lapang & plaza reruntuhan"
    )
    ts = TILE_SIZE

    # 1. Paving / Cobblestone Road Underlay on the Safe Paths (eliminates monotony!)
    # West Paving Strip (x = 5..9, y = 20..42)
    draw.rectangle([5 * ts, 20 * ts, 9 * ts, 43 * ts], fill=(42, 36, 46, 180), outline=(65, 55, 75, 120), width=1)
    draw.rectangle([5 * ts, 41 * ts, 25 * ts, 43 * ts], fill=(42, 36, 46, 180), outline=(65, 55, 75, 120), width=1)
    # East Paving Strip (x = 43..47, y = 20..42)
    draw.rectangle([43 * ts, 20 * ts, 47 * ts, 43 * ts], fill=(42, 36, 46, 180), outline=(65, 55, 75, 120), width=1)
    draw.rectangle([25 * ts, 41 * ts, 47 * ts, 43 * ts], fill=(42, 36, 46, 180), outline=(65, 55, 75, 120), width=1)

    # 2. Thin Rampart Walls (only 2 tiles wide!): x = 18..19 and x = 32..33
    # Textured fortress masonry
    if tex_wall_str:
        st_w = int(tex_wall_str.width * 0.22)
        st_h = int(tex_wall_str.height * 0.22)
        sw = tex_wall_str.resize((st_w, st_h), Image.Resampling.LANCZOS)
        for y in range(21, 42, 2):
            canvas.paste(sw, (int(18 * ts), int(y * ts)), sw)
            canvas.paste(sw, (int(32 * ts), int(y * ts)), sw)

    draw.rectangle([18 * ts, 21 * ts, 20 * ts, 42 * ts], fill=None, outline=(100, 80, 120, 255), width=2)
    draw.rectangle([32 * ts, 21 * ts, 34 * ts, 42 * ts], fill=None, outline=(100, 80, 120, 255), width=2)

    # Watchtowers on Ramparts
    if tex_wall_twr:
        stwr = tex_wall_twr.resize((32, 54), Image.Resampling.LANCZOS)
        for wy in [21, 27, 34, 41]:
            canvas.paste(stwr, (18 * ts - 6, wy * ts - 10), stwr)
            canvas.paste(stwr, (32 * ts - 6, wy * ts - 10), stwr)

    # 3. Rich Atmosphere in the Spacious Courtyards:
    # Decorative small lava pools tucked on outer flanks
    if tex_lava_pool_s:
        slava = tex_lava_pool_s.resize((48, 36), Image.Resampling.LANCZOS)
        canvas.paste(slava, (2 * ts + 8, 25 * ts), slava)
        canvas.paste(slava, (48 * ts - 20, 25 * ts), slava)

    # Ruined pillars in courtyards
    if tex_wall_pil:
        spil = tex_wall_pil.resize((24, 48), Image.Resampling.LANCZOS)
        for px, py in [(12, 25), (14, 33), (12, 38), (38, 25), (36, 33), (38, 38)]:
            canvas.paste(spil, (px * ts, py * ts), spil)

    # Crystals & rocks
    if tex_crystal:
        scrys = tex_crystal.resize((36, 48), Image.Resampling.LANCZOS)
        canvas.paste(scrys, (3 * ts, 35 * ts), scrys)
        canvas.paste(scrys, (48 * ts - 10, 35 * ts), scrys)

    render_shortcut_fissures(canvas, draw)

    draw_badge(draw, 21 * ts - 60, 23 * ts, "JALUR PINTAS (1 LORONG TENGAH)", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "BAHAYA LAHAR STOKASTIK", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 30 * ts, "COURTYARD BARAT LAPANG\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 35 * ts, 30 * ts, "COURTYARD TIMUR LAPANG\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    lx, ly = 20, 35
    draw.rectangle([lx, ly, lx + 440, ly + 140], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 15, ly + 10), "FITUR OPSI A: INFERNAL RAMPARTS", font=font_sub, fill=(140, 190, 255))
    draw.text((lx + 15, ly + 38), "- Tembok benteng sangat ramping: hanya 2 petak (bukan 13 petak!).", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 62), "- Jalur utama diberi paving batu ubin abu-abu yang jelas terbaca.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 86), "- Sayap luar sangat luas, dihiasi pilar runtuh, kristal & kolam lahar kecil.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 110), "- Mengatasi rasa monoton dengan arsitektur militer neraka yang gagah.", font=font_box, fill=(130, 240, 160))

    out_path = os.path.join(ARTIFACT_DIR, "preview_option_a_ramparts.png")
    canvas.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

# ==============================================================================
# OPTION B: VOLCANIC CALDERA (TEBING BASALT BERKELOK ALAMI + POHON HANGUS + LAVA POOL)
# ==============================================================================
def generate_option_b():
    canvas, draw = render_base_scene(
        "OPSI B: VOLCANIC CALDERA & CLIFFS",
        "Tebing basalt alami & berkelok, menghilangkan kesan kotak kaku"
    )
    ts = TILE_SIZE

    # Organic curved rock barriers
    cliff_pts_left = []
    cliff_pts_right = []
    for y in range(21, 42):
        offset = int(math.sin(y * 0.40) * 2.5)
        cx_l = 18 + offset
        cx_r = 33 - offset
        cliff_pts_left.append((cx_l * ts, y * ts))
        cliff_pts_right.append((cx_r * ts, y * ts))

    # Base basalt rock ridges with organic volcanic coloring
    for pt in cliff_pts_left:
        draw.ellipse([pt[0] - 20, pt[1] - 14, pt[0] + 42, pt[1] + 42], fill=(22, 16, 24, 255), outline=(75, 55, 85, 230), width=3)
    for pt in cliff_pts_right:
        draw.ellipse([pt[0] - 20, pt[1] - 14, pt[0] + 42, pt[1] + 42], fill=(22, 16, 24, 255), outline=(75, 55, 85, 230), width=3)

    # Spawn natural large boulders along the ridge
    if tex_rock_l:
        srock = tex_rock_l.resize((38, 38), Image.Resampling.LANCZOS)
        for idx in range(0, len(cliff_pts_left), 2):
            canvas.paste(srock, (int(cliff_pts_left[idx][0] - 10), int(cliff_pts_left[idx][1] - 6)), srock)
            canvas.paste(srock, (int(cliff_pts_right[idx][0] - 10), int(cliff_pts_right[idx][1] - 6)), srock)

    # Rich outdoor volcanic elements:
    # Small decorative lava pools along cliff crevices
    if tex_lava_pool_m:
        mlava = tex_lava_pool_m.resize((64, 48), Image.Resampling.LANCZOS)
        canvas.paste(mlava, (2 * ts + 4, 23 * ts), mlava)
        canvas.paste(mlava, (48 * ts - 32, 23 * ts), mlava)

    # Charred imposing trees in the open highland plateaus
    if tex_tree:
        stree = tex_tree.resize((52, 72), Image.Resampling.LANCZOS)
        canvas.paste(stree, (6 * ts, 27 * ts), stree)
        canvas.paste(stree, (13 * ts, 35 * ts), stree)
        canvas.paste(stree, (43 * ts, 27 * ts), stree)
        canvas.paste(stree, (37 * ts, 35 * ts), stree)

    # Crystals and medium rocks
    if tex_crystal:
        scrys = tex_crystal.resize((36, 48), Image.Resampling.LANCZOS)
        canvas.paste(scrys, (4 * ts, 38 * ts), scrys)
        canvas.paste(scrys, (47 * ts, 38 * ts), scrys)

    render_shortcut_fissures(canvas, draw)

    draw_badge(draw, 21 * ts - 60, 23 * ts, "CELAH KALDERA (JALUR PINTAS)", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "RETAKAN LAHAR MENYALA", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 30 * ts, "DATARAN TINGGI BASALT BARAT\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 35 * ts, 30 * ts, "DATARAN TINGGI BASALT TIMUR\n(100% AMAN, P_h = 0)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    lx, ly = 20, 35
    draw.rectangle([lx, ly, lx + 440, ly + 140], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 15, ly + 10), "FITUR OPSI B: VOLCANIC CALDERA", font=font_sub, fill=(140, 190, 255))
    draw.text((lx + 15, ly + 38), "- Bebas kesan monoton: pembatas berupa tebing basalt meliuk alami.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 62), "- Jalur pintas tengah menyerupai ngarai / celah jurang retakan lahar.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 86), "- Sayap luar adalah padang rumput abu & pohon hangus yang luas.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 110), "- Memberi atmosfer 'Wilderness' neraka yang hidup dan organik.", font=font_box, fill=(130, 240, 160))

    out_path = os.path.join(ARTIFACT_DIR, "preview_option_b_caldera.png")
    canvas.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

# ==============================================================================
# OPTION C: OBSIDIAN COLONNADE (KATEDRAL TERBUKA + JALUR KARPET UPACARA + PILAR)
# ==============================================================================
def generate_option_c():
    canvas, draw = render_base_scene(
        "OPSI C: OBSIDIAN COLONNADE",
        "Barisan pilar katedral megah & balustrade tembus pandang, super megah"
    )
    ts = TILE_SIZE

    # Ceremonial Path Accent on Safe Roads (Violet/Gold Ritual Ribbon)
    draw.rectangle([6 * ts, 20 * ts, 8 * ts, 43 * ts], fill=(55, 20, 45, 160), outline=(180, 140, 50, 140), width=1)
    draw.rectangle([6 * ts, 41 * ts, 25 * ts, 43 * ts], fill=(55, 20, 45, 160), outline=(180, 140, 50, 140), width=1)
    draw.rectangle([44 * ts, 20 * ts, 46 * ts, 43 * ts], fill=(55, 20, 45, 160), outline=(180, 140, 50, 140), width=1)
    draw.rectangle([25 * ts, 41 * ts, 46 * ts, 43 * ts], fill=(55, 20, 45, 160), outline=(180, 140, 50, 140), width=1)

    # Colonnade Railings
    draw.line([(19.5 * ts, 21 * ts), (19.5 * ts, 41.5 * ts)], fill=(90, 75, 110, 240), width=5)
    draw.line([(32.5 * ts, 21 * ts), (32.5 * ts, 41.5 * ts)], fill=(90, 75, 110, 240), width=5)

    # Spaced Majestic Obsidian Pillars
    if tex_wall_pil:
        spil = tex_wall_pil.resize((26, 52), Image.Resampling.LANCZOS)
        for y in range(21, 42, 2):
            canvas.paste(spil, (int(19.5 * ts - 13), int(y * ts - 8)), spil)
            canvas.paste(spil, (int(32.5 * ts - 13), int(y * ts - 8)), spil)

    # Cathedral Sanctuary Elements in the Wings:
    # Statues / Crystal altars in outer naves
    if tex_crystal:
        scrys = tex_crystal.resize((36, 48), Image.Resampling.LANCZOS)
        for py in [24, 32, 38]:
            canvas.paste(scrys, (12 * ts, py * ts), scrys)
            canvas.paste(scrys, (39 * ts, py * ts), scrys)

    # Small braziers / lava wells
    if tex_lava_pool_s:
        slava = tex_lava_pool_s.resize((44, 32), Image.Resampling.LANCZOS)
        canvas.paste(slava, (2 * ts + 10, 28 * ts), slava)
        canvas.paste(slava, (48 * ts - 20, 28 * ts), slava)

    render_shortcut_fissures(canvas, draw)

    draw_badge(draw, 21 * ts - 60, 23 * ts, "COLONNADE LORONG PINTAS", (40, 10, 10, 245), (255, 60, 20), (255, 130, 90))
    draw_badge(draw, 21 * ts - 50, 31 * ts, "PERANGKAP LAHAR STOKASTIK", (50, 15, 10, 245), (255, 160, 30), (255, 210, 110))
    draw_badge(draw, 4 * ts, 30 * ts, "GRAND NAVE BARAT\n(100% AMAN, VISUAL TERBUKA)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))
    draw_badge(draw, 35 * ts, 30 * ts, "GRAND NAVE TIMUR\n(100% AMAN, VISUAL TERBUKA)", (10, 35, 20, 245), (40, 210, 110), (130, 255, 190))

    lx, ly = 20, 35
    draw.rectangle([lx, ly, lx + 440, ly + 140], fill=(15, 12, 22, 245), outline=(100, 140, 220), width=3)
    draw.text((lx + 15, ly + 10), "FITUR OPSI C: OBSIDIAN COLONNADE", font=font_sub, fill=(140, 190, 255))
    draw.text((lx + 15, ly + 38), "- Tidak ada dinding masif kotak: diganti barisan pilar megah & balustrade.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 62), "- Peta tembus pandang (line-of-sight luas), atmosfer katedral neraka agung.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 86), "- Sayap luar dihiasi karpet upacara, kristal obsidian & kolam api kecil.", font=font_box, fill=(230, 230, 240))
    draw.text((lx + 15, ly + 110), "- Tetap kokoh secara gameplay: pilar & pagar tidak bisa diterobos.", font=font_box, fill=(130, 240, 160))

    out_path = os.path.join(ARTIFACT_DIR, "preview_option_c_colonnade.png")
    canvas.save(out_path, "PNG")
    print(f"[OK] Generated: {out_path}")

if __name__ == "__main__":
    generate_option_a()
    generate_option_b()
    generate_option_c()
