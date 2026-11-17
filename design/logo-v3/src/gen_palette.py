# 一览图标 v3 · C「长卷」配色版（抽象简约风）：3 套非蓝紫配色，平面色块 + 均匀细描边
# 用法：python3 gen_palette.py [输出目录]   （默认输出到 ../palette）
import math, os, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'palette')

def rpoly(pts, r):
    # 圆角多边形
    n = len(pts); d = ''
    for i in range(n):
        p0 = pts[i-1]; p1 = pts[i]; p2 = pts[(i+1) % n]
        def toward(a, b):
            L = math.hypot(b[0]-a[0], b[1]-a[1]); k = min(r, L/2) / L
            return (a[0] + (b[0]-a[0])*k, a[1] + (b[1]-a[1])*k)
        a = toward(p1, p0); b = toward(p1, p2)
        d += ('M' if i == 0 else 'L') + f'{a[0]:.1f} {a[1]:.1f} Q{p1[0]:.1f} {p1[1]:.1f} {b[0]:.1f} {b[1]:.1f} '
    return d + 'Z'

# ------------------------------------------------------------------ 配色（每套只用少数几个颜色）
# bg：底板上下两色的柔和渐变；sky/sea：中间画面的两块平涂；sun：太阳；line：地平线「一」
# pan：两侧玻璃片（颜色，近处不透明度，远处不透明度）；stroke：玻璃描边（颜色，不透明度，小尺寸不透明度）
PALETTES = {
 'film': dict(cn='胶片暖调',
  bg=('#eda94c', '#cf6a2c'), sky='#6b2f17', sea='#4f2110', sun='#ffd88a', line='#fff4de', refl='#ffd88a',
  pan=('#fff1d6', .34, .2), stroke=('#fff4de', .78, .9), edge=('#fff0d0', .3), body_sh='#3a1608', lift=('#3a1608', .28)),
 'ink': dict(cn='东方墨色',
  bg=('#faf6ed', '#e9e2d2'), sky='#fffdf8', sea='#e6e0d2', sun='#d8412a', line='#1f1c19', refl='#8f8a80',
  pan=('#3a362f', .2, .1), stroke=('#26231f', .8, .9), edge=('#4a4234', .22), body_sh='#3a3020', lift=('#5a5040', .18)),
 'graphite': dict(cn='石墨金线',
  bg=('#35373c', '#18191c'), sky='#26272b', sea='#111214', sun='#f2c060', line='#ffe2a0', refl='#f2c060',
  pan=('#ffffff', .15, .08), stroke=('#f4f2ec', .46, .7), edge=('#ffffff', .16), body_sh='#000000', lift=('#000000', .4)),
}

def icon_c(P, small=False):
    pc, op_near, op_far = P['pan']
    sc, sop, sop_s = P['stroke']
    so = sop_s if small else sop
    if small:
        cw, ch, crx, sw = 360, 440, 70, 16
        sides = [(34, 150, 380, 290, min(1, op_near + .16), 44)]
        sunr, lh, lx = 104, 30, 138
        refl = []
    else:
        cw, ch, crx, sw = 316, 430, 54, 5
        sides = [(16, 108, 376, 316, op_near, 32), (16, 64, 286, 240, op_far, 22)]
        sunr, lh, lx = 86, 14, 150
        refl = [(560, 140, .9), (598, 80, .55)]      # 两道倒影横线：(y, 宽, 不透明度)
    cx0, cx1 = 512 - cw/2, 512 + cw/2
    cy0 = 512 - ch/2
    g = ''
    offs = []; x = cx1
    for gap, w, hi, ho, op, r in sides:
        offs.append((x + gap, x + gap + w, hi, ho, op, r)); x = x + gap + w
    for xa, xb, hi, ho, op, r in reversed(offs):   # 先画远处的玻璃片
        for side in (1, -1):
            mx = (lambda v: v) if side == 1 else (lambda v: 1024 - v)
            d = rpoly([(mx(xa), 512 - hi/2), (mx(xb), 512 - ho/2), (mx(xb), 512 + ho/2), (mx(xa), 512 + hi/2)], r)
            g += f'  <path d="{d}" fill="{pc}" fill-opacity="{op}" stroke="{sc}" stroke-opacity="{so}" stroke-width="{sw}"/>\n'
    rf = ''.join(f'<rect x="{512-w/2}" y="{y}" width="{w}" height="12" rx="6" fill="{P["refl"]}" opacity="{o}"/>' for y, w, o in refl)
    e = 10 if small else 4
    ec, eop = P['edge']
    if small: eop = min(1, eop * 1.3)
    lc, lop = P['lift']
    title = f"C「长卷」· {P['cn']}" + ('（小尺寸简化版）' if small else '')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<!-- 一览 Yilan App 图标 v3 · {title}。macOS 图标网格：1024 画布，824 主体，圆角 185 -->
<defs>
 <clipPath id="body"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>
 <clipPath id="cen"><rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch}" rx="{crx}"/></clipPath>
 <filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="{P['body_sh']}" flood-opacity=".34"/></filter>
 <filter id="lift" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="18"/></filter>
 <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{P['bg'][0]}"/><stop offset="1" stop-color="{P['bg'][1]}"/></linearGradient>
</defs>
<g filter="url(#sh)">
 <g clip-path="url(#body)">
  <rect width="1024" height="1024" fill="url(#bg)"/>
{g}  <rect x="{cx0}" y="{cy0+14}" width="{cw}" height="{ch}" rx="{crx}" fill="{lc}" opacity="{lop}" filter="url(#lift)"/>
  <g clip-path="url(#cen)">
   <rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch/2}" fill="{P['sky']}"/>
   <rect x="{cx0}" y="512" width="{cw}" height="{ch/2}" fill="{P['sea']}"/>
   <path d="M{512-sunr} 512 A{sunr} {sunr} 0 0 1 {512+sunr} 512Z" fill="{P['sun']}"/>
   {rf}
  </g>
  <rect x="{cx0+sw/2}" y="{cy0+sw/2}" width="{cw-sw}" height="{ch-sw}" rx="{crx-sw/2}" fill="none" stroke="{sc}" stroke-opacity="{so}" stroke-width="{sw}"/>
  <rect x="{lx}" y="{512-lh/2}" width="{1024-2*lx}" height="{lh}" rx="{lh/2}" fill="{P['line']}"/>
 </g>
 <rect x="{100+e/2}" y="{100+e/2}" width="{824-e}" height="{824-e}" rx="{185-e/2}" fill="none" stroke="{ec}" stroke-opacity="{eop}" stroke-width="{e}"/>
</g>
</svg>
'''

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for key, P in PALETTES.items():
        open(os.path.join(OUT, f'c-{key}.svg'), 'w').write(icon_c(P, False))
        open(os.path.join(OUT, f'c-{key}-small.svg'), 'w').write(icon_c(P, True))
