#!/usr/bin/env python3
"""Génère AppIcon.appiconset pour CarenceScan — fond sauge + feuille blanche."""
from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / "CarenceScan" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

BG_R, BG_G, BG_B = 74, 124, 89
LEAF_R, LEAF_G, LEAF_B = 255, 255, 255

ICONS: list[tuple[str, int, str, str, str]] = [
    ("Icon-40.png", 40, "iphone", "20x20", "2x"),
    ("Icon-60.png", 60, "iphone", "20x20", "3x"),
    ("Icon-58.png", 58, "iphone", "29x29", "2x"),
    ("Icon-87.png", 87, "iphone", "29x29", "3x"),
    ("Icon-80.png", 80, "iphone", "40x40", "2x"),
    ("Icon-120-40.png", 120, "iphone", "40x40", "3x"),
    ("Icon-120.png", 120, "iphone", "60x60", "2x"),
    ("Icon-180.png", 180, "iphone", "60x60", "3x"),
    ("Icon-1024.png", 1024, "ios-marketing", "1024x1024", "1x"),
]


def _chunk(tag: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + tag
        + payload
        + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
    )


def rgba_png(size: int, pixels: bytes) -> bytes:
    rows = b"".join(b"\x00" + pixels[y * size * 3 : (y + 1) * size * 3] for y in range(size))
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(rows, 9))
        + _chunk(b"IEND", b"")
    )


def draw_icon(size: int) -> bytes:
    cx, cy = size / 2, size / 2
    r = size * 0.38
    pixels = bytearray(size * size * 3)
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            i = (y * size + x) * 3
            if dist <= r:
                pixels[i : i + 3] = (LEAF_R, LEAF_G, LEAF_B)
            else:
                pixels[i : i + 3] = (BG_R, BG_G, BG_B)
    return bytes(pixels)


def main() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    images = []
    for filename, px, idiom, size_str, scale in ICONS:
        path = ICONSET / filename
        path.write_bytes(rgba_png(px, draw_icon(px)))
        images.append({
            "filename": filename,
            "idiom": idiom,
            "scale": scale,
            "size": size_str,
        })
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
    print(f"✓ Icônes CarenceScan → {ICONSET}")


if __name__ == "__main__":
    main()
