#!/usr/bin/env python3
"""
DailyPaper — Generate today's wallpaper.
Same seed for everyone, same wallpaper worldwide.
"""

from PIL import Image, ImageDraw, ImageFont
import numpy as np
import random
import os
import sys
from datetime import datetime, timezone


def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


# --- CURATED PALETTES: (top-left, bottom-right, text_mode) ---
PALETTES = [
    # Dark (white text)
    ("#0F2027", "#2C5364", "light"),
    ("#1A1A2E", "#16213E", "light"),
    ("#0F0C29", "#302B63", "light"),
    ("#232526", "#414345", "light"),
    ("#141E30", "#243B55", "light"),
    ("#0D1B2A", "#1B263B", "light"),
    ("#1A0A1E", "#8B2252", "light"),
    ("#1B1B2F", "#162447", "light"),
    ("#0B0B0F", "#1A1A2E", "light"),
    ("#200122", "#6F0000", "light"),
    ("#1F1C2C", "#928DAB", "light"),
    ("#2E1437", "#6B2D5B", "light"),
    ("#0A192F", "#172A45", "light"),
    ("#1B0A1A", "#3E1F47", "light"),
    ("#2A0A0A", "#5C1A1A", "light"),
    ("#0D0D0D", "#2A2A2A", "light"),
    ("#1A3C40", "#417D7A", "light"),
    ("#112D4E", "#3F72AF", "light"),
    ("#2C1810", "#5C3D2E", "light"),
    ("#1A0533", "#3B185F", "light"),
    ("#0E2431", "#1C4966", "light"),
    # Light (black text)
    ("#E0EAFC", "#CFDEF3", "dark"),
    ("#FDFCFB", "#E2D1C3", "dark"),
    ("#F5F7FA", "#C3CFE2", "dark"),
    ("#FFECD2", "#FCB69F", "dark"),
    ("#D4FC79", "#96E6A1", "dark"),
    ("#A1C4FD", "#C2E9FB", "dark"),
    ("#E8CBC0", "#636FA4", "dark"),
    ("#F3E7E9", "#E3EEFF", "dark"),
    ("#FDDB92", "#D1FDFF", "dark"),
    ("#C9D6FF", "#E2E2E2", "dark"),
    ("#F8CDDA", "#D5AED0", "dark"),
    ("#FDE1D4", "#F5C6AA", "dark"),
    ("#E6DADA", "#D4C4C4", "dark"),
    ("#F0E6EF", "#D4B5D0", "dark"),
]

# --- DAILY PHRASES ---
PHRASES = [
    "Create your future",
    "Stay sharp",
    "Trust the process",
    "One day at a time",
    "Keep moving forward",
    "Less talk, more work",
    "Make it count",
    "No shortcuts",
    "Build in silence",
    "Bet on yourself",
    "Earn it daily",
    "Show up anyway",
    "Discipline is freedom",
    "Start before you're ready",
    "Be the proof",
    "Grind now, shine later",
    "Do the hard thing",
    "Stay uncomfortable",
    "Prove them wrong",
    "Own your day",
    "Consistency wins",
    "Outwork everyone",
    "Never settle",
    "Think long term",
    "Raise your standards",
    "Execute, don't talk",
    "Small steps, big moves",
    "Protect your energy",
    "Embrace the struggle",
    "Today matters most",
    "Focus or fail",
]


def generate_wallpaper(width=3024, height=1964, output_path="wallpaper.png"):
    """Generate today's wallpaper. Deterministic: same date = same output worldwide."""

    # UTC date as seed — same for everyone on the planet
    today = datetime.now(timezone.utc)
    day_of_year = today.timetuple().tm_yday
    year = today.year
    seed = year * 1000 + day_of_year
    random.seed(seed)
    np.random.seed(seed)

    # Pick today's palette and phrase
    palette = random.choice(PALETTES)
    phrase = PHRASES[day_of_year % len(PHRASES)]

    top_color = hex_to_rgb(palette[0])
    bottom_color = hex_to_rgb(palette[1])
    text_mode = palette[2]

    # --- DIAGONAL GRADIENT (vectorized) ---
    y_coords = np.linspace(0, 1, height).reshape(-1, 1)
    x_coords = np.linspace(0, 1, width).reshape(1, -1)
    t = np.clip(x_coords * 0.4 + y_coords * 0.6, 0, 1)

    pixels = np.zeros((height, width, 3), dtype=np.uint8)
    for c in range(3):
        pixels[:, :, c] = (
            top_color[c] + (bottom_color[c] - top_color[c]) * t
        ).astype(np.uint8)

    img = Image.fromarray(pixels)

    # --- GRAIN TEXTURE ---
    grain = np.random.normal(0, 10, (height, width, 3)).astype(np.int16)
    img_array = np.array(img, dtype=np.int16)
    img_array = np.clip(img_array + grain, 0, 255).astype(np.uint8)
    img = Image.fromarray(img_array)

    # --- TYPOGRAPHY ---
    img = img.convert("RGBA")
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Find fonts (works both locally and in GitHub Actions)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    font_dir = os.path.join(script_dir, "fonts")
    font_black = os.path.join(font_dir, "Montserrat-Arabic-Black.ttf")
    font_medium = os.path.join(font_dir, "Montserrat-Arabic-Medium.ttf")

    font_month = ImageFont.truetype(font_black, int(width * 0.055))
    font_day = ImageFont.truetype(font_black, int(width * 0.14))
    font_phrase = ImageFont.truetype(font_medium, int(width * 0.014))

    if text_mode == "light":
        text_color = (255, 255, 255, 220)
        text_color_sub = (255, 255, 255, 130)
    else:
        text_color = (0, 0, 0, 200)
        text_color_sub = (0, 0, 0, 110)

    day = today.strftime("%d")
    month = today.strftime("%B")

    # MONTH — top left, below macOS widgets zone
    draw.text(
        (int(width * 0.05), int(height * 0.28)),
        month,
        font=font_month,
        fill=text_color,
    )

    # DAY — bottom right, massive
    day_bbox = draw.textbbox((0, 0), day, font=font_day)
    day_w = day_bbox[2] - day_bbox[0]
    day_h = day_bbox[3] - day_bbox[1]
    draw.text(
        (width - day_w - int(width * 0.05), height - day_h - int(height * 0.06)),
        day,
        font=font_day,
        fill=text_color,
    )

    # PHRASE — bottom left
    draw.text(
        (int(width * 0.05), height - int(height * 0.12)),
        phrase,
        font=font_phrase,
        fill=text_color_sub,
    )

    # Composite and save
    img = Image.alpha_composite(img, overlay)
    img = img.convert("RGB")
    img.save(output_path, "PNG", quality=95)

    print(f"[DailyPaper] Saved: {output_path}")
    print(f"[DailyPaper] {width}x{height} | {palette[0]} -> {palette[1]} | {day} {month} | \"{phrase}\"")


if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "wallpaper.png"
    generate_wallpaper(output_path=output)
