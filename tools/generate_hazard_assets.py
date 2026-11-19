import zlib
import struct
import math
import random
import os

def write_png(filename, width, height, pixels):
    """
    pixels is a list of rows, where each row is a list of (r, g, b, a) tuples.
    """
    raw_data = bytearray()
    for row in pixels:
        raw_data.append(0)  # filter type 0 (None)
        for r, g, b, a in row:
            raw_data.extend((r, g, b, a))

    def chunk(chunk_type, data):
        return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xffffffff)

    png = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png += chunk(b"IHDR", ihdr_data)
    png += chunk(b"IDAT", zlib.compress(bytes(raw_data), 9))
    png += chunk(b"IEND", b"")

    with open(filename, "wb") as f:
        f.write(png)

def make_dormant(w=32, h=32):
    random.seed(42)
    pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            # Base dark volcanic basalt rock
            base = 28 + random.randint(-4, 5)
            r, g, b, a = base + 4, base - 2, base - 1, 255
            
            # Fissure crack shape: jagged path roughly from (6, 26) to (26, 6)
            center_x = 16 + int(6 * math.sin((y - 16) / 4.0)) + (1 if (y % 3 == 0) else -1)
            dist = abs(x - center_x)
            
            if dist <= 1:
                # Inside the dark dormant crack
                r, g, b = 45 + random.randint(0, 10), 12, 10
            elif dist == 2:
                # Fissure lip
                r, g, b = 22, 18, 18
            
            # Faint cooled ember spec
            if (x, y) in [(14, 15), (17, 10), (19, 21)]:
                r, g, b = 90, 25, 15

            row.append((r, g, b, a))
        pixels.append(row)
    return pixels

def make_warning(w=32, h=32):
    random.seed(42)
    pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            base = 28 + random.randint(-4, 4)
            r, g, b, a = base + 10, base, base - 4, 255
            
            center_x = 16 + int(6 * math.sin((y - 16) / 4.0)) + (1 if (y % 3 == 0) else -1)
            dist = abs(x - center_x)
            
            if dist == 0:
                # Molten core glow
                r, g, b = 255, 215, 60
            elif dist == 1:
                # Intense orange magma
                r, g, b = 255, 110, 20
            elif dist == 2:
                # Fiery rim
                r, g, b = 180, 50, 15
            elif dist <= 4:
                # Ambient heat glow
                heat = (5 - dist) * 15
                r = min(255, r + heat + 30)
                g = min(255, g + heat // 2)

            # Smoke/vapor wisps
            if y < 14 and abs(x - (16 + int(3 * math.sin(y * 0.8)))) <= 2:
                if (x + y) % 2 == 0:
                    r, g, b = min(255, r + 40), min(255, g + 30), min(255, b + 30)

            row.append((r, g, b, a))
        pixels.append(row)
    return pixels

def make_eruption(w=32, h=32):
    random.seed(99)
    pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            center_x = 16 + int(2 * math.sin(y * 0.5))
            dist = abs(x - center_x)
            
            # Vertical column of fire and magma fountain
            if dist <= 2:
                # Blazing white-yellow heart
                intensity = 255 - int(y * 1.5)
                r, g, b = 255, max(180, intensity), max(60, intensity // 2)
            elif dist <= 5:
                # Roaring fire burst
                r, g, b = 255, 100 + random.randint(-15, 20), 10
            elif dist <= 9:
                # Outer flame turbulence
                if random.random() > (dist - 5) / 5.0:
                    r, g, b = 220, 45 + random.randint(0, 20), 5
                else:
                    r, g, b = 60, 25, 20
            else:
                # Dark ground with scorching heat
                r, g, b = 35 + random.randint(0, 10), 15, 12
            
            # Spattering sparks
            if random.random() < 0.04 and y < 20:
                r, g, b = 255, 240, 120

            row.append((min(255, r), min(255, g), min(255, b), 255))
        pixels.append(row)
    return pixels

if __name__ == "__main__":
    out_dir = r"assets/sprites/map/hazards"
    os.makedirs(out_dir, exist_ok=True)
    
    write_png(os.path.join(out_dir, "fissure_dormant.png"), 32, 32, make_dormant())
    write_png(os.path.join(out_dir, "fissure_warning.png"), 32, 32, make_warning())
    write_png(os.path.join(out_dir, "fissure_eruption.png"), 32, 32, make_eruption())
    print("Hazard textures generated successfully!")

