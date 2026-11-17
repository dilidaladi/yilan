# 生成 一览 图标 v3 的三个方向（各含完整版与小尺寸版）
import math, os, sys
OUT = sys.argv[1]

def stops(lst):
    s = ''
    for st in lst:
        off, col = st[0], st[1]
        op = st[2] if len(st) > 2 else None
        s += f'<stop offset="{off}" stop-color="{col}"' + (f' stop-opacity="{op}"' if op is not None else '') + '/>'
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

COMMON_DEFS = '''
 <clipPath id="body"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>
 <filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="#0a0828" flood-opacity=".38"/></filter>
 <filter id="b12" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="12"/></filter>
 <filter id="b24" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="24"/></filter>
 <filter id="b50" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="50"/></filter>
'''
def wrap(title, defs, inner, edge=4, edge_op=.24):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<!-- 一览 Yilan App 图标 v3 · {title}。macOS 图标网格：1024 画布，824 主体，圆角 185 -->
<defs>{COMMON_DEFS}{defs}</defs>
<g filter="url(#sh)">
 <g clip-path="url(#body)">
{inner}
 </g>
 <rect x="{100+edge/2}" y="{100+edge/2}" width="{824-edge}" height="{824-edge}" rx="{185-edge/2}" fill="none" stroke="#fff" stroke-opacity="{edge_op}" stroke-width="{edge}"/>
</g>
</svg>
'''

# ---------------------------------------------------------------- A 一线天光 · 琉璃
def icon_a(small=False):
    R = 312 if small else 300
    sunr = 136 if small else 96
    rim = 16 if small else 5
    top, bot = 512 - R, 512 + R
    defs = (
     lin('bg', 0, 0, 1, 1, [(0, '#131a66'), (.5, '#2a1a72'), (1, '#58285e')] if small else [(0, '#1c2a8e'), (.5, '#44299a'), (1, '#8e3a7c')]) +
     rad('cool', 290, 230, 470, [(0, '#5f86ff', .6), (1, '#5f86ff', 0)], True) +
     rad('warm', 512, 540, 500, [(0, '#ff9a6e', .8), (.6, '#ff8a78', .3 if small else .62), (.8, '#f0708c', .1 if small else .25), (1, '#f0708c', 0)], True) +
     lin('caus', 0, 512, 0, bot, [(0, '#b9a2ff', 0), (.45, '#b9a2ff', 0), (1, '#b9a2ff', .3)], True) +
     lin('sky', 0, top, 0, 512, [(0, '#1f36a8'), (.38, '#5a44b8'), (.66, '#b85aa6'), (.86, '#f0808c'), (1, '#ffbe86')], True) +
     lin('sea', 0, 512, 0, bot, [(0, '#f7a482'), (.2, '#c45f94'), (.55, '#5c3893'), (1, '#1f2970')], True) +
     rad('glow', 512, 512, 250, [(0, '#fff0cc', .95), (.3, '#ffc890', .6), (1, '#ff9a6a', 0)], True) +
     rad('sun', 512, 512, sunr, [(0, '#fffdf4'), (.6, '#fff0cf'), (1, '#ffd596')], True) +
     rad('refl', .5, .5, .5, [(0, '#ffe2b8', .85), (.45, '#ffb48a', .3), (1, '#ffb48a', 0)]) +
     lin('rp', 0, 0, 1, 0, [(0, '#ffe6c8', 0), (.5, '#fff1dc'), (1, '#ffe6c8', 0)]) +
     lin('ln', 0, 0, 1, 0, [(0, '#fff', 0), (.16, '#ffe9cf', .85), (.5, '#fff'), (.84, '#ffe9cf', .85), (1, '#fff', 0)]) +
     rad('vg', 512, 512, R, [(.8, '#0a0a30', 0), (1, '#0a0a30', .38)], True) +
     rad('gloss', .5, .5, .5, [(0, '#fff', .2), (1, '#fff', 0)]) +
     f'<clipPath id="lens"><circle cx="512" cy="512" r="{R}"/></clipPath>'
     '<clipPath id="up"><rect x="0" y="0" width="1024" height="512"/></clipPath>'
     '<clipPath id="dn"><rect x="0" y="512" width="1024" height="512"/></clipPath>'
    )
    ripples = [(542, 240, 10, .95, 0), (568, 176, 9, .85, 12), (596, 204, 8, .72, -10), (627, 138, 8, .6, 8),
               (660, 150, 7, .46, -6), (695, 92, 6, .36, 5), (730, 66, 5, .26, 0)]
    rp = '' if small else ''.join(
        f'<rect x="{512+dx-w/2}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="url(#rp)" opacity="{o}"/>' for y, w, h, o, dx in ripples)
    inner = f'''  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#cool)"/>
  <rect width="1024" height="1024" fill="url(#warm)"/>
  <circle cx="512" cy="536" r="{R}" fill="#120a3c" opacity=".5" filter="url(#b24)"/>
  <g clip-path="url(#lens)">
   <rect x="{top}" y="{top}" width="{2*R}" height="{R}" fill="url(#sky)"/>
   <g clip-path="url(#up)"><circle cx="512" cy="512" r="250" fill="url(#glow)"/><circle cx="512" cy="512" r="{sunr}" fill="url(#sun)"/></g>
   <rect x="{top}" y="512" width="{2*R}" height="{R}" fill="url(#sea)"/>
   <ellipse cx="512" cy="512" rx="190" ry="{R*.92}" fill="url(#refl)" clip-path="url(#dn)"/>
   {rp}
   <ellipse cx="410" cy="330" rx="250" ry="130" transform="rotate(-28 410 330)" fill="url(#gloss)" opacity="{0 if small else 1}"/>
   <circle cx="512" cy="512" r="{R-20}" fill="none" stroke="url(#caus)" stroke-width="30" filter="url(#b12)" opacity="{0 if small else 1}"/>
   <circle cx="512" cy="512" r="{R}" fill="url(#vg)"/>
  </g>
  <circle cx="512" cy="512" r="{R-rim/2}" fill="none" stroke="#fff" stroke-opacity="{.78 if small else .62}" stroke-width="{rim}"/>
  <path d="{streak(120, 904, 512, 46 if small else 15)}" fill="url(#ln)"/>'''
    return wrap('A「一线天光 · 琉璃」' + ('（小尺寸简化版）' if small else ''), defs, inner, edge=10 if small else 4, edge_op=.3 if small else .24)

# ---------------------------------------------------------------- B 重重见光
def icon_b(small=False):
    if small:
        frames = [(640, 150, '#6f8cff', .4, .55), (430, 104, '#b070f5', .6, .65)]
        core = 0; sw = 16
    else:
        frames = [(616, 150, '#5a7dff', .36, .42), (468, 112, '#9a66ff', .46, .48), (324, 78, '#e868b8', .55, .54)]
        core = 184; sw = 5
    defs = (
     lin('bg', 0, 0, 1, 1, [(0, '#111860'), (.5, '#28196c'), (1, '#52245a')] if small else [(0, '#161f78'), (.5, '#38248a'), (1, '#7a3274')]) +
     rad('cool', 280, 230, 480, [(0, '#4f74ff', .5), (1, '#4f74ff', 0)], True) +
     rad('warm', 512, 512, 430, [(0, '#ff9c74', .6), (.5, '#f07a9a', .32), (1, '#f07a9a', 0)], True) +
     lin('sheen', 0, 0, 0, 1, [(0, '#fff', .2), (.4, '#fff', .02), (1, '#fff', 0)]) +
     lin('core', 0, 0, 0, 1, [(0, '#ff7f96'), (.5, '#ffa474'), (1, '#ffcf7c')]) +
     rad('flare', .5, .5, .5, [(0, '#fff3da', .95), (.4, '#ffc48e', .45), (1, '#ffb080', 0)]) +
     lin('ln', 0, 0, 1, 0, [(0, '#fff', 0), (.2, '#fff3e2', .95), (.5, '#fff'), (.8, '#fff3e2', .95), (1, '#fff', 0)])
    )
    g = ''
    for i, (s, rx, col, op, sop) in enumerate(frames):
        x = 512 - s/2
        g += f'''  <rect x="{x}" y="{x+14}" width="{s}" height="{s}" rx="{rx}" fill="#0e0a3a" opacity=".42" filter="url(#b24)"/>
  <rect x="{x}" y="{x}" width="{s}" height="{s}" rx="{rx}" fill="{col}" fill-opacity="{op}"/>
  <rect x="{x}" y="{x}" width="{s}" height="{s}" rx="{rx}" fill="url(#sheen)"/>
  <rect x="{x+sw/2}" y="{x+sw/2}" width="{s-sw}" height="{s-sw}" rx="{rx-sw/2}" fill="none" stroke="#fff" stroke-opacity="{sop}" stroke-width="{sw}"/>
'''
    if small:
        g += f'''  <rect x="402" y="402" width="220" height="220" rx="56" fill="url(#core)"/>
  <path d="{streak(150, 874, 512, 50)}" fill="url(#ln)"/>'''
    else:
        x = 512 - core/2
        g += f'''  <rect x="{x}" y="{x+12}" width="{core}" height="{core}" rx="46" fill="#0e0a3a" opacity=".4" filter="url(#b24)"/>
  <rect x="{x}" y="{x}" width="{core}" height="{core}" rx="46" fill="url(#core)" fill-opacity=".94"/>
  <rect x="{x}" y="{x}" width="{core}" height="{core}" rx="46" fill="url(#sheen)"/>
  <rect x="{x+2.5}" y="{x+2.5}" width="{core-5}" height="{core-5}" rx="43.5" fill="none" stroke="#fff" stroke-opacity=".62" stroke-width="5"/>
  <ellipse cx="512" cy="512" rx="210" ry="70" fill="url(#flare)"/>
  <path d="{streak(150, 874, 512, 15)}" fill="url(#ln)"/>'''
    inner = f'''  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#cool)"/>
  <rect width="1024" height="1024" fill="url(#warm)"/>
{g}'''
    return wrap('B「重重见光」' + ('（小尺寸简化版）' if small else ''), defs, inner, edge=10 if small else 4, edge_op=.3 if small else .24)

# ---------------------------------------------------------------- C 长卷
def icon_c(small=False):
    if small:
        cw, ch, crx, sw = 360, 440, 70, 16
        sides = [(34, 150, 380, 290, '#7f86ff', '#ff8a9c', 44)]
        s_op = .7
    else:
        cw, ch, crx, sw = 316, 396, 52, 5
        sides = [(16, 108, 344, 290, '#8f78f8', '#f47aa6', 32), (16, 64, 262, 220, '#5f7eff', '#ffae78', 22)]
        s_op = .5
    cx0, cx1 = 512 - cw/2, 512 + cw/2
    cy0, cy1 = 512 - ch/2, 512 + ch/2
    sunr = 96 if small else 70
    defs = (
     lin('bg', 0, 0, 1, 1, [(0, '#121962'), (.5, '#291a6e'), (1, '#54265c')] if small else [(0, '#1a2688'), (.5, '#402892'), (1, '#883a78')]) +
     rad('cool', 250, 300, 460, [(0, '#5578ff', .55), (1, '#5578ff', 0)], True) +
     rad('warm', 760, 620, 480, [(0, '#ff946c', .6), (1, '#ff946c', 0)], True) +
     rad('halo', 512, 512, 330, [(0, '#ffb890', .25 if small else .6), (1, '#ffb890', 0)], True) +
     lin('sky', 0, cy0, 0, 512, [(0, '#2238ac'), (.45, '#6a48b8'), (.78, '#d86a9c'), (1, '#ffbe86')], True) +
     lin('sea', 0, 512, 0, cy1, [(0, '#f7a482'), (.3, '#b0528f'), (1, '#262c76')], True) +
     rad('glow', 512, 512, 170, [(0, '#fff0cc', .95), (.35, '#ffc890', .55), (1, '#ff9a6a', 0)], True) +
     rad('sun', 512, 512, sunr, [(0, '#fffdf4'), (.6, '#fff0cf'), (1, '#ffd596')], True) +
     rad('refl', .5, .5, .5, [(0, '#ffe2b8', .85), (.45, '#ffb48a', .3), (1, '#ffb48a', 0)]) +
     lin('rp', 0, 0, 1, 0, [(0, '#ffe6c8', 0), (.5, '#fff1dc'), (1, '#ffe6c8', 0)]) +
     lin('sheen', 0, 0, 0, 1, [(0, '#fff', .3), (.5, '#fff', .05), (1, '#fff', 0)]) +
     lin('ln', 0, 0, 1, 0, [(0, '#fff', 0), (.14, '#ffe9cf', .8), (.5, '#fff'), (.86, '#ffe9cf', .8), (1, '#fff', 0)]) +
     f'<clipPath id="cen"><rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch}" rx="{crx}"/></clipPath>'
     '<clipPath id="up"><rect x="0" y="0" width="1024" height="512"/></clipPath>'
     '<clipPath id="dn"><rect x="0" y="512" width="1024" height="512"/></clipPath>'
    )
    g = ''
    # 侧面玻璃片：先画远的
    offs = []
    x = cx1
    for gap, w, hi, ho, cl, cr, r in sides:
        offs.append((x + gap, x + gap + w, hi, ho, cl, cr, r)); x = x + gap + w
    for xa, xb, hi, ho, cl, cr, r in reversed(offs):
        for side, col in ((1, cr), (-1, cl)):
            def mx(v): return v if side == 1 else 1024 - v
            pts = [(mx(xa), 512 - hi/2), (mx(xb), 512 - ho/2), (mx(xb), 512 + ho/2), (mx(xa), 512 + hi/2)]
            d = rpoly(pts, r)
            g += f'''  <path d="{d}" fill="#0e0a3a" opacity=".4" filter="url(#b24)" transform="translate(0 12)"/>
  <path d="{d}" fill="{col}" fill-opacity="{.8 if small else .5}"/>
  <path d="{d}" fill="url(#sheen)"/>
  <path d="{d}" fill="none" stroke="#fff" stroke-opacity="{s_op}" stroke-width="{sw}" clip-path="none"/>
'''
    ripples = [(538, 168, 8, .95, 0), (562, 120, 7, .8, 9), (588, 138, 7, .65, -8), (616, 88, 6, .5, 5), (646, 60, 5, .36, 0)]
    rp = '' if small else ''.join(
        f'<rect x="{512+dx-w/2}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="url(#rp)" opacity="{o}"/>' for y, w, h, o, dx in ripples)
    g += f'''  <rect x="{cx0}" y="{cy0+16}" width="{cw}" height="{ch}" rx="{crx}" fill="#0e0a3a" opacity=".5" filter="url(#b24)"/>
  <g clip-path="url(#cen)">
   <rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch/2}" fill="url(#sky)"/>
   <g clip-path="url(#up)"><circle cx="512" cy="512" r="170" fill="url(#glow)"/><circle cx="512" cy="512" r="{sunr}" fill="url(#sun)"/></g>
   <rect x="{cx0}" y="512" width="{cw}" height="{ch/2}" fill="url(#sea)"/>
   <ellipse cx="512" cy="512" rx="{cw*.42}" ry="{ch*.46}" fill="url(#refl)" clip-path="url(#dn)"/>
   {rp}
  </g>
  <rect x="{cx0+sw/2}" y="{cy0+sw/2}" width="{cw-sw}" height="{ch-sw}" rx="{crx-sw/2}" fill="none" stroke="#fff" stroke-opacity="{.8 if small else .66}" stroke-width="{sw}"/>
  <path d="{streak(120, 904, 512, 40 if small else 13)}" fill="url(#ln)"/>'''
    inner = f'''  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#cool)"/>
  <rect width="1024" height="1024" fill="url(#warm)"/>
  <rect width="1024" height="1024" fill="url(#halo)"/>
{g}'''
    return wrap('C「长卷」' + ('（小尺寸简化版）' if small else ''), defs, inner, edge=10 if small else 4, edge_op=.3 if small else .24)

for name, fn in (('a', icon_a), ('b', icon_b), ('c', icon_c)):
    open(os.path.join(OUT, f'v3-{name}.svg'), 'w').write(fn(False))
    open(os.path.join(OUT, f'v3-{name}-small.svg'), 'w').write(fn(True))
