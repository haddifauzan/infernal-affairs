import os
import shutil

base = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\assets\sprites"
prev = r"d:\Tugas\KULIAH\SEMESTER 3\Kecerdasan Buatan\Tugas\tubes\infernal-affairs\laporan_assets\asset_previews"

tasks = [
    ("A1_bridge_stone_tileset.png", os.path.join(base, "map", "ground", "bridge_stone.png")),
    ("A2_vfx_flame_column_sheet.png", os.path.join(base, "map", "hazards", "vfx_flame_column_sheet.png")),
    ("A3_vfx_warning_crack_sheet.png", os.path.join(base, "map", "hazards", "vfx_warning_crack_sheet.png")),
    ("A8_shards_spinning_sheet.png", os.path.join(base, "map", "obstacles", "shards_spinning_sheet.png")),
    ("A9_crystal_dropped.png", os.path.join(base, "map", "obstacles", "crystal_dropped.png")),
    ("A10_item_sparkle_sheet.png", os.path.join(base, "effects", "item_sparkle.png")),
    ("A12_emote_balloons.png", os.path.join(base, "ui", "effects", "emote_balloons.png")),
    ("B2_cliff_edge_tileset.png", os.path.join(base, "map", "ground", "cliff_edge.png")),
]

os.makedirs(os.path.join(base, "effects"), exist_ok=True)
os.makedirs(os.path.join(base, "ui", "effects"), exist_ok=True)

for src_name, dst_path in tasks:
    src_path = os.path.join(prev, src_name)
    if os.path.exists(src_path):
        os.makedirs(os.path.dirname(dst_path), exist_ok=True)
        shutil.copyfile(src_path, dst_path)
        print(f"Copied: {src_name} -> {dst_path}")
    else:
        print(f"Source missing: {src_path}")

print("All asset copies completed successfully.")
