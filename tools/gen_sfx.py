#!/usr/bin/env python3
"""程序化合成像素风音效 → ../assets/sfx/*.wav (16-bit PCM, 22050Hz, 单声道)。
不依赖任何外部音频资源。"""
import os, wave, struct, math, random

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
os.makedirs(OUT, exist_ok=True)
SR = 22050

def write_wav(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        w.writeframes(frames)
    print("saved", name, f"({len(samples)} samples)")

def env(i, n, attack=0.01, release=0.3):
    """简单 AD 包络。"""
    a = int(n * attack); r = int(n * release)
    if i < a: return i / max(1, a)
    if i > n - r: return max(0.0, (n - i) / max(1, r))
    return 1.0

# ---- 玩家射击:短促下滑方波 ----
def shoot():
    n = int(SR * 0.10); out = []
    for i in range(n):
        t = i / SR
        f = 880 - 400 * (i / n)
        s = 0.3 * (1 if math.sin(2*math.pi*f*t) > 0 else -1)
        out.append(s * env(i, n, 0.005, 0.6))
    return out

# ---- 爆炸:白噪声经下降包络 + 低频轰 ----
def explosion():
    n = int(SR * 0.45); out = []
    for i in range(n):
        t = i / SR
        noise = random.uniform(-1, 1)
        rumble = math.sin(2*math.pi*60*t) * 0.5
        e = env(i, n, 0.002, 0.85)
        out.append((noise * 0.6 + rumble) * e * 0.7)
    return out

# ---- 玩家受击:刺耳方波短鸣 ----
def hit():
    n = int(SR * 0.18); out = []
    for i in range(n):
        t = i / SR
        f = 220 + 60 * math.sin(2*math.pi*30*t)
        s = 0.35 * (1 if math.sin(2*math.pi*f*t) > 0 else -1)
        out.append(s * env(i, n, 0.005, 0.5))
    return out

# ---- 通关胜利:三音上行琶音 ----
def victory():
    notes = [523, 659, 784, 1047]  # C E G C
    out = []
    for f in notes:
        n = int(SR * 0.16)
        for i in range(n):
            t = i / SR
            s = 0.3 * math.sin(2*math.pi*f*t)
            s += 0.15 * math.sin(2*math.pi*f*2*t)
            out.append(s * env(i, n, 0.01, 0.4))
    return out

write_wav("shoot.wav", shoot())
write_wav("explosion.wav", explosion())
write_wav("hit.wav", hit())
write_wav("victory.wav", victory())
print("DONE")
