import os
import shutil
from PIL import Image, ImageDraw, ImageFont

BASE_SPRITES = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\assets\sprites"
PREVIEWS_DIR = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\laporan_assets\asset_previews"
ARTIFACT_DIR = r"C:\Users\MyBook Hype AMD\.gemini\antigravity\brain\07868943-55b7-4b4c-ab20-c1b7547b1bbf"

def load_img(rel_path):
    # Check in previews first, then in base sprites
    p1 = os.path.join(PREVIEWS_DIR, rel_path)
    if os.path.exists(p1):
        return Image.open(p1).convert("RGBA")
    p2 = os.path.join(BASE_SPRITES, rel_path.replace("/", os.sep))
    if os.path.exists(p2):
        return Image.open(p2).convert("RGBA")
    print("WARNING: Not found ->", rel_path)
    return Image.new("RGBA", (32, 32), (255, 0, 0, 128))

def draw_card(canvas, x, y, w, h, title, subtitle="", border_col=(80, 70, 95)):
    draw = ImageDraw.Draw(canvas)
    # Dark card background
    draw.rectangle([x, y, x + w, y + h], fill=(22, 18, 28, 255), outline=border_col, width=2)
    # Header bar
    draw.rectangle([x, y, x + w, y + 26], fill=(36, 30, 46, 255))
    draw.text((x + 8, y + 6), title, fill=(240, 230, 255))
    if subtitle:
        draw.text((x + 8, y + h - 20), subtitle, fill=(160, 150, 180))

# ========================================================
# SHOWCASE 1: KATEGORI A (TAHAP 4 MDP & PLANNING)
# ========================================================
def build_showcase_kategori_a():
    cw, ch = 960, 900
    canvas = Image.new("RGBA", (cw, ch), (14, 10, 18, 255))
    draw = ImageDraw.Draw(canvas)

    # Master Title
    draw.rectangle([0, 0, cw, 60], fill=(28, 16, 24, 255))
    draw.rectangle([0, 58, cw, 60], fill=(230, 70, 20, 255))
    draw.text((24, 16), "INFERNAL AFFAIRS - SHOWCASE ASET TAHAP 4 (KATEGORI A: UTAMA & MDP)", fill=(255, 230, 150))
    draw.text((24, 38), "Handcrafted 2D Pixel Art: Jembatan, Hazard Semburan Api, Altar Sumber Daya, Kristal, Kurir & Emote", fill=(180, 170, 200))

    # Card 1: A1 Modular Stone Bridge (x=20, y=75, w=440, h=260)
    draw_card(canvas, 20, 75, 440, 260, "A1: Modular Stone Bridge Tileset & Demo", "32x32 tiles: Stone Deck, Scorched Shortcut, Railings, Pillars")
    tset = load_img("A1_bridge_stone_tileset.png").resize((256, 128), Image.NEAREST)
    canvas.paste(tset, (35, 115), tset)
    bdemo = load_img("A1_bridge_assembled_demo.png").resize((120, 150), Image.NEAREST)
    canvas.paste(bdemo, (320, 110), bdemo)

    # Card 2: A2 Flame Column VFX (x=480, y=75, w=460, h=150)
    draw_card(canvas, 480, 75, 460, 150, "A2: Animated Flame Column VFX (Fase ERUPTION)", "6 Frames Strip (32x64 px) - Semburan Api Mematikan Jalur d")
    flame = load_img("A2_vfx_flame_column_sheet.png").resize((384, 96), Image.NEAREST)
    canvas.paste(flame, (510, 110), flame)

    # Card 3: A3 Warning Cracks & A4 Dormant (x=480, y=240, w=460, h=140)
    draw_card(canvas, 480, 240, 460, 140, "A3: Warning Cracks (W=1) & A4: Dormant Fissure", "Sensor Telegraph Magma & Steam (A3) + Ubin Aman Dilalui (A4)")
    warn = load_img("A3_vfx_warning_crack_sheet.png").resize((256, 64), Image.NEAREST)
    canvas.paste(warn, (495, 280), warn)
    dorm = load_img("map/hazards/fissure_dormant.png").resize((64, 64), Image.NEAREST)
    canvas.paste(dorm, (820, 280), dorm)

    # Card 4: A5, A6, A7 - Tiga Altar Elemen (x=20, y=350, w=440, h=240)
    draw_card(canvas, 20, 350, 440, 240, "A5, A6, A7: Tiga Altar Sumber Daya (Resource Nodes)", "Ignis Altar (Node 1) | Abyssal Shrine (Node 2) | Sanguine Well (Node 3)")
    a5 = load_img("map/obstacles/altar_ignis.png").resize((110, 110), Image.NEAREST)
    a6 = load_img("map/obstacles/altar_abyssal.png").resize((110, 110), Image.NEAREST)
    a7 = load_img("map/obstacles/altar_sanguine.png").resize((110, 110), Image.NEAREST)
    canvas.paste(a5, (35, 395), a5)
    canvas.paste(a6, (175, 395), a6)
    canvas.paste(a7, (315, 395), a7)
    draw.text((50, 520), "Ignis (Flame)", fill=(255, 160, 60))
    draw.text((185, 520), "Abyssal (Void)", fill=(200, 120, 255))
    draw.text((320, 520), "Sanguine (Blood)", fill=(255, 90, 100))

    # Card 5: A8 Spinning Shards & A9 Dropped Crystal & A10 Sparkle (x=480, y=395, w=460, h=220)
    draw_card(canvas, 480, 395, 460, 220, "A8, A9, A10: Kristal Elemen, Drop Item & Sparkle VFX", "Spinning Shards (Flame, Void, Blood) | Drop Item Begal | Twinkle VFX")
    a8 = load_img("A8_shards_spinning_sheet.png").resize((220, 130), Image.NEAREST)
    canvas.paste(a8, (495, 435), a8)
    a9 = load_img("A9_crystal_dropped.png").resize((50, 50), Image.NEAREST)
    canvas.paste(a9, (750, 445), a9)
    draw.text((740, 505), "A9: Drop Item", fill=(255, 200, 120))
    a10 = load_img("A10_item_sparkle_sheet.png").resize((150, 36), Image.NEAREST)
    canvas.paste(a10, (735, 535), a10)
    draw.text((745, 575), "A10: Sparkle VFX", fill=(180, 240, 255))

    # Card 6: A11 Minion Carrier Walk Sheet (x=20, y=605, w=440, h=275)
    draw_card(canvas, 20, 605, 440, 275, "A11: Minion Kurir Membawa Keranjang Kristal", "Spritesheet 4 Arah (Down, Up, Left, Right) dengan Keranjang Pikul Kristal")
    m_carrier = load_img("characters/minion/minion_carrier.png").resize((220, 220), Image.NEAREST)
    canvas.paste(m_carrier, (130, 645), m_carrier)

    # Card 7: A12 Pixel Emote Balloons (x=480, y=630, w=460, h=250)
    draw_card(canvas, 480, 630, 460, 250, "A12: Pixel Emote Balloons (Sensor & Bayesian AI)", "Indikator Reaksi Pikiran Minion: ! (Alert W=1), ? (Reroute), X (Panic)")
    emotes = load_img("A12_emote_balloons.png").resize((288, 96), Image.NEAREST)
    canvas.paste(emotes, (530, 680), emotes)
    draw.text((545, 790), "[ ! ] Bahaya Magma", fill=(255, 140, 40))
    draw.text((680, 790), "[ ? ] Evaluasi Rute", fill=(90, 190, 255))
    draw.text((810, 790), "[ X ] Kena Api / Kabur", fill=(240, 140, 255))

    out_p = os.path.join(PREVIEWS_DIR, "showcase_kategori_a_tahap4.png")
    canvas.save(out_p)
    shutil.copy(out_p, os.path.join(ARTIFACT_DIR, "showcase_kategori_a_tahap4.png"))
    print("Saved ->", out_p)
    return out_p

# ========================================================
# SHOWCASE 2: KATEGORI B (LINGKUNGAN & MAP)
# ========================================================
def build_showcase_kategori_b():
    cw, ch = 960, 750
    canvas = Image.new("RGBA", (cw, ch), (14, 10, 18, 255))
    draw = ImageDraw.Draw(canvas)

    # Master Title
    draw.rectangle([0, 0, cw, 60], fill=(28, 16, 24, 255))
    draw.rectangle([0, 58, cw, 60], fill=(230, 70, 20, 255))
    draw.text((24, 16), "INFERNAL AFFAIRS - SHOWCASE ASET LINGKUNGAN (KATEGORI B)", fill=(255, 230, 150))
    draw.text((24, 38), "Handcrafted 2D Pixel Art: Danau Lahar, Tebing Jurang, Gerbang Gothic, Flora Vulkanik & Singgasana", fill=(180, 170, 200))

    # Card 1: B1 Animated Lava River (x=20, y=75, w=540, h=250)
    draw_card(canvas, 20, 75, 540, 250, "B1: Seamless Molten Lava River Autotile", "Tekstur Aliran Lahar Panas Horizontal Tanpa Sambungan Batu Kaku")
    lava = load_img("map/lava/extracted/river_grand_horizontal.png").resize((500, 180), Image.NEAREST)
    canvas.paste(lava, (40, 115), lava)

    # Card 2: B2 Canyon / Cliff Edge (x=580, y=75, w=360, h=250)
    draw_card(canvas, 580, 75, 360, 250, "B2: Canyon / Cliff Edge Autotile", "Dinding Jurang Tebing 2.5D Menuju Lahar")
    cliff = load_img("B2_cliff_edge_tileset.png").resize((280, 70), Image.NEAREST)
    canvas.paste(cliff, (620, 150), cliff)
    draw.text((620, 240), "Top Lip | Left Wall | Right Wall | Base Shore", fill=(180, 170, 200))

    # Card 3: B3 Gothic Demon Gate Closed & Open (x=20, y=340, w=440, h=220)
    draw_card(canvas, 20, 340, 440, 220, "B3: Heavy Gothic Demon Gate (Closed & Open)", "Gerbang Besi Tempa Hitam dengan Tengkorak Neraka & Rantai Segel CSP")
    g_closed = load_img("map/obstacles/gate_hell_closed.png").resize((140, 140), Image.NEAREST)
    g_open = load_img("map/obstacles/gate_hell_open.png").resize((140, 140), Image.NEAREST)
    canvas.paste(g_closed, (50, 385), g_closed)
    canvas.paste(g_open, (250, 385), g_open)
    draw.text((70, 530), "Terkunci (CSP Segel)", fill=(255, 100, 80))
    draw.text((275, 530), "Terbuka (Level >= 3)", fill=(120, 255, 140))

    # Card 4: B4 Charred Trees & Rocks & Crystals (x=480, y=340, w=460, h=220)
    draw_card(canvas, 480, 340, 460, 220, "B4: Charred Wilderness Flora & Obstacles", "Pohon Hangus Membara, Batu Basalt & Kristal Vulkanis")
    tree = load_img("map/obstacles/tree_large.png").resize((90, 125), Image.NEAREST)
    rock = load_img("map/obstacles/rock_large.png").resize((95, 120), Image.NEAREST)
    cryst = load_img("map/obstacles/crystal_large.png").resize((80, 110), Image.NEAREST)
    canvas.paste(tree, (510, 385), tree)
    canvas.paste(rock, (635, 390), rock)
    canvas.paste(cryst, (765, 400), cryst)

    # Card 5: B5 Obsidian Throne of Hell (x=20, y=575, w=920, h=160)
    draw_card(canvas, 20, 575, 920, 160, "B5: Obsidian Throne of Hell (Map 2 - Castle Throne Room)", "Singgasana Raja Iblis Demon Lord dari Batu Obsidian Bertabur Permata Darah")
    throne = load_img("map/obstacles/throne_boss.png").resize((115, 115), Image.NEAREST)
    canvas.paste(throne, (60, 610), throne)
    draw.text((210, 630), "Takhta Megah Penguasa Neraka untuk Pertarungan Final (Tahap 4)", fill=(255, 230, 180))
    draw.text((210, 655), "• Ukuran: 256x256 px (Skala 2x2 tile di atas ubin karpet istana)", fill=(190, 180, 210))
    draw.text((210, 680), "• Fitur: Mahkota tengkorak obsidian, bantal permata crimson, dan aura panas bawah tanah", fill=(190, 180, 210))

    out_p = os.path.join(PREVIEWS_DIR, "showcase_kategori_b_environment.png")
    canvas.save(out_p)
    shutil.copy(out_p, os.path.join(ARTIFACT_DIR, "showcase_kategori_b_environment.png"))
    print("Saved ->", out_p)
    return out_p

# ========================================================
# SHOWCASE 3: KATEGORI C (KARAKTER, DUEL & UI)
# ========================================================
def build_showcase_kategori_c():
    cw, ch = 960, 840
    canvas = Image.new("RGBA", (cw, ch), (14, 10, 18, 255))
    draw = ImageDraw.Draw(canvas)

    # Master Title
    draw.rectangle([0, 0, cw, 60], fill=(28, 16, 24, 255))
    draw.rectangle([0, 58, cw, 60], fill=(230, 70, 20, 255))
    draw.text((24, 16), "INFERNAL AFFAIRS - SHOWCASE KARAKTER & UI (KATEGORI C)", fill=(255, 230, 150))
    draw.text((24, 38), "Handcrafted 2D Pixel Art: Battle Portraits Arena Duel, Ikon Skill & Segel Magis", fill=(180, 170, 200))

    # Card 1: C1 Battle Portraits (x=20, y=75, w=920, h=470)
    draw_card(canvas, 20, 75, 920, 470, "C1: Karakter Battle Portraits (Panggung Duel Turn-Based)", "Ilustrasi Penuh 6 Karakter Menghadap Arena Pertarungan")
    
    portraits = [
        ("Player Knight", "characters/player/player_portrait.png", (255, 220, 140)),
        ("Guard Knight", "characters/guard/guard_knight_portrait.png", (255, 140, 80)),
        ("Guard Shaman", "characters/guard/guard_shaman_portrait.png", (200, 130, 255)),
        ("Guard Gargoyle", "characters/guard/guard_gargoyle_portrait.png", (180, 200, 220)),
        ("Minion Imp", "characters/minion/minion_portrait.png", (255, 100, 100)),
        ("Demon Lord", "characters/demon/demon_boss.png", (255, 60, 50)),
    ]

    for idx, (pname, ppath, pcolor) in enumerate(portraits):
        col = idx % 3
        row = idx // 3
        px = 45 + col * 300
        py = 115 + row * 215
        
        # Inner portrait box
        draw.rectangle([px, py, px + 260, py + 185], fill=(26, 20, 32, 255), outline=(70, 58, 85), width=2)
        pimg = load_img(ppath).resize((140, 140), Image.NEAREST)
        canvas.paste(pimg, (px + 60, py + 12), pimg)
        draw.text((px + 15, py + 160), pname, fill=pcolor)

    # Card 2: C2 Retro Skill & Status Icons (x=20, y=560, w=920, h=260)
    draw_card(canvas, 20, 560, 920, 260, "C2: Icon Skills, Potions & Gate Seals (Battle HUD)", "Ikon 32x32 / 64x64 Pixel Art dengan Outline Kontras Tebal")
    
    icons = [
        ("Sword", "ui/skills/icon_sword.png"),
        ("Shield", "ui/skills/icon_shield.png"),
        ("Potion", "ui/skills/icon_potion.png"),
        ("Heavy Atk", "ui/skills/icon_heavy_attack.png"),
        ("Castle Key", "ui/skills/icon_castle_key.png"),
        ("Badge Lv", "ui/skills/icon_level_badge.png"),
    ]

    for idx, (iname, ipath) in enumerate(icons):
        ix = 50 + idx * 95
        iy = 605
        draw.rectangle([ix, iy, ix + 75, iy + 85], fill=(30, 24, 38, 255), outline=(85, 70, 100), width=2)
        ic_img = load_img(ipath).resize((50, 50), Image.NEAREST)
        canvas.paste(ic_img, (ix + 12, iy + 8), ic_img)
        draw.text((ix + 10, iy + 64), iname, fill=(220, 210, 240))

    # Gate Seals
    draw.text((650, 605), "3 Segel Magis Gerbang (CSP):", fill=(255, 200, 120))
    seals = load_img("map/obstacles/seals_gate_sheet.png").resize((270, 90), Image.NEAREST)
    canvas.paste(seals, (650, 635), seals)
    draw.text((660, 735), "Flame Seal", fill=(255, 140, 40))
    draw.text((750, 735), "Shadow Seal", fill=(200, 120, 255))
    draw.text((850, 735), "Blood Seal", fill=(255, 80, 90))

    out_p = os.path.join(PREVIEWS_DIR, "showcase_kategori_c_combat_ui.png")
    canvas.save(out_p)
    shutil.copy(out_p, os.path.join(ARTIFACT_DIR, "showcase_kategori_c_combat_ui.png"))
    print("Saved ->", out_p)
    return out_p

build_showcase_kategori_a()
build_showcase_kategori_b()
build_showcase_kategori_c()
print("All 3 Master Showcase Sheets successfully generated and copied to artifact directory!")
