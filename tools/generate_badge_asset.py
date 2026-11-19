import zlib
import struct
import os

def write_png(filename, width, height, pixels):
    raw_data = bytearray()
    for row in pixels:
        raw_data.append(0)
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

def make_warning_badge(w=20, h=20):
    pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            # Triangle warning sign
            # Base width increases from top to bottom
            center_x = 10
            half_width = int(y * 0.55)
            if 3 <= y <= 17 and abs(x - center_x) <= half_width:
                # Inside triangle
                dist_to_edge = half_width - abs(x - center_x)
                if y == 17 or dist_to_edge == 0:
                    # Dark red/black outline
                    r, g, b, a = 120, 20, 20, 255
                elif (center_x - 1 <= x <= center_x) and (6 <= y <= 12):
                    # Exclamation mark stem
                    r, g, b, a = 30, 10, 10, 255
                elif (center_x - 1 <= x <= center_x) and (y == 14):
                    # Exclamation dot
                    r, g, b, a = 30, 10, 10, 255
                else:
                    # Bright amber/yellow fill
                    r, g, b, a = 255, 190, 20, 255
            else:
                r, g, b, a = 0, 0, 0, 0
            row.append((r, g, b, a))
        pixels.append(row)
    return pixels

if __name__ == "__main__":
    out_path = r"assets/sprites/ui/effects/alert_hazard.png"
    write_png(out_path, 20, 20, make_warning_badge())
    print("Warning badge generated successfully!")

