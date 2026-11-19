import re
from collections import deque

WIDTH = 44
HEIGHT = 46
TileType = {
    "GROUND": 0,
    "OBSTACLE": 1,
    "LAVA": 2,
    "BRIDGE": 3
}

# Simulate GridManager logic
grid = [[TileType["GROUND"] for _ in range(WIDTH)] for _ in range(HEIGHT)]

# Outer walls
for x in range(WIDTH):
    grid[0][x] = TileType["OBSTACLE"]
    grid[HEIGHT - 1][x] = TileType["OBSTACLE"]
for y in range(HEIGHT):
    grid[y][0] = TileType["OBSTACLE"]
    grid[y][WIDTH - 1] = TileType["OBSTACLE"]

# Castle front wall at y = 17..18
CENTER_X = 21
COURTYARD_Y = 19
for y in [17, 18]:
    for x in range(1, WIDTH - 1):
        if x != CENTER_X and x != CENTER_X + 1:
            grid[y][x] = TileType["OBSTACLE"]

# Castle wall foot at y = 19
for x in range(1, WIDTH - 1):
    if x != CENTER_X and x != CENTER_X + 1:
        if x != 5 and x != 6 and x != 37 and x != 38:
            grid[COURTYARD_Y][x] = TileType["OBSTACLE"]

# Lava basins
# 1. Outer West Lava: x = 1..4, y = 20..34
for y in range(20, 35):
    for x in range(1, 5):
        grid[y][x] = TileType["LAVA"]

# 2. Inner West Lava Basin: x = 7..20, y = 20..34
for y in range(20, 35):
    for x in range(7, 21):
        grid[y][x] = TileType["LAVA"]

# 3. Inner East Lava Basin: x = 23..36, y = 20..34
for y in range(20, 35):
    for x in range(23, 37):
        grid[y][x] = TileType["LAVA"]

# 4. Outer East Lava: x = 39..42, y = 20..34
for y in range(20, 35):
    for x in range(39, WIDTH - 1):
        grid[y][x] = TileType["LAVA"]

# Clear Safe Paths 'a', Central High Road, and Ground 'c'
for y in range(20, 35):
    for x in [5, 6]:
        grid[y][x] = TileType["GROUND"]

for y in range(COURTYARD_Y, 35):
    for x in [21, 22]:
        grid[y][x] = TileType["GROUND"]

for y in range(20, 35):
    for x in [37, 38]:
        grid[y][x] = TileType["GROUND"]

for y in range(35, HEIGHT - 1):
    for x in range(1, WIDTH - 1):
        grid[y][x] = TileType["GROUND"]

# Bridges 'd'
for dy in range(2):
    for dx in range(14):
        # Bridge Left 'd'
        grid[20 + dy][7 + dx] = TileType["BRIDGE"]
        # Bridge Right 'd'
        grid[20 + dy][23 + dx] = TileType["BRIDGE"]

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

# Test Points
altar_1 = (5, 21)
altar_2 = (38, 21)
altar_3 = (21, 38)
guard = (21, 19)

print("--- Testing Map Connectivity & Paths ---")

# 1. Altar 1 via Bridge 'd' (Pintas)
path_a1_pintas = bfs(altar_1, guard, allow_bridges=True)
assert path_a1_pintas is not None, "Altar 1 to Guard via bridge failed!"
print(f"Altar 1 (Ignis) -> Guard via Bridge 'd' length: {len(path_a1_pintas)} steps.")
assert any(grid[y][x] == TileType["BRIDGE"] for x, y in path_a1_pintas), "Must cross bridge!"

# 2. Altar 1 via Path 'a' -> Ground 'c' -> Center Road (Raya - NO BRIDGES)
path_a1_raya = bfs(altar_1, guard, allow_bridges=False)
assert path_a1_raya is not None, "Altar 1 to Guard via detour failed!"
print(f"Altar 1 (Ignis) -> Guard via Safe Detour (a -> c -> center) length: {len(path_a1_raya)} steps.")
assert not any(grid[y][x] == TileType["BRIDGE"] for x, y in path_a1_raya), "Detour must NOT cross bridge!"

# 3. Altar 2 via Bridge 'd' (Pintas)
path_a2_pintas = bfs(altar_2, guard, allow_bridges=True)
assert path_a2_pintas is not None, "Altar 2 to Guard via bridge failed!"
print(f"Altar 2 (Shadow) -> Guard via Bridge 'd' length: {len(path_a2_pintas)} steps.")

# 4. Altar 2 via Path 'a' -> Ground 'c' -> Center Road (Raya - NO BRIDGES)
path_a2_raya = bfs(altar_2, guard, allow_bridges=False)
assert path_a2_raya is not None, "Altar 2 to Guard via detour failed!"
print(f"Altar 2 (Shadow) -> Guard via Safe Detour (a -> c -> center) length: {len(path_a2_raya)} steps.")

# 5. Altar 3 (Blood / Sanguine Well) to Guard (Center Road)
path_a3 = bfs(altar_3, guard, allow_bridges=False)
assert path_a3 is not None, "Altar 3 to Guard failed!"
print(f"Altar 3 (Sanguine) -> Guard via Center Road length: {len(path_a3)} steps.")

print("ALL TOPOLOGY AND PATH TESTS PASSED PERFECTLY!")
