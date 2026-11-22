import os
from PIL import Image

actual_checks = [
    ("A1 Modular Stone Bridge Tileset", "map/ground/bridge_stone.png"),
    ("A2 Animated Flame Column VFX", "map/hazards/vfx_flame_column_sheet.png"),
    ("A3 Warning Magma Cracks & Steam", "map/hazards/vfx_warning_crack_sheet.png"),
    ("A4 Dormant Basalt Fissure Tile", "map/hazards/fissure_dormant.png"),
    ("A5 Ignis Altar (Fire Brazier)", "map/obstacles/altar_ignis.png"),
    ("A6 Abyssal Fissure (Void Monolith)", "map/obstacles/altar_abyssal.png"),
    ("A7 Sanguine Well (Blood Well)", "map/obstacles/altar_sanguine.png"),
    ("A8 Spinning Elemental Shards", "map/obstacles/shards_spinning_sheet.png"),
    ("A9 Dropped Crystal (Overworld)", "map/obstacles/crystal_dropped.png"),
    ("A10 Item Sparkle / Pulse VFX", "effects/item_sparkle.png"),
    ("A11 Minion Carrier Walk Sheet", "characters/minion/minion_carrier.png"),
    ("A12 Pixel Emote Balloons", "ui/effects/emote_balloons.png"),
    ("B1 Animated Lava Autotile", "map/lava/extracted/river_grand_horizontal.png"),
    ("B2 Canyon / Cliff Edge Autotile", "map/ground/cliff_edge.png"),
    ("B3 Gothic Demon Gate Open/Close", "map/obstacles/gate_hell_open.png"),
    ("B4 Charred Trees & Flora", "map/obstacles/tree_large.png"),
    ("B5 Obsidian Throne of Hell", "map/obstacles/throne_boss.png"),
    ("C1 Player Pixel Portrait", "characters/player/player_portrait.png"),
    ("C1 Guard Knight Portrait", "characters/guard/guard_knight_portrait.png"),
    ("C1 Guard Shaman Portrait", "characters/guard/guard_shaman_portrait.png"),
    ("C1 Guard Gargoyle Portrait", "characters/guard/guard_gargoyle_portrait.png"),
    ("C1 Minion Imp Portrait", "characters/minion/minion_portrait.png"),
    ("C1 Demon Lord Boss Portrait", "characters/demon/demon_boss.png"),
    ("C2 Retro Skill & Status Icons", "ui/skills/icon_sword.png"),
]

base = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\assets\sprites"
print("=== ASSET AUDIT REPORT ===")
for label, p in actual_checks:
    fp = os.path.join(base, p.replace("/", os.sep))
    exists = os.path.exists(fp)
    if exists:
        im = Image.open(fp)
        status = "READY"
        info = f"{str(im.size):12} ({im.mode})"
    else:
        status = "NEED_GEN"
        info = "FILE_MISSING"
    print(f"{label:35} | {status:8} | {info:20} | {p}")
