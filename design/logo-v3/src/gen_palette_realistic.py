# 一览图标 v3 · C「长卷」上一版（写实照片风，已被否，仅留作参照）；输出到 ../palette/prev-realistic
# 用法：python3 gen_palette.py [输出目录]   （默认输出到 ../palette）
import math, os, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'palette', 'prev-realistic')

def stops(lst):
    s = ''
    for st in lst:
        s += f'<stop offset="{st[0]}" stop-color="{st[1]}"' + (f' stop-opacity="{st[2]}"' if len(st) > 2 else '') + '/>'
    return s
def lin(id, x1, y1, x2, y2, lst, user=False):
    u = ' gradientUnits="userSpaceOnUse"' if user else ''
    return f'<linearGradient id="{id}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"{u}>{stops(lst)}</linearGradient>'
def rad(id, cx, cy, r, lst, user=False):
    u = ' gradientUnits="userSpaceOnUse"' if user else ''
    return f'<radialGradient id="{id}" cx="{cx}" cy="{cy}" r="{r}"{u}>{stops(lst)}</radialGradient>'
def streak(x0, x1, y, h):
    cx = (x0 + x1) / 2
    return f'M{x0} {y} Q{cx} {y-h} {x1} {y} Q{cx} {y+h} {x0} {y}Z'
def rpoly(pts, r):
    n = len(pts); d = ''
    for i in range(n):
        p0 = pts[i-1]; p1 = pts[i]; p2 = pts[(i+1) % n]
        def toward(a, b):
            L = math.hypot(b[0]-a[0], b[1]-a[1]); k = min(r, L/2) / L
            return (a[0] + (b[0]-a[0])*k, a[1] + (b[1]-a[1])*k)
        a = toward(p1, p0); b = toward(p1, p2)
        d += ('M' if i == 0 else 'L') + f'{a[0]:.1f} {a[1]:.1f} Q{p1[0]:.1f} {p1[1]:.1f} {b[0]:.1f} {b[1]:.1f} '
    return d + 'Z'
def ridge(x0, x1, base, hs):
    # 山脊剪影：一串高度连成平滑曲线，底边落在 base
    n = len(hs); step = (x1 - x0) / (n - 1)
    pts = [(x0 + i * step, base - h) for i, h in enumerate(hs)]
    d = f'M{x0} {base} L{pts[0][0]:.1f} {pts[0][1]:.1f} '
    for i in range(1, n):
        mx = (pts[i-1][0] + pts[i][0]) / 2; my = (pts[i-1][1] + pts[i][1]) / 2
        d += f'Q{pts[i-1][0]:.1f} {pts[i-1][1]:.1f} {mx:.1f} {my:.1f} '
    d += f'L{pts[-1][0]:.1f} {pts[-1][1]:.1f} L{x1} {base}Z'
    return d
def rgb01(hexs):
    h = hexs.lstrip('#'); return [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]

# ------------------------------------------------------------------ 配色
PALETTES = {
 # 胶片暖调：柯达盒子那种暖黄到赭红的底，中间是一张黄昏海面的照片
 'film': dict(
  cn='胶片暖调',
  bg=[(0, '#e7a548'), (.48, '#cf6a2c'), (1, '#8a3a1c')], bg_s=[(0, '#dc9638'), (.48, '#c05c24'), (1, '#7a3018')],
  amb=('#ffd98a', .5), halo=('#ffd9a0', .5, .3),
  sky=[(0, '#4e2e20'), (.3, '#8a4826'), (.58, '#cc6a2c'), (.8, '#f09a40'), (.93, '#fcc468'), (1, '#ffe2a0')],
  sea=[(0, '#f4b460'), (.1, '#c47434'), (.4, '#7a3e20'), (1, '#321a10')],
  cloud=('#4a2414', .5), cloud_lit=('#ffb458', .6),
  sun='#fff8e4', bloom=[(0, '#fff4d0', 1), (.14, '#ffdc98', .85), (.45, '#f8a850', .38), (1, '#f08a3c', 0)],
  hill_far=('#8a5434', .9), hill_near=('#3a2218', 1),
  glitter='#ffe8b8', wave='#24140c', haze=('#ffd898', .5), vig=('#1c0e08', .5),
  ln=[(0, '#fff', 0), (.14, '#fff0d0', .85), (.5, '#fff'), (.86, '#fff0d0', .85), (1, '#fff', 0)],
  rim=('#fff4e0', .72, .9), edge=('#ffe6bc', .32), shadow=('#4a1a08', .5), body_sh='#3a1608',
  pan=('#7a3a1c', '#f2b868', .62, .5), pstroke=('#fff4e0', .55, .8), sheen=.2),
 # 东方墨色：宣纸白底，中间是一张黑白的山水雾景照片，只有地平线那一笔是朱砂红
 'ink': dict(
  cn='东方墨色',
  bg=[(0, '#f9f5ec'), (.55, '#f0eadd'), (1, '#e0d8c6')], bg_s=[(0, '#f9f5ec'), (.55, '#f0eadd'), (1, '#e0d8c6')],
  amb=('#ffffff', .6), halo=('#8a8478', .16, .12),
  sky=[(0, '#6e6c68'), (.35, '#908e89'), (.7, '#bcb9b2'), (.92, '#dedbd4'), (1, '#ece9e2')],
  sea=[(0, '#e2dfd8'), (.12, '#b9b6af'), (.45, '#85837e'), (1, '#4c4a47')],
  cloud=('#5a5854', .4), cloud_lit=('#f4f2ec', .45),
  sun='#ffffff', bloom=[(0, '#ffffff', 1), (.16, '#fbfaf6', .8), (.5, '#eeebe4', .34), (1, '#eeebe4', 0)],
  hill_far=('#9a9892', .9), hill_near=('#3e3c3a', 1),
  glitter='#ffffff', wave='#2a2927', haze=('#f6f4ee', .6), vig=('#1e1d1b', .42),
  ln=[(0, '#c8321f', 0), (.12, '#cf3a24', .92), (.5, '#d8412a'), (.88, '#cf3a24', .92), (1, '#c8321f', 0)],
  rim=('#2a2724', .8, .9), edge=('#4a4234', .24), shadow=('#6a5e48', .3), body_sh='#3a3020',
  pan=('#77746e', '#dcd9d1', .7, .55), pstroke=('#2a2724', .62, .85), sheen=.28),
 # 石墨金线：石墨黑单色，中间是一张低调的金色落日照片，只有一道暖金色天光
 'graphite': dict(
  cn='石墨金线',
  bg=[(0, '#383a3f'), (.5, '#222327'), (1, '#131417')], bg_s=[(0, '#303237'), (.5, '#1c1d21'), (1, '#101114')],
  amb=('#a4a6ae', .2), halo=('#e8ac40', .3, .2),
  sky=[(0, '#101114'), (.4, '#1e1f22'), (.68, '#3a332a'), (.86, '#7a5c30'), (.95, '#c8963e'), (1, '#f0c468')],
  sea=[(0, '#d8a84c'), (.08, '#6e5632'), (.32, '#2a2826'), (1, '#0e0f11')],
  cloud=('#0c0c0e', .6), cloud_lit=('#c89238', .5),
  sun='#fff8dc', bloom=[(0, '#fff2c4', 1), (.14, '#ffd880', .8), (.45, '#e0a038', .32), (1, '#c88828', 0)],
  hill_far=('#4a3e2c', .95), hill_near=('#0c0c0e', 1),
  glitter='#ffe09a', wave='#000000', haze=('#f2c060', .42), vig=('#000000', .55),
  ln=[(0, '#ffd884', 0), (.14, '#ffdc90', .9), (.5, '#fff6dc'), (.86, '#ffdc90', .9), (1, '#ffd884', 0)],
  rim=('#f4f2ec', .5, .75), edge=('#ffffff', .16), shadow=('#000000', .6), body_sh='#000000',
  pan=('#3a3b40', '#b8924c', .7, .55), pstroke=('#f4f2ec', .4, .65), sheen=.14),
}

def wrap(title, P, defs, inner, small):
    e = 10 if small else 4
    col, op = P['edge']
    if small: op = min(1, op * 1.3)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<!-- 一览 Yilan App 图标 v3 · {title}。macOS 图标网格：1024 画布，824 主体，圆角 185 -->
<defs>
 <clipPath id="body"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>
 <filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="{P['body_sh']}" flood-opacity=".36"/></filter>
 <filter id="b2" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="2"/></filter>
 <filter id="b8" x="-50%" y="-150%" width="200%" height="400%"><feGaussianBlur stdDeviation="8"/></filter>
 <filter id="b24" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="24"/></filter>
 <clipPath id="up"><rect x="0" y="0" width="1024" height="512"/></clipPath>
 <clipPath id="dn"><rect x="0" y="512" width="1024" height="512"/></clipPath>
{defs}</defs>
<g filter="url(#sh)">
 <g clip-path="url(#body)">
{inner}
 </g>
 <rect x="{100+e/2}" y="{100+e/2}" width="{824-e}" height="{824-e}" rx="{185-e/2}" fill="none" stroke="{col}" stroke-opacity="{op}" stroke-width="{e}"/>
</g>
</svg>
'''

def noise_filter(id, x, y, w, h, fx, fy, seed, color, gain, bias):
    r, g, b = rgb01(color)
    return (f'<filter id="{id}" filterUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}" color-interpolation-filters="sRGB">'
            f'<feTurbulence type="fractalNoise" baseFrequency="{fx} {fy}" numOctaves="2" seed="{seed}"/>'
            f'<feColorMatrix values="0 0 0 0 {r:.3f}  0 0 0 0 {g:.3f}  0 0 0 0 {b:.3f}  {gain} 0 0 0 {bias}"/></filter>')

def photo(P, x0, y0, w, h, small):
    """中间那张“照片”：天空、云、落日、远山、海面波光、暗角、颗粒。返回 (defs, 内容)"""
    x1, y1 = x0 + w, y0 + h
    sy = 498                      # 太阳中心，略高于地平线
    sunr = 58 if small else 31
    d = (lin('sky', 0, y0, 0, 512, P['sky'], True) + lin('sea', 0, 512, 0, y1, P['sea'], True) +
         rad('bloom', 512, sy, 250 if small else 215, P['bloom'], True) +
         rad('vig', 512, 512, h * .72, [(.55, P['vig'][0], 0), (1, P['vig'][0], P['vig'][1])], True) +
         rad('refl', .5, 0, 1, [(0, P['glitter'], .75), (.4, P['glitter'], .22), (1, P['glitter'], 0)]))
    body = f'''   <rect x="{x0}" y="{y0}" width="{w}" height="{512-y0}" fill="url(#sky)"/>
   <g clip-path="url(#up)"><circle cx="512" cy="{sy}" r="{250 if small else 215}" fill="url(#bloom)"/>'''
    if small:
        body += f'''<circle cx="512" cy="{sy}" r="{sunr}" fill="{P['sun']}"/></g>
   <rect x="{x0}" y="512" width="{w}" height="{y1-512}" fill="url(#sea)"/>
   <path d="M{512-70} 512 L{512+70} 512 L{512+120} {y1} L{512-120} {y1}Z" fill="url(#refl)"/>
   <rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="url(#vig)"/>'''
        return d, body
    d += (noise_filter('nGl1', x0, 512, w, 80, .03, .55, 11, P['glitter'], 9, -4.9) +
          noise_filter('nGl2', x0, 560, w, y1 - 560, .016, .2, 5, P['glitter'], 8, -4.3) +
          noise_filter('nWave', x0, 512, w, y1 - 512, .012, .14, 23, P['wave'], 2.6, -1.1) +
          noise_filter('nSky', x0, y0, w, 512 - y0, .006, .03, 3, P['cloud'][0], 2.4, -1.05) +
          noise_filter('nGrain', x0, y0, w, h, .85, .85, 2, '#808080', .32, -.11) +
          f'<mask id="mPath" maskUnits="userSpaceOnUse" x="{x0}" y="512" width="{w}" height="{y1-512}">'
          f'<path d="M{512-26} 512 L{512+26} 512 L{512+104} {y1} L{512-104} {y1}Z" fill="url(#mFade)" filter="url(#b8)"/></mask>'
          + lin('mFade', 0, 512, 0, y1, [(0, '#fff'), (.6, '#fff', .85), (1, '#fff', .35)], True))
    cc, cop = P['cloud']; lc, lop = P['cloud_lit']
    # 云：深色云体 + 被落日照亮的云底
    clouds = [(430, 376, 120, 9), (590, 352, 90, 7), (560, 418, 130, 8), (410, 444, 80, 6), (630, 462, 70, 5), (500, 474, 110, 4)]
    cl = ''.join(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{cc}" opacity="{cop}"/>'
                 f'<ellipse cx="{cx+6}" cy="{cy+ry*.9:.1f}" rx="{rx*.8:.0f}" ry="{max(2, ry*.4):.1f}" fill="{lc}" opacity="{lop}"/>' for cx, cy, rx, ry in clouds)
    far = ridge(x0 - 10, x1 + 10, 513, [16, 22, 30, 24, 17, 10, 5, 3, 3, 4, 8, 13, 19, 15, 11])
    near = ridge(x0 - 10, x0 + 150, 514, [34, 40, 30, 24, 15, 9, 4, 0])
    body += f'''<rect x="{x0}" y="{y0}" width="{w}" height="{512-y0}" filter="url(#nSky)" opacity=".32"/>
    <g filter="url(#b8)">{cl}</g>
    <circle cx="512" cy="{sy}" r="{sunr}" fill="{P['sun']}" filter="url(#b2)"/>
    <path d="{far}" fill="{P['hill_far'][0]}" opacity="{P['hill_far'][1]}" filter="url(#b2)"/>
    <path d="{near}" fill="{P['hill_near'][0]}" opacity="{P['hill_near'][1]}"/></g>
   <rect x="{x0}" y="512" width="{w}" height="{y1-512}" fill="url(#sea)"/>
   <rect x="{x0}" y="512" width="{w}" height="{y1-512}" filter="url(#nWave)" opacity=".42"/>
   <path d="M{512-34} 512 L{512+34} 512 L{512+118} {y1} L{512-118} {y1}Z" fill="url(#refl)" filter="url(#b8)"/>
   <g mask="url(#mPath)"><rect x="{x0}" y="512" width="{w}" height="80" filter="url(#nGl1)"/><rect x="{x0}" y="560" width="{w}" height="{y1-560}" filter="url(#nGl2)"/></g>
   <ellipse cx="512" cy="512" rx="{w*.62}" ry="13" fill="{P['haze'][0]}" opacity="{P['haze'][1]}" filter="url(#b8)"/>
   <rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="url(#vig)"/>
   <rect x="{x0}" y="{y0}" width="{w}" height="{h}" filter="url(#nGrain)"/>'''
    return d, body

def icon_c(P, small=False):
    pd, pl, op_near, op_far = P['pan']
    if small:
        cw, ch, crx, sw = 360, 440, 70, 16
        sides = [(34, 150, 380, 290, min(1, op_near + .22), 44)]
    else:
        cw, ch, crx, sw = 316, 396, 52, 5
        sides = [(16, 108, 344, 290, op_near, 32), (16, 64, 262, 220, op_far, 22)]
    sc, sop, sop_s = P['pstroke']
    rc, rop, rop_s = P['rim']
    cx0, cx1 = 512 - cw/2, 512 + cw/2
    cy0 = 512 - ch/2
    hc, hop, hop_s = P['halo']
    pdefs, pbody = photo(P, cx0, cy0, cw, ch, small)
    defs = (lin('bg', 0, 0, 1, 1, P['bg_s'] if small else P['bg']) +
     rad('amb', 290, 230, 470, [(0, P['amb'][0], P['amb'][1]), (1, P['amb'][0], 0)], True) +
     rad('halo', 512, 512, 380, [(0, hc, hop_s if small else hop), (1, hc, 0)], True) +
     lin('ln', 0, 0, 1, 0, P['ln']) +
     lin('sheen', 0, 0, 0, 1, [(0, '#fff', P['sheen']), (.45, '#fff', .03), (1, '#fff', 0)]) +
     # 侧片：和中间照片同一道光——上下暗、地平线处亮
     lin('pan', 0, 512 - 172, 0, 512 + 172, [(0, pd), (.44, pl), (.5, pl), (.52, pl), (.8, pd), (1, pd)], True) +
     pdefs + f'<clipPath id="cen"><rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch}" rx="{crx}"/></clipPath>')
    g = ''
    offs = []; x = cx1
    for gap, w, hi, ho, op, r in sides:
        offs.append((x + gap, x + gap + w, hi, ho, op, r)); x = x + gap + w
    for xa, xb, hi, ho, op, r in reversed(offs):   # 先画远处的玻璃片
        for side in (1, -1):
            mx = (lambda v: v) if side == 1 else (lambda v: 1024 - v)
            d = rpoly([(mx(xa), 512 - hi/2), (mx(xb), 512 - ho/2), (mx(xb), 512 + ho/2), (mx(xa), 512 + hi/2)], r)
            g += f'''  <path d="{d}" fill="{P['shadow'][0]}" opacity="{round(P['shadow'][1]*.75, 3)}" filter="url(#b24)" transform="translate(0 12)"/>
  <path d="{d}" fill="url(#pan)" fill-opacity="{op}"/>
  <path d="{d}" fill="url(#sheen)"/>
  <path d="{d}" fill="none" stroke="{sc}" stroke-opacity="{sop_s if small else sop}" stroke-width="{sw}"/>
'''
    g += f'''  <rect x="{cx0}" y="{cy0+16}" width="{cw}" height="{ch}" rx="{crx}" fill="{P['shadow'][0]}" opacity="{P['shadow'][1]}" filter="url(#b24)"/>
  <g clip-path="url(#cen)">
{pbody}
  </g>
  <rect x="{cx0+sw/2}" y="{cy0+sw/2}" width="{cw-sw}" height="{ch-sw}" rx="{crx-sw/2}" fill="none" stroke="{rc}" stroke-opacity="{rop_s if small else rop}" stroke-width="{sw}"/>
  <path d="{streak(120, 904, 512, 38 if small else 9)}" fill="url(#ln)"/>'''
    inner = f'''  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#amb)"/>
  <rect width="1024" height="1024" fill="url(#halo)"/>
{g}'''
    return wrap(f"C「长卷」· {P['cn']}" + ('（小尺寸简化版）' if small else ''), P, defs, inner, small)

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for key, P in PALETTES.items():
        open(os.path.join(OUT, f'c-{key}.svg'), 'w').write(icon_c(P, False))
        open(os.path.join(OUT, f'c-{key}-small.svg'), 'w').write(icon_c(P, True))
