"""
Generate 2D Map Visualization for Tahap 4 (Infernal Affairs)
Decision Under Uncertainty & Markov Decision Processes (MDP)
Matches:
- 09_Decision under uncertainity.pdf
- PLAN_TAHAP_4.md
- GridManager.gd topology (44x46 tiles)
- StochasticHazardManager.gd
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from collections import deque

WIDTH = 44
HEIGHT = 46

TileType = {
    "GROUND": 0,
    "OBSTACLE": 1,
    "LAVA": 2,
    "BRIDGE": 3
}

# 1. Build Grid matching GridManager.gd
grid = [[TileType["GROUND"] for _ in range(WIDTH)] for _ in range(HEIGHT)]

# Outer perimeter
for x in range(WIDTH):
    grid[0][x] = TileType["OBSTACLE"]
    grid[HEIGHT - 1][x] = TileType["OBSTACLE"]
for y in range(HEIGHT):
    grid[y][0] = TileType["OBSTACLE"]
    grid[y][WIDTH - 1] = TileType["OBSTACLE"]

CENTER_X = 21
COURTYARD_Y = 19

# Castle walls & pillars (Map 2)
for y in range(1, 17):
    grid[y][1] = TileType["OBSTACLE"]
    grid[y][2] = TileType["OBSTACLE"]
    grid[y][WIDTH - 2] = TileType["OBSTACLE"]
    grid[y][WIDTH - 3] = TileType["OBSTACLE"]

for py in [6, 10, 14]:
    for px in [8, 14, 28, 34]:
        grid[py][px] = TileType["OBSTACLE"]
        grid[py + 1][px] = TileType["OBSTACLE"]

# Castle front wall at y = 17..18
for y in [17, 18]:
    for x in range(1, WIDTH - 1):
        if x != CENTER_X and x != CENTER_X + 1:
            grid[y][x] = TileType["OBSTACLE"]

# Castle wall foot at y = 19
for x in range(1, WIDTH - 1):
    if x != CENTER_X and x != CENTER_X + 1:
        if x not in [5, 6, 37, 38]:
            grid[COURTYARD_Y][x] = TileType["OBSTACLE"]

# Lava basins (y = 20..34)
for y in range(20, 35):
    for x in range(1, 5):
        grid[y][x] = TileType["LAVA"]
    for x in range(7, 21):
        grid[y][x] = TileType["LAVA"]
    for x in range(23, 37):
        grid[y][x] = TileType["LAVA"]
    for x in range(39, WIDTH - 1):
        grid[y][x] = TileType["LAVA"]

# Clear Safe Paths 'a', Central Road, and Ground 'c'
for y in range(20, 35):
    for x in [5, 6]:
        grid[y][x] = TileType["GROUND"]
    for x in [37, 38]:
        grid[y][x] = TileType["GROUND"]

for y in range(COURTYARD_Y, 35):
    for x in [21, 22]:
        grid[y][x] = TileType["GROUND"]

for y in range(35, HEIGHT - 1):
    for x in range(1, WIDTH - 1):
        grid[y][x] = TileType["GROUND"]

# Shortcut Bridges 'd' (y = 20..21)
bridge_tiles = set()
for dy in range(2):
    for dx in range(14):
        bx1, by1 = 7 + dx, 20 + dy
        bx2, by2 = 23 + dx, 20 + dy
        grid[by1][bx1] = TileType["BRIDGE"]
        grid[by2][bx2] = TileType["BRIDGE"]
        bridge_tiles.add((bx1, by1))
        bridge_tiles.add((bx2, by2))

# Landmarks in Ground 'c'
landmarks_2x2 = [(10, 41), (32, 41), (2, 38), (40, 38), (15, 43), (27, 43)]
for bx, by in landmarks_2x2:
    for dy in [0, 1]:
        for dx in [0, 1]:
            if 0 <= bx + dx < WIDTH and 0 <= by + dy < HEIGHT:
                grid[by + dy][bx + dx] = TileType["OBSTACLE"]

landmarks_1x1 = [(8, 39), (34, 39), (17, 42), (25, 42)]
for x, y in landmarks_1x1:
    grid[y][x] = TileType["OBSTACLE"]

trees = [(2, 35), (41, 35), (6, 42), (37, 42), (12, 44), (30, 44)]
for x, y in trees:
    grid[y][x] = TileType["OBSTACLE"]

# BFS Pathfinding for Route Overlays
def is_walkable(x, y, allow_bridges=True):
    if not (0 <= x < WIDTH and 0 <= y < HEIGHT):
        return False
    t = grid[y][x]
    if t == TileType["GROUND"]:
        return True
    if t == TileType["BRIDGE"] and allow_bridges:
        return True
    return False

def bfs(start, goal, allow_bridges=True):
    q = deque([(start, [start])])
    visited = {start}
    dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)]
    while q:
        curr, path = q.popleft()
        if curr == goal:
            return path
        for dx, dy in dirs:
            nxt = (curr[0] + dx, curr[1] + dy)
            if is_walkable(nxt[0], nxt[1], allow_bridges) and nxt not in visited:
                visited.add(nxt)
                q.append((nxt, path + [nxt]))
    return None

altar_ignis = (5, 21)
altar_abyssal = (38, 21)
altar_sanguine = (21, 38)
guard_post = (21, 19)

path_ignis_pintas = bfs(altar_ignis, guard_post, allow_bridges=True)
path_ignis_raya = bfs(altar_ignis, guard_post, allow_bridges=False)
path_abyssal_pintas = bfs(altar_abyssal, (22, 19), allow_bridges=True)
path_abyssal_raya = bfs(altar_abyssal, (22, 19), allow_bridges=False)

# 2. Rendering High-Definition 2D Map
fig = plt.figure(figsize=(24, 16), dpi=150, facecolor="#0a0711")
gs = fig.add_gridspec(1, 2, width_ratios=[1.3, 0.7], wspace=0.08)
ax_map = fig.add_subplot(gs[0, 0])
ax_info = fig.add_subplot(gs[0, 1])

# Map Setup
ax_map.set_facecolor("#0a0711")
ax_map.set_xlim(-0.5, WIDTH - 0.5)
ax_map.set_ylim(HEIGHT - 0.5, -0.5)  # Invert Y so 0 is top
ax_map.set_aspect("equal")

COLOR_GROUND_CASTLE = "#1b1426"
COLOR_GROUND_WILD = "#18151f"
COLOR_OBSTACLE_WALL = "#312842"
COLOR_OBSTACLE_ROCK = "#292133"
COLOR_LAVA = "#941f05"
COLOR_LAVA_CORE = "#e65100"
COLOR_BRIDGE = "#423b54"

# Draw Grid Cells
for y in range(HEIGHT):
    for x in range(WIDTH):
        t = grid[y][x]
        rect_color = COLOR_GROUND_WILD
        if y < 17:
            rect_color = COLOR_GROUND_CASTLE
        
        if t == TileType["OBSTACLE"]:
            if y < 20:
                rect_color = COLOR_OBSTACLE_WALL
            else:
                rect_color = COLOR_OBSTACLE_ROCK
        elif t == TileType["LAVA"]:
            rect_color = COLOR_LAVA
        elif t == TileType["BRIDGE"]:
            rect_color = COLOR_BRIDGE

        rect = patches.Rectangle((x - 0.5, y - 0.5), 1.0, 1.0,
                                 facecolor=rect_color,
                                 edgecolor="#110d18",
                                 linewidth=0.35)
        ax_map.add_patch(rect)

# Draw Lava Basin Glowing Core Accents
for y in range(20, 35):
    for x in list(range(1, 5)) + list(range(7, 21)) + list(range(23, 37)) + list(range(39, WIDTH - 1)):
        if (x, y) not in bridge_tiles:
            dot = patches.Circle((x, y), 0.20, facecolor=COLOR_LAVA_CORE, edgecolor="none", alpha=0.75)
            ax_map.add_patch(dot)

# Draw Hazard Fissures on Bridges 'd' with Warning Striping
for bx, by in bridge_tiles:
    hazard_patch = patches.Rectangle((bx - 0.42, by - 0.42), 0.84, 0.84,
                                     facecolor="#ff3d00", edgecolor="#ffeb3b",
                                     linewidth=0.8, alpha=0.55, linestyle="--")
    ax_map.add_patch(hazard_patch)
    ax_map.plot(bx, by, marker="^", markersize=3.2, color="#ffffff", alpha=0.9)

# Zone Divider Lines & Badges
ax_map.axhline(16.5, color="#ab47bc", linestyle="--", linewidth=1.2, alpha=0.8)
ax_map.text(3.5, 15.8, "ZONE 1: BOSS THRONE CHAMBER (y = 1..16)",
            color="#e1bee7", fontsize=8.5, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.25", facecolor="#241233", edgecolor="#ab47bc", alpha=0.9))

ax_map.axhline(19.5, color="#ffa726", linestyle="--", linewidth=1.2, alpha=0.8)
ax_map.text(3.5, 17.5, "ZONE 2: FORTIFIED CITADEL & GUARD GATE (y = 17..19)",
            color="#ffe0b2", fontsize=8.5, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.25", facecolor="#2e1905", edgecolor="#ffa726", alpha=0.9))

ax_map.text(3.5, 36.2, "ZONE 3: VOLCANIC ASH WILDERNESS & LAVA NETWORKS (y = 20..45)",
            color="#ffab91", fontsize=8.5, fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.25", facecolor="#2b0e06", edgecolor="#ff7043", alpha=0.9))

# Draw Key Entities
# Boss & Throne
ax_map.plot(21, 2, marker="s", markersize=14, color="#ffb300", markeredgecolor="#ffffff", markeredgewidth=1.5)
ax_map.text(21, 1.0, "THRONE (21, 2)", color="#ffecb3", fontsize=8, fontweight="bold", ha="center")

ax_map.plot(21, 4, marker="D", markersize=15, color="#d50000", markeredgecolor="#ffffff", markeredgewidth=1.5)
ax_map.text(21, 5.2, "DEMON LORD (BOSS) (21, 4)", color="#ff8a80", fontsize=8, fontweight="bold", ha="center")

# Guard Post (Collection Point)
ax_map.plot(21, 19, marker="p", markersize=16, color="#00e676", markeredgecolor="#ffffff", markeredgewidth=1.5)
ax_map.text(21.5, 18.5, "POS PENJAGA (Goal $s_4$)\nDeliver +10 Reward | (21, 19)",
            color="#b9f6ca", fontsize=8, fontweight="bold", ha="left",
            bbox=dict(boxstyle="round,pad=0.25", facecolor="#052613", edgecolor="#00e676", alpha=0.9))

# Elemental Altars
# 1. Ignis (Flame) - Node 1
ax_map.plot(5, 21, marker="o", markersize=14, color="#ff5722", markeredgecolor="#ffffff", markeredgewidth=1.8)
ax_map.text(5, 22.8, "IGNIS ALTAR\n(Flame, Node 1)\n(5, 21)", color="#ffab91",
            fontsize=7.5, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#291207", edgecolor="#ff5722", alpha=0.85))

# 2. Abyssal (Shadow) - Node 2
ax_map.plot(38, 21, marker="o", markersize=14, color="#7c4dff", markeredgecolor="#ffffff", markeredgewidth=1.8)
ax_map.text(38, 22.8, "ABYSSAL FISSURE\n(Shadow, Node 2)\n(38, 21)", color="#b388ff",
            fontsize=7.5, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#1b0e2b", edgecolor="#7c4dff", alpha=0.85))

# 3. Sanguine (Blood) - Node 3
ax_map.plot(21, 38, marker="o", markersize=14, color="#e91e63", markeredgecolor="#ffffff", markeredgewidth=1.8)
ax_map.text(21, 39.5, "SANGUINE WELL (Blood, Node 3) (21, 38)", color="#f48fb1",
            fontsize=8, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#2b0d19", edgecolor="#e91e63", alpha=0.85))

# Player Spawn
ax_map.plot(21, 42, marker="*", markersize=18, color="#00e5ff", markeredgecolor="#ffffff", markeredgewidth=1.5)
ax_map.text(21, 43.4, "PLAYER SPAWN (21, 42)", color="#84ffff",
            fontsize=8, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#072229", edgecolor="#00e5ff", alpha=0.85))

# Decision Crossroads (Simpang Lembah - s1)
circle_s1_w = patches.Circle((5.5, 20.0), 1.5, fill=False, edgecolor="#ffeb3b", linewidth=2.4, linestyle="--")
ax_map.add_patch(circle_s1_w)
ax_map.text(5.5, 16.5, "SIMPANG $s_1$ (West)\nBellman Decision Node", color="#fff59d", fontsize=7.5, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#262408", edgecolor="#ffeb3b", alpha=0.85))

circle_s1_e = patches.Circle((37.5, 20.0), 1.5, fill=False, edgecolor="#ffeb3b", linewidth=2.4, linestyle="--")
ax_map.add_patch(circle_s1_e)
ax_map.text(37.5, 16.5, "SIMPANG $s_1$ (East)\nBellman Decision Node", color="#fff59d", fontsize=7.5, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.2", facecolor="#262408", edgecolor="#ffeb3b", alpha=0.85))

# Draw MDP Policy Trajectories (from Ignis Altar)
# 1. Jalur Pintas (Risky Shortcut, s2 -> s4)
if path_ignis_pintas:
    px = [p[0] for p in path_ignis_pintas]
    py = [p[1] for p in path_ignis_pintas]
    ax_map.plot(px, py, color="#ff1744", linewidth=3.4, linestyle="-", alpha=0.9,
                label=f"Jalur Pintas ($s_2$, Jembatan 'd'): ~{len(path_ignis_pintas)} steps (Risiko Magma f, R=-20)")
    for i in range(3, len(path_ignis_pintas) - 2, 3):
        ax_map.annotate("", xy=(px[i+1], py[i+1]), xytext=(px[i], py[i]),
                        arrowprops=dict(arrowstyle="->", color="#ff5252", lw=2.2))

# 2. Jalur Utama Aman (Safe Detour, s3 -> s4)
if path_ignis_raya:
    px = [p[0] for p in path_ignis_raya]
    py = [p[1] for p in path_ignis_raya]
    ax_map.plot(px, py, color="#00e676", linewidth=2.8, linestyle="--", alpha=0.9,
                label=f"Jalur Utama Aman ($s_3$, Detour Flank): ~{len(path_ignis_raya)} steps (100% Aman, Living Cost -2)")
    for i in range(5, len(path_ignis_raya) - 5, 8):
        ax_map.annotate("", xy=(px[i+2], py[i+2]), xytext=(px[i], py[i]),
                        arrowprops=dict(arrowstyle="->", color="#69f0ae", lw=1.8))

# Sensory Telegraph Warning Radii
warning_zone_w = patches.Rectangle((7.0, 19.5), 14.0, 2.0, fill=True,
                                   facecolor="#ff9100", alpha=0.22, edgecolor="#ffab40", linewidth=1.5, linestyle=":")
ax_map.add_patch(warning_zone_w)
ax_map.text(14.0, 24.5, "Sensor Telegraph Warning Area\nP(W=1|Hazard) = 0.90\nBayes Update $f = 0.10 \\to 0.50$\nPolicy Shift: Pintas $\\to$ Raya",
            color="#ffe0b2", fontsize=7.8, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.35", facecolor="#261608", edgecolor="#ff9100", alpha=0.9))

warning_zone_e = patches.Rectangle((23.0, 19.5), 14.0, 2.0, fill=True,
                                   facecolor="#ff9100", alpha=0.22, edgecolor="#ffab40", linewidth=1.5, linestyle=":")
ax_map.add_patch(warning_zone_e)
ax_map.text(30.0, 24.5, "Sensor Telegraph Warning Area\nP(W=1|Hazard) = 0.90\nBayes Update $f = 0.10 \\to 0.50$\nPolicy Shift: Pintas $\\to$ Raya",
            color="#ffe0b2", fontsize=7.8, fontweight="bold", ha="center",
            bbox=dict(boxstyle="round,pad=0.35", facecolor="#261608", edgecolor="#ff9100", alpha=0.9))

# Flank Path Annotations
ax_map.text(5.5, 28.5, "Flank 'a'\n(Safe)", color="#a7ffeb", fontsize=7.5, fontweight="bold", ha="center", rotation=90)
ax_map.text(37.5, 28.5, "Flank 'a'\n(Safe)", color="#a7ffeb", fontsize=7.5, fontweight="bold", ha="center", rotation=90)
ax_map.text(21.5, 28.5, "Central Avenue\n(Safe Highway)", color="#a7ffeb", fontsize=7.5, fontweight="bold", ha="center", rotation=90)

# Axes Labels & Ticks
ax_map.set_xticks(range(0, WIDTH, 4))
ax_map.set_yticks(range(0, HEIGHT, 4))
ax_map.set_xticklabels(range(0, WIDTH, 4), color="#b0bec5", fontsize=7.5)
ax_map.set_yticklabels(range(0, HEIGHT, 4), color="#b0bec5", fontsize=7.5)
ax_map.grid(color="#1a1624", linestyle=":", linewidth=0.5)
ax_map.set_title("TOPOLOGI PETA 2D ARENA: TAHAP 4 (44 x 46 TILES)\nKeputusan di Bawah Ketidakpastian & Markov Decision Processes (MDP)",
                 color="#ffffff", fontsize=11, fontweight="bold", pad=12)

# Legend on Map
leg = ax_map.legend(loc="lower left", fontsize=8, facecolor="#181324", edgecolor="#7c4dff", labelcolor="#e0e0e0")

# =========================================================================
# RIGHT PANEL: Mathematical & Algorithmic Specifications (Mengacu PDF 09)
# =========================================================================
ax_info.set_facecolor("#100b1a")
ax_info.axis("off")

info_text = """
===================================================================
  RANCANGAN MATEMATIS TAHAP 4: KEPUTUSAN DI BAWAH KETIDAKPASTIAN
  Mengacu: 09_Decision under uncertainity.pdf & PLAN_TAHAP_4.md
===================================================================

1. FORMULASI MARKOV DECISION PROCESS (MDP)
   Formal Tuple: < S, A, P, R, γ >
   • State Space (S):
     - s0: Altar (Titik Panen: Ignis, Abyssal, Sanguine)
     - s1: Simpang Lembah (Titik Keputusan Bifurkasi)
     - s2: Jalur Pintas (Jembatan 'd', Bahaya Magma Stokastik)
     - s3: Jalur Utama (Detour Flank Aman, 100% Bebas Lahar)
     - s4: Pos Penjaga (Terminal Goal: Delivery Berhasil)
     - s5: Magma Trap (Terminal Fail: Terbakar & Kristal Hangus)
   • Action Space (A):
     - a_Pintas : Melintasi jembatan retakan magma (Cepat, Risiko f)
     - a_Raya   : Mengambil jalan aman memutar selatan (Lambat, Aman)
     - a_Wait   : Diam di petak aman menunggu semburan padam
     - a_Balik  : Mundur kembali ke Altar
   • Reward Function (R):
     - R(Goal s4)       = +10.0 (Reward Pengiriman Sukses)
     - R(Fail s5)       = -20.0 (Penalti Keranjang Terbakar)
     - R(Step Non-term) =  -2.0 (Living Cost agar efisien, Slide 23)
   • Discount Factor (γ)  = 0.80 (Preferensi waktu pengiriman cepat)

-------------------------------------------------------------------
2. ATURAN BAYES (BAYESIAN BELIEF UPDATING)
   • Prior Belief      : P(Hazard) = 0.10,  P(Safe) = 0.90
   • Sensor Likelihood : P(W | Hazard) = 0.90, P(W | Safe) = 0.10
   • Total Evidence P(W):
     P(W) = (0.90 × 0.10) + (0.10 × 0.90) = 0.09 + 0.09 = 0.18
   • Posterior Belief (Saat Sinyal Sensor W Aktif / Asap Magma):
     P(Hazard | W) = (P(W | Hazard) × P(Hazard)) / P(W)
                   = (0.90 × 0.10) / 0.18 = 0.50 (50% Bahaya!)

-------------------------------------------------------------------
3. VALUE ITERATION & POLICY SHIFT (BELLMAN EQUATION)
   Q(s, a) = ∑ P(s'|s,a) [ R(s') + γ V(s') ]
   V(s)    = max_a Q(s, a)

   A. KONDISI NORMAL (f = 0.10, Tanpa Sinyal Bahaya):
      • Q(s1, a_Pintas) = 0.90(+10) + 0.10(-20) = 9.0 - 2.0 = +7.0
      • Q(s1, a_Raya)   = -2.0 + 0.80(10.0) = +6.0
      >>> PILIHAN OPTIMAL: π*(s1) = a_Pintas (7.0 > 6.0)

   B. KONDISI WASPADA (f = 0.50, Retakan Berasap / Sinyal W):
      • Q(s1, a_Pintas) = 0.50(+10) + 0.50(-20) = 5.0 - 10.0 = -5.0
      • Q(s1, a_Raya)   = -2.0 + 0.80(10.0) = +6.0
      >>> PERGESERAN KEBIJAKAN (POLICY SHIFT):
          π*(s1) BERUBAH DARI a_Pintas KE a_Raya (-5.0 < 6.0)!

-------------------------------------------------------------------
4. SIKLUS RINTANGAN MAGMA SEMI-STOKASTIK (JEMBATAN 'd')
   • Fase 1 - Dormant  (3.5 - 5.0s): Basalt dingin aman.
   • Fase 2 - Warning  (1.8s)      : Retakan oranye + asap sulfur (W=1).
   • Fase 3 - Eruption (1.6s)      : Pilar api lethal (-12 HP Player /
                                     Kristal Minion tumpah & mundur).

-------------------------------------------------------------------
5. PERBANDINGAN TAHAP 4A (PLAN) vs TAHAP 4B (POLICY):
   • Classical Plan (STRIPS): [Move -> Harvest -> Move -> Deliver]
     -> Kaku, gagal total saat rintangan dinamis muncul.
   • MDP Policy (π: S -> A):
     -> Fleksibel, langsung re-evaluasi saat ada asap/ancaman musuh.
===================================================================
"""

ax_info.text(0.01, 0.98, info_text, transform=ax_info.transAxes,
             fontsize=7.8, family="monospace", color="#eceff1",
             verticalalignment="top",
             bbox=dict(boxstyle="round,pad=0.6", facecolor="#171122", edgecolor="#7c4dff", alpha=0.92))

out_dir1 = "D:/Tugas/KULIAH/SEMESTER 3/Kecerdasan Buatan/Tugas/tubes/infernal-affairs/laporan_assets"
out_dir2 = "D:/Tugas/KULIAH/SEMESTER 3/Kecerdasan Buatan/Tugas/tubes/hell-pathfinder/laporan_assets"
artifact_dir = "C:/Users/MyBook Hype AMD/.gemini/antigravity/brain/07868943-55b7-4b4c-ab20-c1b7547b1bbf"

os.makedirs(out_dir1, exist_ok=True)
os.makedirs(out_dir2, exist_ok=True)
os.makedirs(artifact_dir, exist_ok=True)

out_file1 = os.path.join(out_dir1, "peta_2d_tahap_4_mdp.png")
out_file2 = os.path.join(out_dir2, "peta_2d_tahap_4_mdp.png")
out_artifact = os.path.join(artifact_dir, "peta_2d_tahap_4_mdp.png")

plt.subplots_adjust(left=0.04, right=0.98, top=0.95, bottom=0.05)
plt.savefig(out_file1, dpi=200, bbox_inches="tight")
plt.savefig(out_file2, dpi=200, bbox_inches="tight")
plt.savefig(out_artifact, dpi=200, bbox_inches="tight")
plt.close()

print("Regenerated 2D Map Tahap 4 with clean non-overlapping typography!")
