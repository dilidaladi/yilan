# 生成 palette/index.html：C「长卷」3 套配色的对比页（单文件，SVG 以 data URI 内嵌）
# 用法：先跑 gen_palette.py，再跑 python3 build_palette_index.py
import base64, os
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.normpath(os.path.join(HERE, '..', 'palette'))
V3 = os.path.normpath(os.path.join(HERE, '..'))
def uri(p):
    return 'data:image/svg+xml;base64,' + base64.b64encode(open(p, 'rb').read()).decode()
KEYS = ['film', 'ink', 'graphite']
U = {k: uri(f'{D}/c-{k}.svg') for k in KEYS}
US = {k: uri(f'{D}/c-{k}-small.svg') for k in KEYS}
U['old'] = uri(f'{V3}/v3-c.svg'); US['old'] = uri(f'{V3}/v3-c-small.svg')
for k in KEYS:   # 上一版（写实）留作参照
    U['r-' + k] = uri(f'{D}/prev-realistic/c-{k}.svg'); US['r-' + k] = uri(f'{D}/prev-realistic/c-{k}-small.svg')

DIRS = [
 dict(k='film', tag='配色一', name='胶片暖调',
      sw=['#eda94c', '#cf6a2c', '#6b2f17', '#ffd88a', '#fff4de'],
      desc='暖橙色的底板，中间是一块深赭色的画面，里面只有三样东西：半个暖黄的太阳、一条地平线、两道倒影横线。两侧四片是同一种奶白色的半透明玻璃，只靠深浅区分远近。',
      small='在 Dock 里最显眼：暖橙色的看图工具很少见，和一排蓝色图标放在一起一眼能找到。'),
 dict(k='ink', tag='配色二', name='东方墨色',
      sw=['#faf6ed', '#e6e0d2', '#8f8a80', '#1f1c19', '#d8412a'],
      desc='宣纸白的底板，墨线勾出五片玻璃，一道墨色的地平线「一」横穿过去，上面是半轮朱砂红的太阳。全图只有黑、白、灰和一点红。',
      small='最克制、最有辨识度，也是三套里唯一的浅色图标；在浅色壁纸上会比另外两套低调一些。'),
 dict(k='graphite', tag='配色三', name='石墨金线',
      sw=['#35373c', '#18191c', '#111214', '#f2c060', '#ffe2a0'],
      desc='石墨黑的底板和玻璃，只有太阳、地平线和倒影是暖金色，像相机机身上的一道金线。',
      small='和 App 的深色舞台界面最搭；在深色 Dock 里靠金线和太阳来辨认，底板本身比较暗。'),
]
PH = ['linear-gradient(160deg,#5aa9ff,#2f6fe0)', 'linear-gradient(160deg,#ffd76a,#f0a321)', 'linear-gradient(160deg,#6fe0a0,#22a865)',
      'linear-gradient(160deg,#f4f5f7,#cfd3da)', 'linear-gradient(160deg,#ff8f7a,#e0483e)', 'linear-gradient(160deg,#55565c,#232428)']
def ph(i): return f'<span class="ph"><i style="background:{PH[i]}"></i></span>'
def dock(k, mode):
    icons = ph(0) + ph(1) + ph(3) + f'<img src="{U[k]}" width="64" height="64" alt="">' + ph(2) + ph(4) + ph(5)
    label = '深色壁纸' if mode == 'dark' else '浅色壁纸'
    return f'<figure class="wall {mode}"><div class="dock">{icons}</div><figcaption>{label}下的 Dock</figcaption></figure>'
def sizes(k, mode):
    cells = ''
    for s in (128, 64, 32, 16):
        src = U[k] if s >= 64 else US[k]
        note = '' if s >= 64 else '（简化版）'
        cells += f'<div class="sz"><img src="{src}" width="{s}" height="{s}" alt=""><span>{s}{note}</span></div>'
    return f'<div class="sizes {mode}">{cells}</div>'
def section(d):
    k = d['k']
    sw = ''.join(f'<i style="background:{c}"></i>' for c in d['sw'])
    return f'''
<section class="dir" id="dir-{k}">
  <div class="hero">
    <a href="c-{k}.svg" title="打开 SVG 源文件"><img class="big" src="{U[k]}" width="512" height="512" alt="{d['name']}"></a>
    <div class="txt">
      <span class="tag">{d['tag']}</span>
      <h2>{d['name']}</h2>
      <div class="sw">{sw}</div>
      <p>{d['desc']}</p>
      <p class="small-note">{d['small']}</p>
      <p class="files">源文件：<code>c-{k}.svg</code>　小尺寸：<code>c-{k}-small.svg</code></p>
    </div>
  </div>
  <h3>各尺寸（单位：像素；32 和 16 用的是简化版）</h3>
  <div class="row2">{sizes(k, 'dark')}{sizes(k, 'light')}</div>
  <h3>放进 Dock 里的样子（其余是普通占位图标）</h3>
  <div class="row2">{dock(k, 'dark')}{dock(k, 'light')}</div>
</section>'''
def cmp_row(mode, items):
    cells = ''.join(f'<div class="cmp"><img src="{U[k]}" width="200" height="200" alt=""><div class="mini"><img src="{US[k]}" width="32" height="32" alt=""><img src="{US[k]}" width="16" height="16" alt=""></div><span>{n}</span></div>' for k, n in items)
    return f'<div class="cmprow {mode}">{cells}</div>'
NEW = [('film', '胶片暖调'), ('ink', '东方墨色'), ('graphite', '石墨金线'), ('old', '更早的 v3-C（蓝紫）')]
REAL = [('r-film', '胶片暖调（写实）'), ('r-ink', '东方墨色（写实）'), ('r-graphite', '石墨金线（写实）')]

html = f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>一览 图标 · 长卷配色</title>
<style>
:root{{--bg:#151514;--panel:#1e1e1c;--line:#32322f;--ink:#f2f0ea;--mute:#a5a299;--accent:#e9a24a}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.75 -apple-system,"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif;-webkit-font-smoothing:antialiased}}
main{{max-width:1120px;margin:0 auto;padding:56px 24px 96px}}
h1{{font-size:34px;line-height:1.25;margin:0 0 10px;letter-spacing:.01em}}
h2{{font-size:26px;line-height:1.3;margin:10px 0 12px}}
h3{{font-size:14px;font-weight:600;color:var(--mute);margin:30px 0 12px}}
p{{margin:0 0 12px}}
.lead{{color:var(--mute);max-width:46em}}
code{{font:13px ui-monospace,Menlo,monospace;background:#2a2a27;border-radius:5px;padding:2px 6px;color:#e2dfd6}}
.pick{{margin:30px 0 8px;padding:22px 26px;border-radius:18px;background:#24221d;border:1px solid #4a4132}}
.pick b{{color:var(--accent)}}
.pick h2{{margin-top:0;font-size:20px}}
.pick ul{{margin:8px 0 0;padding-left:1.2em}}
.pick li{{margin:4px 0}}
.dir{{margin-top:44px;padding:30px;border-radius:22px;background:var(--panel);border:1px solid var(--line)}}
.hero{{display:flex;gap:34px;align-items:center;flex-wrap:wrap}}
.hero a{{flex:0 1 512px;min-width:260px;display:block;border-radius:18px;background:radial-gradient(circle at 50% 45%,#3a3a37,#232321)}}
.big{{display:block;width:100%;height:auto}}
.txt{{flex:1 1 320px;min-width:0}}
.tag{{display:inline-block;font-size:12.5px;font-weight:600;color:#1c1608;background:var(--accent);border-radius:99px;padding:1px 12px}}
.sw{{display:flex;gap:6px;margin:0 0 14px}}
.sw i{{width:34px;height:20px;border-radius:6px;border:1px solid rgba(255,255,255,.18)}}
.small-note{{color:var(--mute);font-size:14.5px}}
.files{{font-size:13.5px;color:var(--mute)}}
.row2{{display:grid;grid-template-columns:1fr 1fr;gap:16px}}
.row2>*{{min-width:0}}
.sizes{{display:flex;align-items:flex-end;justify-content:center;gap:30px;padding:24px 16px 14px;border-radius:14px;flex-wrap:wrap}}
.sizes.dark,.cmprow.dark{{background:#0e0e0d;border:1px solid var(--line)}}
.sizes.light,.cmprow.light{{background:#ecebe7;color:#3d3b36}}
.sz{{display:flex;flex-direction:column;align-items:center;gap:8px}}
.sz img{{display:block}}
.sz span{{font-size:12px;opacity:.75;white-space:nowrap}}
figure{{margin:0}}
.wall{{border-radius:14px;padding:70px 12px 12px;display:flex;flex-direction:column;align-items:center;gap:10px;overflow:hidden}}
.wall.dark{{background:radial-gradient(120% 90% at 20% 0%,#23463f 0%,transparent 60%),radial-gradient(120% 100% at 90% 100%,#4a3324 0%,transparent 60%),#10161a}}
.wall.light{{background:radial-gradient(120% 90% at 15% 0%,#cfe8f4 0%,transparent 60%),radial-gradient(120% 100% at 95% 100%,#f6e2c8 0%,transparent 60%),#e9eef0}}
.dock{{display:flex;align-items:center;gap:2px;padding:6px 8px;border-radius:24px;width:478px;max-width:100%}}
.wall.dark .dock{{background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.22)}}
.wall.light .dock{{background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.8)}}
.dock img{{display:block;flex:0 1 64px;min-width:0;height:auto}}
.ph{{flex:0 1 64px;min-width:0;aspect-ratio:1;display:grid;place-items:center}}
.ph i{{display:block;width:80.5%;height:80.5%;border-radius:22.4%;box-shadow:0 1px 3px rgba(0,0,0,.35)}}
figcaption{{font-size:12px;opacity:.7}}
.wall.light figcaption{{color:#3d3b36}}
.cmprow{{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:24px 12px;border-radius:14px;margin-bottom:16px}}
.cmp{{display:flex;flex-direction:column;align-items:center;gap:8px;min-width:0;text-align:center}}
.cmp>img{{width:100%;max-width:200px;height:auto}}
.cmp span{{font-size:13.5px;font-weight:600}}
.mini{{display:flex;align-items:center;gap:12px}}
footer{{margin-top:40px;color:var(--mute);font-size:13.5px}}
@media (max-width:760px){{.row2{{grid-template-columns:1fr}}.cmprow{{grid-template-columns:1fr 1fr}}.dir{{padding:20px}}h1{{font-size:27px}}.sizes{{gap:18px}}}}
</style></head>
<body><main>
<h1>一览 Yilan · 「长卷」图标的三套配色</h1>
<p class="lead">构图沿用已经选定的 C「长卷」：中间一张正在看的画面，两边是前后的图片和视频，一条地平线（「一」字）把它们串起来。这一版改成抽象、简约的画法：全部是平面色块，没有云、山、波光、光晕、暗角和纹理；中间只留半个太阳、一条地平线和两道倒影横线。不用蓝紫色，玻璃描边是单独一条均匀细线。</p>

<div class="pick">
  <h2>推荐意见</h2>
  <p><b>推荐「胶片暖调」。</b>它和原来的日出主题一脉相承，颜色最有温度，在 Dock 里最容易找到，小尺寸下也最清楚；暖橙色的看图 App 很少，不会像 AI 产品。</p>
  <ul>
    <li>想要更安静、更有专业相机气质，并且和 App 的深色界面统一，选 <b>「石墨金线」</b>。</li>
    <li>想要最特别、最有东方味道的，选 <b>「东方墨色」</b>；它是浅色图标，那半轮朱砂红日很好认。</li>
  </ul>
</div>

{''.join(section(d) for d in DIRS)}

<section class="dir" id="compare">
  <span class="tag" style="background:#d8d5cc">对比</span>
  <h2>和之前的版本并排</h2>
  <p class="small-note">每个图标下面的两个小图是 32 和 16 像素的简化版。</p>
  <h3>这一版（抽象简约），最右边是更早的蓝紫 v3-C</h3>
  {cmp_row('dark', NEW)}{cmp_row('light', NEW)}
  <h3>上一版（写实），只作参照</h3>
  {cmp_row('dark', REAL)}
</section>

<footer>说明：这一页只是设计稿，还没有接进 App。选定配色后再替换 App 里的图标。点击每套配色的大图可以打开对应的 SVG 源文件（1024 像素）。</footer>
</main></body></html>
'''
open(f'{D}/index.html', 'w').write(html)
print(len(html))
