#!/usr/bin/env python3
"""程序化生成像素风飞机射击素材。街机像素风,小调色板,左右对称。
输出 PNG 到 ../assets/art/。每个 sprite 用整数像素放大(nearest)。"""
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

def C(r, g, b): return (r, g, b, 255)

BODY   = C(79, 195, 247); BODY_D = C(41, 121, 185)
COCK   = C(225, 245, 254); WING = C(129, 212, 250)
FLAME1 = C(255, 213, 79);  FLAME2 = C(255, 138, 101)

# PLACEHOLDER_PLAYER

# ============ 玩家机 (16x16, 机头朝上) ============
def player_frame(flame_len):
    px = grid(16, 16)
    for y in range(2, 14):
        px[y][7] = BODY; px[y][8] = BODY
    px[1][7] = BODY; px[1][8] = BODY
    for y in range(4, 12):
        px[y][6] = BODY_D; px[y][9] = BODY_D
    px[4][7] = COCK; px[4][8] = COCK; px[5][7] = COCK; px[5][8] = COCK
    for x in range(2, 7):
        px[9][x] = WING
    px[10][3] = WING; px[10][4] = WING; px[10][5] = WING; px[10][6] = WING
    px[8][5] = WING; px[8][6] = WING
    px[12][5] = BODY_D; px[12][10] = BODY_D
    px[13][6] = BODY_D; px[13][9] = BODY_D
    for i in range(flame_len):
        y = 14 + i
        if y < 16:
            px[y][7] = FLAME1; px[y][8] = FLAME1
        if i >= 1 and y < 16:
            px[y][7] = FLAME2; px[y][8] = FLAME2
    mirror_x(px)
    return px

save(player_frame(1), "player_0.png", 6)
save(player_frame(2), "player_1.png", 6)

# ============ 敌机 (18x16, 机头朝下, 敦实) ============
def enemy_frame():
    px = grid(18, 16)
    ER = C(229, 92, 92); ED = C(160, 50, 50); EW = C(255, 160, 120); EC = C(255, 224, 178)
    cx = 9
    for y in range(2, 13):
        for x in range(cx - 2, cx + 2):
            px[y][x] = ER
    px[13][cx-1] = ER; px[13][cx] = ER
    px[14][cx-1] = ER; px[14][cx] = ER
    for y in range(3, 12):
        px[y][cx - 3] = ED; px[y][cx + 2] = ED
    px[9][cx-1] = EC; px[9][cx] = EC; px[10][cx-1] = EC; px[10][cx] = EC
    for x in range(1, cx - 1):
        px[6][x] = EW
    for x in range(1, cx - 2):
        px[7][x] = EW
    px[5][3] = EW; px[5][4] = EW
    px[2][cx-3] = ED; px[2][cx+2] = ED
    px[3][cx-4] = ED; px[3][cx+3] = ED
    mirror_x(px)
    return px

save(enemy_frame(), "enemy_0.png", 6)

# ============ 玩家子弹 (4x8) ============
def bullet():
    px = grid(4, 8)
    Y = C(255, 241, 118); O = C(255, 167, 38)
    for y in range(0, 8):
        px[y][1] = Y; px[y][2] = Y
    px[0][1] = C(255,255,255); px[0][2] = C(255,255,255)
    px[6][1] = O; px[6][2] = O; px[7][1] = O; px[7][2] = O
    return px

save(bullet(), "bullet.png", 6)

# PLACEHOLDER_EXPLOSION

# ============ 爆炸序列帧 (20x20 x 7) 实心火球炸开→消散 ============
def explosion_frame(t):
    px = grid(20, 20)
    cx, cy = 9.5, 9.5
    random.seed(int(t * 1000) + 7)
    WHITE = C(255, 250, 230); Y = C(255, 238, 150)
    O = C(255, 150, 55); R = C(225, 70, 45); SMOKE = C(95, 78, 72)
    if t <= 0.5:
        g = t / 0.5
        radius = 2.0 + g * 7.5
        white_r = radius * 0.35; yellow_r = radius * 0.62; orange_r = radius * 0.85
        for y in range(20):
            for x in range(20):
                d = math.hypot(x - cx, y - cy)
                if d <= white_r: px[y][x] = WHITE
                elif d <= yellow_r: px[y][x] = Y
                elif d <= orange_r: px[y][x] = O
                elif d <= radius: px[y][x] = R
    else:
        g = (t - 0.5) / 0.5
        radius = 9.5 * (1.0 - g * 0.25)
        core_r = max(0.0, (1.0 - g) * 4.5)
        for y in range(20):
            for x in range(20):
                d = math.hypot(x - cx, y - cy)
                if d <= core_r:
                    px[y][x] = O if g < 0.6 else R
                elif d <= radius * 0.7:
                    px[y][x] = R if random.random() > g * 0.7 else SMOKE
                elif d <= radius:
                    if random.random() > 0.35 + g * 0.4:
                        px[y][x] = SMOKE
    return px

N = 7
for i in range(N):
    save(explosion_frame((i + 0.5) / N), f"explosion_{i}.png", 6)

def enemy_bullet():
    px = grid(6, 6)
    R = C(255, 80, 80); O = C(255, 150, 90); W = C(255, 230, 200)
    cx, cy = 2.5, 2.5
    for y in range(6):
        for x in range(6):
            d = math.hypot(x - cx, y - cy)
            if d <= 1.2: px[y][x] = W
            elif d <= 2.0: px[y][x] = O
            elif d <= 2.8: px[y][x] = R
    return px

save(enemy_bullet(), "enemy_bullet.png", 6)

def boss_body():
    px = grid(48, 32)
    STEEL = C(96, 110, 130); STEEL_D = C(60, 72, 90); STEEL_L = C(140, 155, 175); TRIM = C(229, 92, 92)
    for y in range(6, 26):
        for x in range(6, 42):
            px[y][x] = STEEL
    for x in range(6, 42):
        px[6][x] = STEEL_L; px[7][x] = STEEL_L
        px[24][x] = STEEL_D; px[25][x] = STEEL_D
    for y in range(4, 28):
        for x in range(2, 6): px[y][x] = STEEL_D
        for x in range(42, 46): px[y][x] = STEEL_D
    for y in range(5, 27, 3):
        for x in range(2, 6): px[y][x] = C(40,48,60)
        for x in range(42, 46): px[y][x] = C(40,48,60)
    for x in range(10, 38):
        px[15][x] = TRIM
    for x in range(20, 28):
        px[26][x] = STEEL_D; px[27][x] = STEEL_D
    return px

save(boss_body(), "boss_body.png", 5)

def boss_main_gun():
    px = grid(16, 16)
    M = C(180, 70, 70); MD = C(120, 40, 40); ML = C(220, 110, 110)
    cx, cy = 7.5, 6
    for y in range(2, 11):
        for x in range(2, 14):
            d = math.hypot(x - cx, y - cy)
            if d <= 5.5: px[y][x] = M
            if d <= 5.5 and y < cy: px[y][x] = ML
    for y in range(2,11):
        for x in range(2,14):
            d = math.hypot(x-cx,y-cy)
            if 4.6 < d <= 5.5: px[y][x] = MD
    for y in range(10, 16):
        px[y][7] = MD; px[y][8] = MD; px[y][6] = M; px[y][9] = M
    return px

save(boss_main_gun(), "boss_gun_main.png", 6)

def boss_sub_gun():
    px = grid(12, 12)
    M = C(200, 110, 90); MD = C(140, 60, 50); ML = C(235, 150, 120)
    cx, cy = 5.5, 5
    for y in range(1, 9):
        for x in range(1, 11):
            d = math.hypot(x - cx, y - cy)
            if d <= 4.2: px[y][x] = M
            if d <= 4.2 and y < cy: px[y][x] = ML
            if 3.4 < d <= 4.2: px[y][x] = MD
    for y in range(8, 12):
        px[y][5] = MD; px[y][6] = MD
    return px

save(boss_sub_gun(), "boss_gun_sub.png", 6)

def stars():
    random.seed(42)
    px = grid(64, 64)
    for _ in range(40):
        x = random.randint(0, 63); y = random.randint(0, 63)
        b = random.choice([120, 160, 200, 255])
        px[y][x] = C(b, b, min(255, b + 20))
    for _ in range(6):
        x = random.randint(1, 62); y = random.randint(1, 62)
        px[y][x] = C(255,255,255)
        px[y][x-1] = C(180,190,210); px[y][x+1] = C(180,190,210)
        px[y-1][x] = C(180,190,210); px[y+1][x] = C(180,190,210)
    return px

save(stars(), "stars.png", 4)
print("DONE")
