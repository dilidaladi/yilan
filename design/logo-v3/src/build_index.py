# 生成 logo-v3/index.html（单文件，SVG 以 data URI 内嵌）
import base64, os
# 以脚本自身位置为基准，不依赖绝对路径
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.normpath(os.path.join(HERE, '..'))
DESIGN = os.path.normpath(os.path.join(HERE, '..', '..'))
def uri(p):
    return 'data:image/svg+xml;base64,' + base64.b64encode(open(p, 'rb').read()).decode()
U = {k: uri(f'{D}/v3-{k}.svg') for k in 'abc'}
US = {k: uri(f'{D}/v3-{k}-small.svg') for k in 'abc'}
U['cur'] = uri(f'{DESIGN}/yilan-icon.svg')
US['cur'] = uri(f'{DESIGN}/yilan-icon-small.svg')

DIRS = [
 dict(k='a', tag='现有图标升级', name='A · 一线天光 · 琉璃',
      desc='在现有「一线天光」上整体升级：圆窗变成一片有厚度的彩色玻璃镜片，天空从靛蓝过渡到紫罗兰、梅紫再到日出暖色，太阳是清晰的半圆，水面是一条长短不一的碎金波光。镜片周围加了一圈暖色环境光，像太阳的光透过玻璃洒在底板上；那道地平线（「一」字）仍然横穿整个镜片。所有玻璃边都是单独一条均匀细线，没有错位的高光。',
      small='小尺寸版：去掉波光，太阳和地平线加粗，底板压暗，16 像素下是「亮圆 + 一横」。'),
 dict(k='b', tag='全新概念', name='B · 重重见光',
      desc='一层套一层的彩色玻璃画框，从外到内由靛蓝、紫罗兰、梅紫一路变到日出暖色，尽头是一道亮光——也就是「一」字。意思是一眼望穿文件夹里的每一张图，直接看到底。没有具体景物，图形最抽象、最对称，和常见的「山 + 太阳」看图图标完全不同。',
      small='小尺寸版：只留两层画框和中间的暖色亮块，一横加粗。'),
 dict(k='c', tag='全新概念', name='C · 长卷',
      desc='五片玻璃排成一道弧形长卷：中间最大的一片是正在看的画面（日出），两边是前后的图片和视频，越远越小，颜色从左边的夜色靛蓝走到右边的晨光暖色。一道地平线的光把五片全部串起来，既是「一」字，也是「一眼看尽整个文件夹」。它最像这个 App 实际的用法（大图 + 一排缩略图，左右切换）。',
      small='小尺寸版：只留中间一片和左右各一片，颜色加实，线条加粗。'),
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
    return f'''
<section class="dir" id="dir-{k}">
  <div class="hero">
    <a href="v3-{k}.svg" title="打开 SVG 源文件"><img class="big" src="{U[k]}" width="512" height="512" alt="{d['name']}"></a>
    <div class="txt">
      <span class="tag">{d['tag']}</span>
      <h2>{d['name']}</h2>
      <p>{d['desc']}</p>
      <p class="small-note">{d['small']}</p>
      <p class="files">源文件：<code>v3-{k}.svg</code>　小尺寸：<code>v3-{k}-small.svg</code></p>
    </div>
  </div>
  <h3>各尺寸（单位：像素；32 和 16 用的是简化版）</h3>
  <div class="row2">{sizes(k, 'dark')}{sizes(k, 'light')}</div>
  <h3>放进 Dock 里的样子（其余是普通占位图标）</h3>
  <div class="row2">{dock(k, 'dark')}{dock(k, 'light')}</div>
</section>'''
def cmp_row(mode):
    items = [('cur', '现有图标'), ('a', 'A · 琉璃'), ('b', 'B · 重重见光'), ('c', 'C · 长卷')]
    cells = ''.join(f'<div class="cmp"><img src="{U[k]}" width="200" height="200" alt=""><div class="mini"><img src="{US[k]}" width="32" height="32" alt=""><img src="{US[k]}" width="16" height="16" alt=""></div><span>{n}</span></div>' for k, n in items)
    return f'<div class="cmprow {mode}">{cells}</div>'

html = f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>一览 图标 v3 · 三个方向</title>
<style>
:root{{--bg:#131318;--panel:#1c1c23;--line:#2e2e38;--ink:#f1f0f5;--mute:#a09fb0;--accent:#ffb07c;--violet:#a58bff}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.75 -apple-system,"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif;-webkit-font-smoothing:antialiased}}
main{{max-width:1120px;margin:0 auto;padding:56px 24px 96px}}
h1{{font-size:34px;line-height:1.25;margin:0 0 10px;letter-spacing:.01em}}
h2{{font-size:26px;line-height:1.3;margin:10px 0 12px}}
h3{{font-size:14px;font-weight:600;color:var(--mute);margin:30px 0 12px}}
p{{margin:0 0 12px}}
.lead{{color:var(--mute);max-width:46em}}
code{{font:13px ui-monospace,Menlo,monospace;background:#26262f;border-radius:5px;padding:2px 6px;color:#d9d6ea}}
.pick{{margin:30px 0 8px;padding:22px 26px;border-radius:18px;background:linear-gradient(135deg,rgba(90,110,255,.16),rgba(255,160,120,.14));border:1px solid rgba(255,255,255,.12)}}
.pick b{{color:var(--accent)}}
.pick h2{{margin-top:0;font-size:20px}}
.pick ul{{margin:8px 0 0;padding-left:1.2em}}
.pick li{{margin:4px 0}}
.dir{{margin-top:44px;padding:30px;border-radius:22px;background:var(--panel);border:1px solid var(--line)}}
.hero{{display:flex;gap:34px;align-items:center;flex-wrap:wrap}}
.hero a{{flex:0 1 512px;min-width:260px;display:block;border-radius:18px;background:radial-gradient(circle at 50% 45%,#2b2b36,#17171d)}}
.big{{display:block;width:100%;height:auto}}
.txt{{flex:1 1 320px;min-width:0}}
.tag{{display:inline-block;font-size:12.5px;font-weight:600;color:#1a1326;background:var(--accent);border-radius:99px;padding:1px 12px}}
#dir-b .tag,#dir-c .tag{{background:var(--violet)}}
.small-note{{color:var(--mute);font-size:14.5px}}
.files{{font-size:13.5px;color:var(--mute)}}
.row2{{display:grid;grid-template-columns:1fr 1fr;gap:16px}}
.sizes{{display:flex;align-items:flex-end;justify-content:center;gap:30px;padding:24px 16px 14px;border-radius:14px;flex-wrap:wrap}}
.sizes.dark{{background:#0e0e12;border:1px solid var(--line)}}
.sizes.light{{background:#ecebef;color:#3b3a45}}
.sz{{display:flex;flex-direction:column;align-items:center;gap:8px}}
.sz img{{display:block}}
.sz span{{font-size:12px;opacity:.75;white-space:nowrap}}
figure{{margin:0}}
.row2>*{{min-width:0}}
.wall{{border-radius:14px;padding:70px 12px 12px;display:flex;flex-direction:column;align-items:center;gap:10px;overflow:hidden}}
.wall.dark{{background:radial-gradient(120% 90% at 20% 0%,#27407a 0%,transparent 60%),radial-gradient(120% 100% at 90% 100%,#5a2a5e 0%,transparent 60%),#0d1226}}
.wall.light{{background:radial-gradient(120% 90% at 15% 0%,#bfe3ff 0%,transparent 60%),radial-gradient(120% 100% at 95% 100%,#ffd9c2 0%,transparent 60%),#e8eef6}}
.dock{{display:flex;align-items:center;gap:2px;padding:6px 8px;border-radius:24px;width:478px;max-width:100%}}
.wall.dark .dock{{background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.22)}}
.wall.light .dock{{background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.8)}}
.dock img{{display:block;flex:0 1 64px;min-width:0;height:auto}}
.ph{{flex:0 1 64px;min-width:0;aspect-ratio:1;display:grid;place-items:center}}
.ph i{{display:block;width:80.5%;height:80.5%;border-radius:22.4%;box-shadow:0 1px 3px rgba(10,8,40,.35)}}
figcaption{{font-size:12px;opacity:.7}}
.wall.light figcaption{{color:#3b3a45}}
.cmprow{{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:24px 12px;border-radius:14px;margin-bottom:16px}}
.cmprow.dark{{background:#0e0e12;border:1px solid var(--line)}}
.cmprow.light{{background:#ecebef;color:#3b3a45}}
.cmp{{display:flex;flex-direction:column;align-items:center;gap:8px;min-width:0}}
.cmp>img{{width:100%;max-width:200px;height:auto}}
.cmp span{{font-size:13.5px;font-weight:600}}
.mini{{display:flex;align-items:center;gap:12px}}
footer{{margin-top:40px;color:var(--mute);font-size:13.5px}}
@media (max-width:760px){{.row2{{grid-template-columns:1fr}}.dir{{padding:20px}}h1{{font-size:27px}}.sizes{{gap:18px}}}}
</style></head>
<body><main>
<h1>一览 Yilan · App 图标第 3 版</h1>
<p class="lead">三个方向，都是原创图形，颜色都取自现有图标（靛蓝、紫罗兰、梅紫、日出暖色），都按 macOS 图标网格绘制（1024 画布、824 圆角方形主体）。玻璃边一律是单独一条均匀细线；没有做眼睛造型，也没有铺满整个画面的日出。</p>

<div class="pick">
  <h2>推荐意见</h2>
  <p><b>推荐 A「一线天光 · 琉璃」。</b>它保留了你已经认可的构图，但颜色、太阳、水面和玻璃质感都明显更精致，在 Dock 里也最醒目，换上去风险最小。</p>
  <ul>
    <li>如果想让图标一眼看出「这是翻看一整个文件夹的图片和视频」，选 <b>C「长卷」</b>——它最贴合 App 的实际用法，也最不容易和别的看图 App 撞车。</li>
    <li><b>B「重重见光」</b>最抽象、最简洁，适合想要一个纯图形标志的情况；但它和「看图」的联系要靠解释。</li>
  </ul>
</div>

{''.join(section(d) for d in DIRS)}

<section class="dir" id="compare">
  <span class="tag" style="background:#d9d6ea">对比</span>
  <h2>和现有图标并排</h2>
  <p class="small-note">每个图标下面的两个小图是 32 和 16 像素的简化版。</p>
  {cmp_row('dark')}{cmp_row('light')}
</section>

<footer>说明：这一页只是设计稿，还没有接进 App。选定方向后再替换 App 里的图标。点击每个方向的大图可以打开对应的 SVG 源文件（1024 像素）。</footer>
</main></body></html>
'''
open(f'{D}/index.html', 'w').write(html)
print(len(html))
