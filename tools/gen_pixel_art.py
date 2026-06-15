#!/usr/bin/env python3
"""Sci‑fi pixel art generator for PlaneShooter.
Overwrites sprites in ../assets/art with neon/tech palettes and crisper silhouettes.
All sizes and filenames stay compatible with the current scenes.
"""
from PIL import Image
import os, math, random

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "art")
os.makedirs(OUT, exist_ok=True)

TRANSPARENT = (0, 0, 0, 0)

def grid(w, h):
    return [[TRANSPARENT for _ in range(w)] for _ in range(h)]

def mirror_x(px):
    h = len(px); w = len(px[0])
    for y in range(h):
        for x in range(w // 2):
            px[y][w - 1 - x] = px[y][x]
    return px

def to_image(px, scale):
    h = len(px); w = len(px[0])
    img = Image.new("RGBA", (w, h), TRANSPARENT)
    for y in range(h):
        for x in range(w):
            img.putpixel((x, y), px[y][x])
    return img.resize((w * scale, h * scale), Image.NEAREST)

def save(px, name, scale):
    to_image(px, scale).save(os.path.join(OUT, name))
    print("saved", name)

# ---------- Sci‑fi palette ----------
# Deep space metal + neon highlights
STEEL     = (82, 96, 122, 255)
STEEL_D   = (44, 54, 70, 255)
STEEL_L   = (132, 148, 176, 255)
NEON_CYAN = (0, 255, 230, 255)
CYAN      = (0, 200, 220, 255)
TEAL      = (0, 150, 170, 255)
NEON_PURP = (220, 120, 255, 255)
CORE_W    = (255, 252, 248, 255)
AMBER     = (255, 196, 64, 255)
SMOKE     = (90, 84, 94, 255)
STAR_A    = (170, 200, 255, 255)
STAR_B    = (120, 150, 220, 255)
STAR_C    = (210, 240, 255, 255)

# ============ PLAYER (18x18, forward/up) ============
# Angular delta‑wing hull with cyan canopy and twin engine glow.
def player_frame(flame_len):
    px = grid(18, 18)
    cx = 9
    # spine
    for y in range(2, 15):
        px[y][cx] = STEEL_L
    # canopy
    px[5][cx] = CYAN; px[6][cx] = CYAN
    # fuselage blocks
    for y in range(4, 13):
        for x in range(cx-1, cx+2):
            px[y][x] = STEEL
    # bevel edges
    for y in range(7, 13):
        px[y][cx-2] = STEEL_D; px[y][cx+2] = STEEL_D
    # wings
    for dy, span in [(8,3),(9,4),(10,5),(11,4),(12,3)]:
        for x in range(cx-span, cx+span+1):
            px[dy][x] = STEEL_D if abs(x-cx) >= span-1 else STEEL
    # neon trims on wing roots
    px[9][cx-1] = NEON_CYAN; px[9][cx+1] = NEON_CYAN
    # ventral fin
    px[13][cx-1] = STEEL_D; px[13][cx] = STEEL; px[13][cx+1] = STEEL_D
    # engine flame (twin)
    for i in range(flame_len):
        y = 15 + i
        if y < 18:
            px[y][cx-1] = AMBER
            px[y][cx+1] = AMBER
            if i >= 1 and y < 18:
                px[y][cx-1] = (255, 140, 40, 255)
                px[y][cx+1] = (255, 140, 40, 255)
    return px

save(player_frame(1), "player_0.png", 6)
save(player_frame(2), "player_1.png", 6)

# ============ ENEMY DRONE (20x16, down) ============
# Compact tech drone with neon ring.
def enemy_frame():
    px = grid(20, 16)
    cx = 10
    # core body
    for y in range(3, 13):
        for x in range(cx-3, cx+4):
            px[y][x] = STEEL
    # side panels
    for y in range(5, 11):
        px[y][cx-4] = STEEL_D; px[y][cx+4] = STEEL_D
    # neon ring accents
    for ang in range(0, 360, 30):
        r = 4.5
        x = int(round(cx + r * math.cos(math.radians(ang))))
        y = int(round(8 + r * math.sin(math.radians(ang))))
        if 0 <= x < 20 and 0 <= y < 16:
            px[y][x] = NEON_PURP if ang % 60 else NEON_CYAN
    # eye visor
    for x in range(cx-2, cx+3):
        px[7][x] = CYAN
    # lower thrusters
    px[12][cx-1] = STEEL_D; px[12][cx+1] = STEEL_D
    return px

save(enemy_frame(), "enemy_0.png", 6)

# ============ PLAYER BULLET (4x8) ============
# Bright plasma bolt with white core, cyan edge.
def bullet():
    px = grid(4, 8)
    for y in range(0, 8):
        px[y][1] = CORE_W; px[y][2] = CORE_W
    for y in range(1, 7):
        px[y][0] = NEON_CYAN; px[y][3] = NEON_CYAN
    px[0][1] = STAR_C; px[0][2] = STAR_C
    return px

save(bullet(), "bullet.png", 6)

# ============ ENEMY BULLET (6x6) ============
# Magenta pulse sphere.
def enemy_bullet():
    px = grid(6, 6)
    cx, cy = 2.5, 2.5
    for y in range(6):
        for x in range(6):
            d = math.hypot(x - cx, y - cy)
            if d <= 1.1: px[y][x] = CORE_W
            elif d <= 2.1: px[y][x] = NEON_PURP
            elif d <= 2.7: px[y][x] = (160, 70, 200, 255)
    return px

save(enemy_bullet(), "enemy_bullet.png", 6)

# ============ EXPLOSION (20x20 x 7) ============
# Energy bloom: white core -> cyan halo -> smoke.
def explosion_frame(t):
    px = grid(20, 20)
    cx, cy = 9.5, 9.5
    random.seed(int(t * 9973) + 11)
    if t <= 0.5:
        g = t / 0.5
        radius = 2.0 + g * 8.0
        core_r = radius * 0.45
        halo_r = radius * 0.85
        for y in range(20):
            for x in range(20):
                d = math.hypot(x - cx, y - cy)
                if d <= core_r: px[y][x] = CORE_W
                elif d <= halo_r: px[y][x] = NEON_CYAN
                elif d <= radius: px[y][x] = CYAN
    else:
        g = (t - 0.5) / 0.5
        radius = 10.0 * (1.0 - g * 0.35)
        for y in range(20):
            for x in range(20):
                d = math.hypot(x - cx, y - cy)
                if d <= radius * (0.55 - 0.2 * g):
                    px[y][x] = CYAN if random.random() > g * 0.6 else CORE_W
                elif d <= radius:
                    if random.random() > 0.45 + g * 0.3:
                        px[y][x] = SMOKE
    return px

for i in range(7):
    save(explosion_frame((i + 0.5) / 7), f"explosion_{i}.png", 6)

# ============ BOSS BODY (48x32) ============
# Tank chassis with neon trims.
def boss_body():
    px = grid(48, 32)
    for y in range(6, 26):
        for x in range(6, 42):
            px[y][x] = STEEL
    # top/bottom panels
    for x in range(6, 42):
        px[6][x] = STEEL_L; px[7][x] = STEEL_L
        px[24][x] = STEEL_D; px[25][x] = STEEL_D
    # side armor
    for y in range(4, 28):
        for x in range(2, 6): px[y][x] = STEEL_D
        for x in range(42, 46): px[y][x] = STEEL_D
    # neon rails
    for x in range(10, 38):
        px[15][x] = NEON_CYAN
    for x in range(14, 34, 4):
        px[11][x] = NEON_PURP
    return px

save(boss_body(), "boss_body.png", 5)

# ============ BOSS GUNS ============
# Main: heavy emitter with neon core. Sub: lighter turrets.
def boss_main_gun():
    px = grid(16, 16)
    cx, cy = 7.5, 6
    for y in range(2, 11):
        for x in range(2, 14):
            d = math.hypot(x - cx, y - cy)
            if d <= 5.6: px[y][x] = STEEL
            if 4.8 < d <= 5.6: px[y][x] = STEEL_D
    # core glow
    px[6][7] = CORE_W; px[6][8] = NEON_CYAN
    for y in range(10, 16):
        px[y][7] = STEEL_D; px[y][8] = STEEL_D
    return px

save(boss_main_gun(), "boss_gun_main.png", 6)


def boss_sub_gun():
    px = grid(12, 12)
    cx, cy = 5.5, 5
    for y in range(1, 9):
        for x in range(1, 11):
            d = math.hypot(x - cx, y - cy)
            if d <= 4.3: px[y][x] = STEEL
            if 3.4 < d <= 4.3: px[y][x] = STEEL_D
    px[5][5] = NEON_PURP
    for y in range(8, 12):
        px[y][5] = STEEL_D; px[y][6] = STEEL_D
    return px

save(boss_sub_gun(), "boss_gun_sub.png", 6)

# ============ STARFIELD (64x64 tile) ============
# Dense blue‑white stars with a few bright flares.
def stars():
    random.seed(4242)
    px = grid(64, 64)
    # faint noise field
    for _ in range(220):
        x = random.randint(0, 63); y = random.randint(0, 63)
        b = random.choice([STAR_A, STAR_B])
        px[y][x] = b
    # bright stars
    for _ in range(26):
        x = random.randint(2, 61); y = random.randint(2, 61)
        px[y][x] = STAR_C
        px[y][x-1] = STAR_A; px[y][x+1] = STAR_A
        px[y-1][x] = STAR_A; px[y+1][x] = STAR_A
    return px

save(stars(), "stars.png", 4)
print("DONE")
