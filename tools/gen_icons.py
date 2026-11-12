#!/usr/bin/env python3
"""
Rage Hub icon source of truth.

Icons are drawn on a 24x24 grid out of a tiny shape language (Lucide/Feather
style outline icons). The Lua library re-draws them with plain Frames: no asset
ids, no emoji, crisp at any size and tintable.

Shapes
  L x1 y1 x2 y2          line
  P x1 y1 x2 y2 ...      polyline
  C cx cy r              ring (outline)
  D cx cy r              filled dot
  R x y w h rad          rounded rectangle outline
  F x y w h rad          filled rounded rectangle

Run:  python3 tools/gen_icons.py
Out:  src/icons.lua  assets/icons-preview.png  assets/logo.svg  assets/logo.png  ICONS.md
"""
import math, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def L(*a): return ["L", *a]
def P(*a): return ["P", *a]
def C(x, y, r): return ["C", x, y, r]
def D(x, y, r=1.2): return ["D", x, y, r]
def R(x, y, w, h, r=2): return ["R", x, y, w, h, r]
def F(x, y, w, h, r=1): return ["F", x, y, w, h, r]

def A(cx, cy, r, a1, a2):
    n = max(2, math.ceil(abs(a2 - a1) / 25))
    pts = ["P"]
    for i in range(n + 1):
        a = math.radians(a1 + (a2 - a1) * i / n)
        pts += [cx + r * math.cos(a), cy + r * math.sin(a)]
    return pts

def spokes(cx, cy, r1, r2, n, off=0):
    out = []
    for i in range(n):
        a = math.radians(off + i * 360 / n)
        out.append(L(cx + r1 * math.cos(a), cy + r1 * math.sin(a),
                     cx + r2 * math.cos(a), cy + r2 * math.sin(a)))
    return out

def icon(*parts):
    out = []
    for p in parts:
        if p and isinstance(p[0], str):
            out.append(p)
        else:
            out.extend(p)
    return out

def egg():
    pts = ["P"]
    for i in range(0, 25):
        t = math.radians(i * 15)
        w = 7.2 * (1 - 0.17 * math.cos(t))
        pts += [12 + w * math.sin(t), 12.3 - 9.4 * math.cos(t)]
    return pts

HEX = P(12, 2.5, 20.5, 7.25, 20.5, 16.75, 12, 21.5, 3.5, 16.75, 3.5, 7.25, 12, 2.5)

ICONS = {
    # ---------- navigation / ui ----------
    "home": icon(P(3, 11, 12, 3, 21, 11), P(5, 9.5, 5, 20, 19, 20, 19, 9.5), P(10, 20, 10, 14, 14, 14, 14, 20)),
    "settings": icon(C(12, 12, 3), C(12, 12, 6.6), spokes(12, 12, 6.6, 9.8, 8)),
    "sliders": icon(L(4, 6, 20, 6), L(4, 12, 20, 12), L(4, 18, 20, 18), D(9, 6, 2.4), D(15, 12, 2.4), D(8, 18, 2.4)),
    "menu": icon(L(4, 6, 20, 6), L(4, 12, 20, 12), L(4, 18, 20, 18)),
    "more": icon(D(5, 12, 1.8), D(12, 12, 1.8), D(19, 12, 1.8)),
    "list": icon(L(8, 6, 21, 6), L(8, 12, 21, 12), L(8, 18, 21, 18), D(4, 6), D(4, 12), D(4, 18)),
    "grid": icon(R(3, 3, 7.5, 7.5, 2), R(13.5, 3, 7.5, 7.5, 2), R(3, 13.5, 7.5, 7.5, 2), R(13.5, 13.5, 7.5, 7.5, 2)),
    "layers": icon(P(12, 3, 21.5, 8, 12, 13, 2.5, 8, 12, 3), P(2.5, 12.5, 12, 17.5, 21.5, 12.5), P(2.5, 16.5, 12, 21.5, 21.5, 16.5)),
    "search": icon(C(10.5, 10.5, 7), L(15.5, 15.5, 21, 21)),
    "filter": icon(P(3, 4.5, 21, 4.5, 14, 12.5, 14, 19.5, 10, 21.5, 10, 12.5, 3, 4.5)),
    "toggle": icon(R(2, 7, 20, 10, 5), D(16, 12, 3)),
    "check": icon(P(4, 12.5, 9.5, 18, 20, 6.5)),
    "x": icon(L(5, 5, 19, 19), L(19, 5, 5, 19)),
    "plus": icon(L(12, 5, 12, 19), L(5, 12, 19, 12)),
    "minus": icon(L(5, 12, 19, 12)),
    "chevron-up": icon(P(6, 15, 12, 9, 18, 15)),
    "chevron-down": icon(P(6, 9, 12, 15, 18, 9)),
    "chevron-left": icon(P(15, 6, 9, 12, 15, 18)),
    "chevron-right": icon(P(9, 6, 15, 12, 9, 18)),
    "chevrons-up-down": icon(P(8, 9, 12, 5, 16, 9), P(8, 15, 12, 19, 16, 15)),
    "arrow-up": icon(L(12, 19, 12, 5), P(6, 11, 12, 5, 18, 11)),
    "arrow-down": icon(L(12, 5, 12, 19), P(6, 13, 12, 19, 18, 13)),
    "arrow-left": icon(L(19, 12, 5, 12), P(11, 6, 5, 12, 11, 18)),
    "arrow-right": icon(L(5, 12, 19, 12), P(13, 6, 19, 12, 13, 18)),
    "expand": icon(P(4, 9, 4, 4, 9, 4), P(15, 4, 20, 4, 20, 9), P(20, 15, 20, 20, 15, 20), P(9, 20, 4, 20, 4, 15)),
    "move": icon(L(12, 3, 12, 21), L(3, 12, 21, 12), P(9, 6, 12, 3, 15, 6), P(9, 18, 12, 21, 15, 18), P(6, 9, 3, 12, 6, 15), P(18, 9, 21, 12, 18, 15)),
    "resize": icon(L(21, 11, 11, 21), L(21, 17, 17, 21)),
    "info": icon(C(12, 12, 9.5), L(12, 11, 12, 16.5), D(12, 7.6, 1.2)),
    "warning": icon(P(12, 3, 22, 20.5, 2, 20.5, 12, 3), L(12, 9.5, 12, 14), D(12, 17.3, 1.1)),
    "help": icon(C(12, 12, 9.5), A(12, 9.8, 2.8, 180, 400), L(12, 12.4, 12, 14), D(12, 17.2, 1.1)),
    "circle-check": icon(C(12, 12, 9.5), P(8, 12, 11, 15, 16, 9)),
    "circle-x": icon(C(12, 12, 9.5), L(9, 9, 15, 15), L(15, 9, 9, 15)),
    "circle": icon(C(12, 12, 9)),
    "dot": icon(D(12, 12, 3)),
    "square": icon(R(4, 4, 16, 16, 3)),
    "hexagon": icon(HEX),
    "hash": icon(L(8.5, 3.5, 6.5, 20.5), L(17.5, 3.5, 15.5, 20.5), L(4, 9, 20, 9), L(3.5, 15.5, 19.5, 15.5)),
    "external-link": icon(P(14, 3, 21, 3, 21, 10), L(21, 3, 11, 13), P(18, 14, 18, 19, 16, 21, 5, 21, 3, 19, 3, 8, 5, 6, 10, 6)),

    # ---------- people / player ----------
    "user": icon(C(12, 8, 4), A(12, 21, 8, 180, 360)),
    "users": icon(C(9, 8, 3.5), A(9, 21, 6.5, 180, 360), C(17, 8.5, 3), A(17, 21, 4.8, 250, 360)),
    "user-circle": icon(C(12, 12, 9.5), C(12, 10, 3), A(12, 18.5, 6.5, 200, 340)),
    "walk": icon(C(12, 4.5, 2.3), L(12, 8, 12, 15), L(12, 15, 8, 21), L(12, 15, 16, 21), L(12, 10, 7.5, 13), L(12, 10, 16.5, 13)),
    "run": icon(C(15, 4.5, 2.3), P(13, 8.5, 10, 11, 7, 11.5), P(13, 8.5, 13, 13, 16.5, 15.5, 16.5, 20), P(13, 13, 9, 16, 8, 21), P(13.5, 10, 17, 10.5, 19, 13)),
    "jump": icon(C(12, 5, 2.3), L(12, 8.5, 12, 15), L(12, 15, 8.5, 20), L(12, 15, 15.5, 20), L(12, 10, 7, 6), L(12, 10, 17, 6)),
    "fly": icon(P(3, 16, 3.5, 10, 8, 5.5, 14, 5, 21, 8, 16, 9.5, 13, 13, 9.5, 17, 3, 16), L(6.5, 13, 12, 8.5)),
    "teleport": icon(L(3, 12, 13, 12), P(9, 8, 13, 12, 9, 16), A(17, 12, 6, -100, 100)),
    "eye": icon(P(2, 12, 6, 7.5, 12, 5.5, 18, 7.5, 22, 12, 18, 16.5, 12, 18.5, 6, 16.5, 2, 12), C(12, 12, 3)),
    "eye-off": icon(P(2, 12, 6, 7.5, 12, 5.5, 18, 7.5, 22, 12, 18, 16.5, 12, 18.5, 6, 16.5, 2, 12), C(12, 12, 3), L(4, 4, 20, 20)),
    "bot": icon(R(4, 8, 16, 12, 3.5), L(12, 4, 12, 8), D(12, 3.3, 1.3), D(9, 13.5, 1.5), D(15, 13.5, 1.5), L(9.5, 17, 14.5, 17)),

    # ---------- combat / game ----------
    "sword": icon(P(14.5, 17.5, 3, 6, 3, 3, 6, 3, 17.5, 14.5), L(13, 19, 19, 13), L(16, 16, 20, 20), L(19, 21, 21, 19)),
    "swords": icon(L(4, 4, 18, 18), L(20, 4, 6, 18), L(14, 18, 18, 14), L(6, 14, 10, 18)),
    "shield": icon(P(12, 2.5, 20, 5.5, 20, 12, 17.5, 17.5, 12, 21.5, 6.5, 17.5, 4, 12, 4, 5.5, 12, 2.5)),
    "shield-check": icon(P(12, 2.5, 20, 5.5, 20, 12, 17.5, 17.5, 12, 21.5, 6.5, 17.5, 4, 12, 4, 5.5, 12, 2.5), P(8.5, 12, 11, 14.5, 15.5, 9.5)),
    "target": icon(C(12, 12, 9), C(12, 12, 5), D(12, 12, 1.4)),
    "crosshair": icon(C(12, 12, 7), L(12, 2, 12, 7), L(12, 17, 12, 22), L(2, 12, 7, 12), L(17, 12, 22, 12)),
    "radar": icon(C(12, 12, 9.5), C(12, 12, 5.5), L(12, 12, 18, 6), D(12, 12, 1.3)),
    "skull": icon(P(4.5, 10, 6, 5, 12, 3, 18, 5, 19.5, 10, 17, 13.5, 17, 18.5, 7, 18.5, 7, 13.5, 4.5, 10), C(9, 11, 1.8), C(15, 11, 1.8), L(10, 15.5, 10, 18.5), L(14, 15.5, 14, 18.5)),
    "ghost": icon(P(5, 21, 5, 10, 7, 5, 12, 3, 17, 5, 19, 10, 19, 21, 16, 18, 13.5, 21, 10.5, 21, 8, 18, 5, 21), D(9.5, 10, 1.2), D(14.5, 10, 1.2)),
    "bomb": icon(C(11, 14, 7), L(15.5, 9, 19, 5.5), L(17, 3.5, 20.5, 7), D(20.5, 3.5, 1)),
    "trophy": icon(P(7, 3.5, 17, 3.5, 17, 9.5, 14.5, 13.5, 9.5, 13.5, 7, 9.5, 7, 3.5), P(7, 5.5, 4, 5.5, 4, 8, 7, 10), P(17, 5.5, 20, 5.5, 20, 8, 17, 10), L(12, 13.5, 12, 20.5), L(8, 20.5, 16, 20.5)),
    "crown": icon(P(3, 18, 3, 7, 8, 12, 12, 5, 16, 12, 21, 7, 21, 18, 3, 18), L(5, 21, 19, 21)),
    "gem": icon(P(6, 3.5, 18, 3.5, 22, 9.5, 12, 21, 2, 9.5, 6, 3.5), L(2, 9.5, 22, 9.5), P(9, 9.5, 12, 21, 15, 9.5), P(9, 9.5, 10.5, 3.5), P(15, 9.5, 13.5, 3.5)),
    "star": icon(P(12, 2.5, 14.9, 8.7, 21.7, 9.5, 16.6, 14.1, 18, 20.8, 12, 17.5, 6, 20.8, 7.4, 14.1, 2.3, 9.5, 9.1, 8.7, 12, 2.5)),
    "heart": icon(P(12, 20, 5, 13, 3.5, 9, 5, 5.5, 8.5, 4.5, 12, 7.5, 15.5, 4.5, 19, 5.5, 20.5, 9, 19, 13, 12, 20)),
    "zap": icon(P(13, 2, 4.5, 13.5, 11.5, 13.5, 10.5, 22, 19.5, 10, 12.5, 10, 13, 2)),
    "flame": icon(P(12, 2.5, 16.5, 8, 18, 13, 16, 18.5, 12, 21.5, 8, 18.5, 6, 13, 8.5, 9.5, 10.5, 11.5, 12, 2.5)),
    "rocket": icon(P(12, 2.5, 16.5, 6.5, 17, 12.5, 14.5, 16.5, 9.5, 16.5, 7, 12.5, 7.5, 6.5, 12, 2.5), C(12, 9.5, 1.8), P(7.5, 12.5, 4.5, 15, 5, 19, 9, 17), P(16.5, 12.5, 19.5, 15, 19, 19, 15, 17), L(12, 18.5, 12, 21.5)),
    "gamepad": icon(R(2.5, 7, 19, 11, 5.5), L(7, 10.5, 7, 14.5), L(5, 12.5, 9, 12.5), D(15.5, 11, 1.1), D(18, 13.5, 1.1)),
    "wand": icon(L(4, 20, 15, 9), L(18, 3, 18, 8), L(15.5, 5.5, 20.5, 5.5), L(20, 12, 20, 15), L(18.5, 13.5, 21.5, 13.5)),
    "sparkles": icon(P(12, 2.5, 14, 10, 21.5, 12, 14, 14, 12, 21.5, 10, 14, 2.5, 12, 10, 10, 12, 2.5), L(19, 3, 19, 7), L(17, 5, 21, 5)),
    "magnet": icon(A(12, 12, 7.5, 0, 180), A(12, 12, 3.5, 0, 180), L(4.5, 12, 4.5, 4), L(19.5, 12, 19.5, 4), L(8.5, 12, 8.5, 4), L(15.5, 12, 15.5, 4), L(4.5, 4, 8.5, 4), L(15.5, 4, 19.5, 4)),

    # ---------- farm / nature / items ----------
    "egg": icon(egg(), P(8.5, 13.5, 10.5, 11.5, 12.5, 13.5, 14.5, 11.5, 15.5, 12.5)),
    "paw": icon(D(6, 10.5, 1.9), D(10, 6.5, 1.9), D(14, 6.5, 1.9), D(18, 10.5, 1.9), P(12, 12, 15.5, 15, 16.5, 18.5, 14.5, 20.5, 12, 19.5, 9.5, 20.5, 7.5, 18.5, 8.5, 15, 12, 12)),
    "sprout": icon(L(12, 21, 12, 11), P(12, 13, 7, 13.5, 4, 10.5, 4, 7, 7.5, 7.5, 10.5, 9.5, 12, 13), P(12, 10, 14, 6, 18, 4.5, 20.5, 4.5, 20, 8.5, 17, 11, 12, 10)),
    "leaf": icon(P(20.5, 3.5, 11, 4.5, 5.5, 10, 5.5, 16, 8.5, 18.5, 14.5, 18, 19.5, 12, 20.5, 3.5), L(3, 21, 11, 13)),
    "tree": icon(P(12, 2.5, 18, 10, 15, 10, 19, 16, 5, 16, 9, 10, 6, 10, 12, 2.5), L(12, 16, 12, 21.5)),
    "fish": icon(P(3, 12, 8, 7, 14, 6.5, 18, 10, 21.5, 7, 21.5, 17, 18, 14, 14, 17.5, 8, 17, 3, 12), D(8, 11.5, 1)),
    "droplet": icon(P(12, 2.5, 17, 9.5, 18.5, 14, 16.5, 18.5, 12, 21, 7.5, 18.5, 5.5, 14, 7, 9.5, 12, 2.5)),
    "snowflake": icon(L(12, 2.5, 12, 21.5), L(3.8, 7.2, 20.2, 16.8), L(20.2, 7.2, 3.8, 16.8)),
    "pumpkin": icon(R(3, 7.5, 18, 13.5, 6.5), R(8.5, 7.5, 7, 13.5, 3.5), P(12, 7.5, 12, 4.5, 14.5, 3.5)),
    "mountain": icon(P(2, 20, 9, 7, 13, 13, 15.5, 9.5, 22, 20, 2, 20)),
    "moon": icon(A(12, 12, 9, 0, 270), A(16.5, 7.5, 6.36, 225, 45)),
    "sun": icon(C(12, 12, 4.2), spokes(12, 12, 7.4, 10, 8)),
    "cloud": icon(L(7.5, 19, 17.5, 19), A(17.5, 15.5, 3.5, -90, 90), A(7.5, 15.5, 3.5, 90, 270), A(12.8, 12, 4.8, 180, 360)),
    "box": icon(P(12, 2.5, 21, 7.5, 21, 16.5, 12, 21.5, 3, 16.5, 3, 7.5, 12, 2.5), P(3, 7.5, 12, 12.5, 21, 7.5), L(12, 12.5, 12, 21.5)),
    "bag": icon(P(5, 8, 19, 8, 20, 21, 4, 21, 5, 8), A(12, 8, 4, 180, 360)),
    "gift": icon(R(3, 9, 18, 4, 1.5), R(5, 13, 14, 8, 1.5), L(12, 9, 12, 21), P(12, 9, 8, 8, 7.5, 5, 10, 4.5, 12, 9), P(12, 9, 16, 8, 16.5, 5, 14, 4.5, 12, 9)),
    "coin": icon(C(12, 12, 9.5), C(12, 12, 5.5)),
    "dollar": icon(L(12, 3, 12, 21), P(17, 7, 15, 5.8, 10.5, 5.8, 8, 8, 8.5, 10.5, 12, 12, 15.5, 13.5, 16, 16, 13.5, 18.2, 9, 18.2, 7, 17)),
    "store": icon(P(3.5, 9, 5, 3.5, 19, 3.5, 20.5, 9, 3.5, 9), R(5, 9, 14, 12, 1), R(9.5, 14, 5, 7, 1)),
    "cart": icon(P(2, 3.5, 5, 3.5, 7.5, 15.5, 18.5, 15.5, 21, 7, 6, 7), C(9.5, 20, 1.5), C(17, 20, 1.5)),
    "tag": icon(P(3, 3, 12.5, 3, 21, 11.5, 12, 21, 3, 12, 3, 3), D(7.5, 7.5, 1.5)),
    "bookmark": icon(P(6, 3, 18, 3, 18, 21.5, 12, 17, 6, 21.5, 6, 3)),
    "key": icon(C(8, 15, 4.5), L(11.5, 11.5, 21, 2), L(17.5, 5.5, 20, 8), L(15, 8, 17, 10)),
    "lightbulb": icon(A(12, 9.5, 6, 135, 405), P(7.8, 13.7, 9.5, 16, 9.5, 18.5, 14.5, 18.5, 14.5, 16, 16.2, 13.7), L(10, 21.5, 14, 21.5)),
    "anchor": icon(C(12, 5, 2.5), L(12, 7.5, 12, 21.5), L(8, 12, 16, 12), A(12, 12.5, 8.5, 20, 160)),
    "hammer": icon(L(14, 10, 4.5, 19.5), P(9, 7, 14, 2.5, 21.5, 10, 17, 15, 9, 7)),
    "wrench": icon(C(16.5, 7.5, 4.5), L(13.3, 10.7, 4, 20)),
    "pickaxe": icon(L(4, 20, 14, 10), A(8, 16, 8.5, -110, 20)),
    "coffee": icon(P(4, 8, 4, 15, 7, 19, 14, 19, 17, 15, 17, 8, 4, 8), P(17, 9.5, 20, 9.5, 20, 14, 17, 14), L(7, 3.5, 7, 5.5), L(10.5, 3, 10.5, 5.5), L(14, 3.5, 14, 5.5)),

    # ---------- map / world ----------
    "map": icon(P(3, 6, 9, 3.5, 15, 6, 21, 3.5, 21, 18, 15, 20.5, 9, 18, 3, 20.5, 3, 6), L(9, 3.5, 9, 18), L(15, 6, 15, 20.5)),
    "compass": icon(C(12, 12, 9.5), P(15.5, 8.5, 13.5, 13.5, 8.5, 15.5, 10.5, 10.5, 15.5, 8.5)),
    "pin": icon(P(12, 21.5, 6.5, 14, 5.5, 10, 7, 6, 10, 4, 14, 4, 17, 6, 18.5, 10, 17.5, 14, 12, 21.5), C(12, 10, 2.3)),
    "flag": icon(L(5, 3, 5, 22), P(5, 4, 19, 4, 16, 8.5, 19, 13, 5, 13)),
    "globe": icon(C(12, 12, 9.5), L(2.5, 12, 21.5, 12), R(7.5, 2.5, 9, 19, 4.5)),
    "plane": icon(P(21, 3, 3, 10.5, 10.5, 13.5, 13.5, 21, 21, 3)),
    "car": icon(P(2.5, 16, 2.5, 11.5, 5.5, 10.5, 8, 6.5, 16, 6.5, 18.5, 10.5, 21.5, 11.5, 21.5, 16, 2.5, 16), C(7, 17.5, 2), C(17, 17.5, 2)),

    # ---------- system / dev ----------
    "terminal": icon(R(2.5, 4, 19, 16, 3), P(7, 9.5, 10.5, 12.5, 7, 15.5), L(12.5, 16, 17, 16)),
    "code": icon(P(8, 7, 3, 12, 8, 17), P(16, 7, 21, 12, 16, 17), L(14, 4.5, 10, 19.5)),
    "cpu": icon(R(6, 6, 12, 12, 2), R(9.5, 9.5, 5, 5, 1), L(9, 2.5, 9, 6), L(15, 2.5, 15, 6), L(9, 18, 9, 21.5), L(15, 18, 15, 21.5), L(2.5, 9, 6, 9), L(2.5, 15, 6, 15), L(18, 9, 21.5, 9), L(18, 15, 21.5, 15)),
    "database": icon(R(4, 3, 16, 6, 3), R(4, 9, 16, 6, 3), R(4, 15, 16, 6, 3)),
    "server": icon(R(3, 3.5, 18, 7, 2), R(3, 13.5, 18, 7, 2), D(7, 7, 1.1), D(7, 17, 1.1)),
    "bug": icon(R(7.5, 8, 9, 12.5, 4.5), L(12, 8, 12, 20.5), L(9, 4, 10.5, 6.5), L(15, 4, 13.5, 6.5), L(7.5, 12.5, 3.5, 11), L(16.5, 12.5, 20.5, 11), L(7.5, 17, 3.5, 19), L(16.5, 17, 20.5, 19)),
    "activity": icon(P(2, 12, 6, 12, 9, 4, 15, 20, 18, 12, 22, 12)),
    "chart": icon(F(4, 12, 3, 9, 1), F(10.5, 4, 3, 17, 1), F(17, 8, 3, 13, 1)),
    "trending": icon(P(3, 17, 9, 11, 13, 15, 21, 7), P(15, 7, 21, 7, 21, 13)),
    "gauge": icon(A(12, 15, 9, 180, 360), L(12, 15, 16, 9.5), D(12, 15, 1.3)),
    "battery": icon(R(2.5, 7, 17, 10, 2.5), L(21.5, 10.5, 21.5, 13.5), F(5, 9.5, 6, 5, 1)),
    "monitor": icon(R(2.5, 3.5, 19, 13, 2.5), L(8, 21, 16, 21), L(12, 16.5, 12, 21)),
    "phone": icon(R(6.5, 2.5, 11, 19, 2.5), D(12, 18.5, 0.9)),
    "keyboard": icon(R(2.5, 6, 19, 12, 2.5), D(6.5, 10, 0.9), D(10, 10, 0.9), D(14, 10, 0.9), D(17.5, 10, 0.9), L(7, 15, 17, 15)),
    "mouse": icon(R(6.5, 2.5, 11, 19, 5.5), L(12, 2.5, 12, 9.5)),
    "pointer": icon(P(5, 3, 19, 11, 12, 13, 9.5, 20, 5, 3)),
    "wifi": icon(A(12, 19, 4.2, 225, 315), A(12, 19, 8.4, 225, 315), A(12, 19, 12.6, 225, 315), D(12, 19, 1.3)),
    "link": icon(R(2.5, 8.5, 11, 7, 3.5), R(10.5, 8.5, 11, 7, 3.5)),
    "lock": icon(R(4.5, 10.5, 15, 11, 2.5), A(12, 10.5, 4.5, 180, 360), D(12, 16, 1.2)),
    "unlock": icon(R(4.5, 10.5, 15, 11, 2.5), L(7.5, 10.5, 7.5, 7), A(12, 7, 4.5, 180, 360), D(12, 16, 1.2)),
    "power": icon(A(12, 13, 8, -60, 240), L(12, 3, 12, 12)),
    "refresh": icon(A(12, 12, 8, -60, 210), P(5, 3.5, 5, 8.5, 10, 8.5)),
    "repeat": icon(P(17, 3, 20, 6, 17, 9), P(4, 11, 4, 8, 7, 6, 20, 6), P(7, 21, 4, 18, 7, 15), P(20, 13, 20, 16, 17, 18, 4, 18)),
    "shuffle": icon(P(3, 7, 8, 7, 16, 17, 21, 17), P(18, 14, 21, 17, 18, 20), P(3, 17, 8, 17, 10.5, 14), P(13.5, 10, 16, 7, 21, 7), P(18, 4, 21, 7, 18, 10)),
    "login": icon(P(10, 17, 15, 12, 10, 7), L(15, 12, 3, 12), P(14, 3, 19, 3, 21, 5, 21, 19, 19, 21, 14, 21)),
    "logout": icon(P(16, 17, 21, 12, 16, 7), L(21, 12, 9, 12), P(9, 3, 5, 3, 3, 5, 3, 19, 5, 21, 9, 21)),
    "play": icon(P(7, 4.5, 19, 12, 7, 19.5, 7, 4.5)),
    "play-circle": icon(C(12, 12, 9.5), P(10, 8.5, 15.5, 12, 10, 15.5, 10, 8.5)),
    "pause": icon(F(6, 4.5, 4, 15, 1.2), F(14, 4.5, 4, 15, 1.2)),
    "stop": icon(F(5, 5, 14, 14, 2)),
    "skip": icon(P(5, 5, 15, 12, 5, 19, 5, 5), L(19, 5, 19, 19)),
    "download": icon(L(12, 3, 12, 15), P(7, 10.5, 12, 15.5, 17, 10.5), P(4, 16, 4, 20, 20, 20, 20, 16)),
    "upload": icon(L(12, 15.5, 12, 3.5), P(7, 8, 12, 3, 17, 8), P(4, 16, 4, 20, 20, 20, 20, 16)),
    "copy": icon(R(8.5, 8.5, 12, 12, 2.5), P(5.5, 15.5, 4.5, 15.5, 3.5, 14.5, 3.5, 5.5, 5.5, 3.5, 14.5, 3.5, 15.5, 4.5, 15.5, 5.5)),
    "trash": icon(L(3.5, 6.5, 20.5, 6.5), P(6, 6.5, 7, 19.5, 8.5, 21, 15.5, 21, 17, 19.5, 18, 6.5), P(9.5, 6.5, 9.5, 3.5, 14.5, 3.5, 14.5, 6.5), L(10, 10.5, 10, 17), L(14, 10.5, 14, 17)),
    "edit": icon(P(16.5, 3.5, 20.5, 7.5, 8, 20, 3.5, 20.5, 4, 16, 16.5, 3.5), L(14, 6, 18, 10)),
    "save": icon(R(3.5, 3.5, 17, 17, 2.5), R(7, 3.5, 9, 5.5, 1), R(6.5, 12.5, 11, 8, 1.5)),
    "folder": icon(P(3, 6.5, 3, 19, 21, 19, 21, 8.5, 11.5, 8.5, 9.5, 5.5, 4.5, 5.5, 3, 6.5)),
    "file": icon(P(5.5, 3, 14, 3, 19, 8, 19, 21, 5.5, 21, 5.5, 3), P(14, 3, 14, 8, 19, 8), L(8.5, 13, 16, 13), L(8.5, 17, 16, 17)),
    "clipboard": icon(R(5, 4, 14, 17, 2.5), R(9, 2.5, 6, 3.5, 1.5), L(8.5, 11, 15.5, 11), L(8.5, 15, 13, 15)),
    "book": icon(P(3, 5, 9, 4.5, 12, 6.5, 15, 4.5, 21, 5, 21, 18.5, 15, 18, 12, 20, 9, 18, 3, 18.5, 3, 5), L(12, 6.5, 12, 20)),
    "inbox": icon(P(3, 13, 7, 13, 8.5, 16, 15.5, 16, 17, 13, 21, 13), P(5.5, 4, 18.5, 4, 21, 13, 21, 19, 3, 19, 3, 13, 5.5, 4)),
    "mail": icon(R(2.5, 4.5, 19, 15, 2.5), P(3, 7, 12, 13.5, 21, 7)),
    "chat": icon(P(4, 5, 20, 5, 20, 16, 11, 16, 6.5, 20, 6.5, 16, 4, 16, 4, 5)),
    "send": icon(P(21.5, 2.5, 2.5, 10, 10.5, 13.5, 14, 21.5, 21.5, 2.5), L(21.5, 2.5, 10.5, 13.5)),
    "bell": icon(P(6, 17, 6, 10, 8, 6, 12, 5, 16, 6, 18, 10, 18, 17, 20, 18.5, 4, 18.5, 6, 17), A(12, 19, 2.2, 0, 180), L(12, 2.5, 12, 5)),
    "calendar": icon(R(3, 5, 18, 16, 2.5), L(3, 10, 21, 10), L(8, 2.5, 8, 7), L(16, 2.5, 16, 7)),
    "clock": icon(C(12, 12, 9.5), P(12, 6.5, 12, 12, 15.5, 14)),
    "timer": icon(C(12, 13.5, 7.5), L(12, 13.5, 12, 9.5), L(9.5, 2.5, 14.5, 2.5), L(12, 2.5, 12, 6), L(18, 7.5, 19.5, 6)),
    "hourglass": icon(P(6, 3, 18, 3, 18, 7, 12, 12, 6, 7, 6, 3), P(6, 21, 18, 21, 18, 17, 12, 12, 6, 17, 6, 21)),
    "volume": icon(P(4, 9.5, 8, 9.5, 13, 5, 13, 19, 8, 14.5, 4, 14.5, 4, 9.5), A(13, 12, 5, -50, 50), A(13, 12, 9, -50, 50)),
    "mic": icon(R(9, 2.5, 6, 11.5, 3), A(12, 11, 7, 0, 180), L(12, 18, 12, 21.5), L(8.5, 21.5, 15.5, 21.5)),
    "music": icon(P(9, 18, 9, 5, 20, 3, 20, 16), C(6.5, 18, 2.7), C(17.5, 16, 2.7)),
    "camera": icon(P(3, 8, 7, 8, 9, 5, 15, 5, 17, 8, 21, 8, 21, 19, 3, 19, 3, 8), C(12, 13, 3.5)),
    "image": icon(R(3, 3.5, 18, 17, 2.5), D(8.5, 9, 1.6), P(3.5, 17, 9, 12, 14, 17, 17, 14, 20.5, 17.5)),
    "palette": icon(C(12, 12, 9.5), D(8, 10, 1.3), D(12, 7.5, 1.3), D(16, 10, 1.3), D(8.5, 15, 1.3)),
    "brush": icon(P(18.5, 3, 21, 5.5, 12, 14.5, 9.5, 12, 18.5, 3), P(9.5, 12, 6, 13, 5, 16.5, 4, 20, 7.5, 19, 11, 18, 12, 14.5)),

    # ---------- brand ----------
    "rage": icon(HEX, P(13, 7, 9, 12.5, 12.5, 12.5, 11, 17, 15.5, 11, 12, 11, 13, 7)),
}

ALIASES = {
    "gear": "settings", "cog": "settings", "misc": "grid", "farm": "sprout", "plant": "sprout",
    "visuals": "eye", "esp": "eye", "player": "user", "avatar": "user", "combat": "sword",
    "pvp": "swords", "aimbot": "crosshair", "teleports": "teleport", "tp": "teleport",
    "movement": "run", "speed": "run", "fling": "zap", "bolt": "zap", "lightning": "zap",
    "eggs": "egg", "pets": "paw", "pet": "paw", "shop": "store", "buy": "cart", "money": "coin",
    "cash": "dollar", "premium": "crown", "vip": "crown", "event": "calendar", "events": "calendar",
    "webhook": "link", "server-hop": "shuffle", "hop": "shuffle", "rejoin": "refresh", "reconnect": "refresh",
    "afk": "coffee", "anti-afk": "coffee", "script": "code", "executor": "terminal", "console": "terminal",
    "stats": "chart", "info-circle": "info", "alert": "warning", "error": "circle-x", "success": "circle-check",
    "close": "x", "back": "chevron-left", "next": "chevron-right", "up": "chevron-up", "down": "chevron-down",
    "world": "globe", "map-pin": "pin", "location": "pin", "performance": "gauge", "fps": "gauge",
    "config": "save", "profile": "user-circle", "account": "user-circle", "discord": "chat",
    "fly-mode": "fly", "noclip": "ghost", "godmode": "shield", "auto": "bot", "automation": "bot",
    "farm-bot": "bot", "unload": "power", "exit": "logout", "join": "login", "logo": "rage", "ragehub": "rage",
    "dark": "moon", "light": "sun", "theme": "palette", "ui": "monitor", "mobile": "phone", "pc": "monitor",
    "halloween": "pumpkin", "winter": "snowflake", "water": "droplet", "forest": "tree", "boss": "skull",
    "quest": "flag", "tasks": "clipboard", "logs": "file", "update": "download", "notification": "bell",
}

# ---------------------------------------------------------------- lua output
def fmt(x):
    if isinstance(x, str):
        return '"%s"' % x
    s = ("%.2f" % x).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s

def lua_table():
    lines = ["local ICONS = {"]
    for name, shapes in ICONS.items():
        body = ",".join("{" + ",".join(fmt(v) for v in s) + "}" for s in shapes)
        lines.append('\t["%s"] = {%s},' % (name, body))
    lines.append("}")
    lines.append("local ICON_ALIASES = {")
    for k, v in ALIASES.items():
        lines.append('\t["%s"] = "%s",' % (k, v))
    lines.append("}")
    return "\n".join(lines) + "\n"

# ---------------------------------------------------------------- rendering
def render_icon(draw, shapes, ox, oy, s, col, w=2.0):
    """Approximates how the Lua engine draws an icon (used for previews only)."""
    def pt(x, y): return (ox + x * s, oy + y * s)
    def dot(x, y, r):
        draw.ellipse([ox + (x - r) * s, oy + (y - r) * s, ox + (x + r) * s, oy + (y + r) * s], fill=col)
    def seg(x1, y1, x2, y2):
        draw.line([pt(x1, y1), pt(x2, y2)], fill=col, width=int(round(w * s)))
        dot(x1, y1, w / 2); dot(x2, y2, w / 2)
    for sh in shapes:
        t = sh[0]; a = sh[1:]
        if t == "L":
            seg(*a)
        elif t == "P":
            for i in range(0, len(a) - 2, 2):
                seg(a[i], a[i + 1], a[i + 2], a[i + 3])
        elif t == "C":
            cx, cy, r = a; r2 = r + w / 2
            draw.ellipse([ox + (cx - r2) * s, oy + (cy - r2) * s, ox + (cx + r2) * s, oy + (cy + r2) * s],
                         outline=col, width=int(round(w * s)))
        elif t == "D":
            dot(*a)
        elif t == "R":
            x, y, ww, hh, rad = a
            draw.rounded_rectangle([ox + (x - w / 2) * s, oy + (y - w / 2) * s,
                                    ox + (x + ww + w / 2) * s, oy + (y + hh + w / 2) * s],
                                   radius=(rad + w / 2) * s, outline=col, width=int(round(w * s)))
        elif t == "F":
            x, y, ww, hh, rad = a
            draw.rounded_rectangle([ox + x * s, oy + y * s, ox + (x + ww) * s, oy + (y + hh) * s],
                                   radius=rad * s, fill=col)

def preview(path):
    from PIL import Image, ImageDraw, ImageFont
    names = list(ICONS.keys())
    cols = 10
    cw, ch = 132, 118
    rows = math.ceil(len(names) / cols)
    ss = 3
    W, H = cols * cw, rows * ch + 70
    img = Image.new("RGB", (W * ss, H * ss), (16, 14, 26))
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf", 12 * ss)
        big = ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf", 22 * ss)
    except Exception:
        font = big = ImageFont.load_default()
    d.text((20 * ss, 18 * ss), "Rage Hub - %d icons" % len(names), fill=(240, 238, 255), font=big)
    for i, n in enumerate(names):
        cx, cy = (i % cols) * cw, (i // cols) * ch + 70
        d.rounded_rectangle([(cx + 8) * ss, (cy + 6) * ss, (cx + cw - 8) * ss, (cy + ch - 6) * ss],
                            radius=12 * ss, fill=(26, 23, 44))
        render_icon(d, ICONS[n], (cx + cw / 2 - 20) * ss, (cy + 16) * ss, 40 / 24 * ss, (196, 170, 255))
        tw = d.textlength(n, font=font)
        d.text((cx * ss + (cw * ss - tw) / 2, (cy + 78) * ss), n, fill=(160, 154, 195), font=font)
    img = img.resize((W, H), Image.LANCZOS)
    img.save(path)

def logo(path_png, path_svg, size=512):
    from PIL import Image, ImageDraw
    ss = 2
    S = size * ss
    grad = Image.new("RGB", (S, S))
    px = grad.load()
    c1, c2, c3 = (124, 58, 237), (217, 70, 239), (244, 63, 94)
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * S - 2)
            if t < 0.6:
                u = t / 0.6
                c = tuple(int(c1[i] + (c2[i] - c1[i]) * u) for i in range(3))
            else:
                u = (t - 0.6) / 0.4
                c = tuple(int(c2[i] + (c3[i] - c2[i]) * u) for i in range(3))
            px[x, y] = c
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.23), fill=255)
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    base.paste(grad, (0, 0), mask)
    # soft top light (no hard edge)
    hl = Image.new("L", (S, S), 0)
    hd = ImageDraw.Draw(hl)
    for y in range(int(S * 0.6)):
        hd.line([(0, y), (S, y)], fill=int(48 * (1 - y / (S * 0.6)) ** 2))
    white = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    hl_mask = Image.new("L", (S, S), 0)
    hl_mask.paste(hl, (0, 0), mask)
    base = Image.composite(white, base, hl_mask) if False else Image.alpha_composite(base, Image.merge("RGBA", (white.split()[0], white.split()[1], white.split()[2], hl_mask)))
    d = ImageDraw.Draw(base)
    m = S * 0.17
    s = (S - 2 * m) / 24
    def P2(pts):
        return [(m + pts[i] * s, m + pts[i + 1] * s) for i in range(0, len(pts), 2)]
    hexpts = P2(HEX[1:])
    wpx = int(2.1 * s)
    d.line(hexpts + [hexpts[0]], fill=(255, 255, 255), width=wpx, joint="curve")
    for (x, y) in hexpts:
        d.ellipse([x - wpx / 2, y - wpx / 2, x + wpx / 2, y + wpx / 2], fill=(255, 255, 255))
    bolt = P2([13.4, 6.6, 8.6, 12.9, 12.3, 12.9, 10.8, 17.6, 15.6, 11.2, 11.9, 11.2])
    d.polygon(bolt, fill=(255, 255, 255))
    d.line(bolt + [bolt[0]], fill=(255, 255, 255), width=int(0.8 * s), joint="curve")
    base = base.resize((size, size), Image.LANCZOS)
    base.save(path_png)

    sc = (size - 2 * size * 0.17) / 24
    off = size * 0.17
    hx = " ".join("%.2f,%.2f" % (off + HEX[1:][i] * sc, off + HEX[1:][i + 1] * sc) for i in range(0, len(HEX) - 1, 2))
    bp = [13.4, 6.6, 8.6, 12.9, 12.3, 12.9, 10.8, 17.6, 15.6, 11.2, 11.9, 11.2]
    bt = " ".join("%.2f,%.2f" % (off + bp[i] * sc, off + bp[i + 1] * sc) for i in range(0, len(bp), 2))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#7C3AED"/><stop offset="0.6" stop-color="#D946EF"/><stop offset="1" stop-color="#F43F5E"/>
  </linearGradient></defs>
  <rect width="{size}" height="{size}" rx="{size * 0.23:.0f}" fill="url(#g)"/>
  <polyline points="{hx}" fill="none" stroke="#fff" stroke-width="{2.1 * sc:.2f}" stroke-linecap="round" stroke-linejoin="round"/>
  <polygon points="{bt}" fill="#fff" stroke="#fff" stroke-width="{0.8 * sc:.2f}" stroke-linejoin="round"/>
</svg>
'''
    with open(path_svg, "w") as f:
        f.write(svg)

def icons_md(path):
    names = sorted(ICONS.keys())
    lines = ["# Rage Hub icons", "",
             "%d vector icons, drawn with plain Frames (no asset ids, no emoji)." % len(names), "",
             "Use them anywhere in the library: `Window:CreateTab(\"Farm\", \"sprout\")`, `Section:CreateToggle({Icon = \"zap\"})`,",
             "or in your own UI with `RageHub:CreateIcon(parent, \"zap\", 20, Color3.new(1,1,1))`.", "",
             "![icons](assets/icons-preview.png)", "", "## Names", "",
             ", ".join("`%s`" % n for n in names), "", "## Aliases", "",
             ", ".join("`%s` -> `%s`" % (k, v) for k, v in sorted(ALIASES.items())), ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))

if __name__ == "__main__":
    for a, t in ALIASES.items():
        assert t in ICONS, (a, t)
    with open(os.path.join(ROOT, "src", "icons.lua"), "w") as f:
        f.write(lua_table())
    os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
    try:
        preview(os.path.join(ROOT, "assets", "icons-preview.png"))
        logo(os.path.join(ROOT, "assets", "logo.png"), os.path.join(ROOT, "assets", "logo.svg"))
    except ImportError:
        print("Pillow not installed: skipped preview/logo (pip install pillow)")
    icons_md(os.path.join(ROOT, "ICONS.md"))
    print("icons:", len(ICONS), "aliases:", len(ALIASES))
