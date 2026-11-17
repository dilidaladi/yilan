# 生成 palette2/index.html：C「长卷」第二批 4 套配色的对比页（单文件，SVG 以 data URI 内嵌）
# 用法：先跑 gen_palette2.py（以及 gen_palette.py），再跑 python3 build_palette2_index.py
import base64, os
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.normpath(os.path.join(HERE, '..', 'palette2'))
P1 = os.path.normpath(os.path.join(HERE, '..', 'palette'))
def uri(p):
    return 'data:image/svg+xml;base64,' + base64.b64encode(open(p, 'rb').read()).decode()
KEYS = ['turquoise', 'vermilion', 'sandpine', 'coral']
U = {k: uri(f'{D}/c-{k}.svg') for k in KEYS}
US = {k: uri(f'{D}/c-{k}-small.svg') for k in KEYS}
for k in ('film', 'graphite'):   # 现有配色，作参照
    U[k] = uri(f'{P1}/c-{k}.svg'); US[k] = uri(f'{P1}/c-{k}-small.svg')

DIRS = [
 dict(k='turquoise', tag='新配色一 · 最推荐', name='松石绿', accent='#3fc4b0',
      sw=['#3fc4b0', '#128a80', '#0e3b3b', '#ffe2a0', '#fffaf0'],
      desc='明亮的青绿色底板，深青色的画面，奶黄色的太阳。底板偏冷、太阳偏暖，两种颜色互相衬托，太阳是全图最亮的一点。',
      pts=[('为什么适合', '青绿让人想到水面和清晨的空气，安静、干净，不抢照片本身的颜色；一点暖黄的太阳又保留了「日出」的主题。'),
           ('Dock 里的辨识度', 'Dock 里蓝色和黄绿色的图标很多，这种介于蓝和绿之间的青绿比较少见；常见的视频播放器 VLC 是橙色，这个颜色也能和它分开。'),
           ('深浅壁纸', '底板是中等明度的鲜亮颜色，深色、浅色壁纸上边界都清楚。'),
           ('16 像素', '清楚：亮色底板 + 深色方块 + 一个亮点，三层明暗分明。'),
           ('当界面品牌色', '青绿在深色界面上很醒目，又不像红色、橙色那样容易被当成「出错」或「警告」，适合做选中框、进度条和按钮。')]),
 dict(k='vermilion', tag='新配色二', name='朱砂红', accent='#f0633f',
      sw=['#ea5a3a', '#b9301c', '#44150d', '#ffd9a0', '#fff1de'],
      desc='朱漆一样的橙红色底板，深褐色的画面，奶金色的太阳。太阳不是红的，底也不是白的，不会让人联想到国旗。',
      pts=[('为什么适合', '颜色最浓、最有东方味道，像漆器和印章；深色画面配暖色太阳，仍然是一幅日出。'),
           ('Dock 里的辨识度', '很抢眼。Dock 里的红色图标不多，而且多半是偏粉的红或红白相间，这种偏橙的朱红加深色方块不容易混。'),
           ('深浅壁纸', '深色、浅色壁纸上都非常显眼。'),
           ('16 像素', '清楚，三套亮色里对比最强。'),
           ('当界面品牌色', '在深色界面上够亮，但红色在界面里通常表示删除、出错，用作选中色时要小心区分；这是它最大的顾虑。')]),
 dict(k='sandpine', tag='新配色三', name='暖砂松绿', accent='#f0a63a',
      sw=['#f3ead8', '#e0d2b6', '#1f5a46', '#173a2e', '#f0a63a'],
      desc='燕麦色的浅底板，线条和玻璃片是松绿色，太阳是琥珀色。是一套浅色方案，但没有红日配白底。',
      pts=[('为什么适合', '像相册的纸页和旧相机的皮套，文气、耐看，适合把它当成一个安静的看图工具。'),
           ('Dock 里的辨识度', '中等。Dock 里白色、浅色的图标很多，它靠松绿的线条和琥珀色的圆点来区分。'),
           ('深浅壁纸', '深色壁纸上很亮、很清楚；浅色壁纸上边界会弱一些。'),
           ('16 像素', '一般：线条变细后主要剩一个浅色方块和琥珀色圆点。'),
           ('当界面品牌色', '松绿太深，放在深色界面上看不清，界面里只能用琥珀色，这样品牌色和图标的主色就不一致了。')]),
 dict(k='coral', tag='新配色四', name='墨青珊瑚', accent='#ff8f66',
      sw=['#1a4041', '#0c2223', '#102c2d', '#ff8f66', '#ffc2a4'],
      desc='很深的墨青色底板和玻璃片，只有太阳和地平线是珊瑚色。是一套深色方案，和石墨金线同一类，但底板带颜色，强调色更暖、更柔。',
      pts=[('为什么适合', '和 App 的深色舞台最接近，图标像是界面的一小块；珊瑚色的太阳像天刚亮的那一下。'),
           ('Dock 里的辨识度', '中等偏低。深色图标在 Dock 里本来就多，它靠珊瑚色的一横一点来认。'),
           ('深浅壁纸', '浅色壁纸上轮廓清楚；深色壁纸上底板会融进背景，只剩珊瑚色的太阳和线。'),
           ('16 像素', '一般：能看到一个珊瑚色亮点和一条线，底板细节看不出。'),
           ('当界面品牌色', '珊瑚色在深色界面上很好看，做选中框、进度条都自然；墨青可以直接当界面的底色。')]),
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
def stage(accent):
    # 深色舞台界面的示意：选中的缩略图、播放进度条、按钮都用品牌色
    thumbs = ''.join(f'<i class="{"on" if i == 3 else ""}"></i>' for i in range(7))
    return f'''<div class="stage" style="--ac:{accent}">
      <div class="view"><div class="bar"><b></b></div></div>
      <div class="strip">{thumbs}</div>
      <div class="btns"><span class="btn">打开文件夹</span><span class="cap">示意：品牌色用在选中框、进度条和按钮上</span></div>
    </div>'''
def section(d):
    k = d['k']
    sw = ''.join(f'<i style="background:{c}"></i>' for c in d['sw'])
    pts = ''.join(f'<li><b>{a}：</b>{b}</li>' for a, b in d['pts'])
    return f'''
<section class="dir" id="dir-{k}">
  <div class="hero">
    <a href="c-{k}.svg" title="打开 SVG 源文件"><img class="big" src="{U[k]}" width="512" height="512" alt="{d['name']}"></a>
    <div class="txt">
      <span class="tag">{d['tag']}</span>
      <h2>{d['name']}</h2>
      <div class="sw">{sw}</div>
      <p>{d['desc']}</p>
      <ul class="pts">{pts}</ul>
      <p class="files">源文件：<code>c-{k}.svg</code>　小尺寸：<code>c-{k}-small.svg</code></p>
    </div>
  </div>
  <h3>各尺寸（单位：像素；32 和 16 用的是简化版）</h3>
  <div class="row2">{sizes(k, 'dark')}{sizes(k, 'light')}</div>
  <h3>放进 Dock 里的样子（其余是普通占位图标）</h3>
  <div class="row2">{dock(k, 'dark')}{dock(k, 'light')}</div>
  <h3>当作界面品牌色，放在深色舞台上</h3>
  {stage(d['accent'])}
</section>'''
ALL = [('turquoise', '松石绿'), ('vermilion', '朱砂红'), ('sandpine', '暖砂松绿'), ('coral', '墨青珊瑚'), ('film', '胶片暖调（现有）'), ('graphite', '石墨金线（现有）')]
def cmp_row(mode):
    cells = ''.join(f'<div class="cmp"><img src="{U[k]}" width="150" height="150" alt=""><div class="mini"><img src="{US[k]}" width="32" height="32" alt=""><img src="{US[k]}" width="16" height="16" alt=""></div><span>{n}</span></div>' for k, n in ALL)
    return f'<div class="cmprow {mode}">{cells}</div>'

html = f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>一览 图标 · 长卷配色第二批</title>
<style>
:root{{--bg:#151514;--panel:#1e1e1c;--line:#32322f;--ink:#f2f0ea;--mute:#a5a299;--accent:#3fc4b0}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.75 -apple-system,"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif;-webkit-font-smoothing:antialiased}}
main{{max-width:1120px;margin:0 auto;padding:56px 24px 96px}}
h1{{font-size:34px;line-height:1.25;margin:0 0 10px;letter-spacing:.01em}}
h2{{font-size:26px;line-height:1.3;margin:10px 0 12px}}
h3{{font-size:14px;font-weight:600;color:var(--mute);margin:30px 0 12px}}
p{{margin:0 0 12px}}
.lead{{color:var(--mute);max-width:46em}}
code{{font:13px ui-monospace,Menlo,monospace;background:#2a2a27;border-radius:5px;padding:2px 6px;color:#e2dfd6}}
.pick{{margin:30px 0 8px;padding:22px 26px;border-radius:18px;background:#1b2523;border:1px solid #2f4a45}}
.pick b{{color:var(--accent)}}
.pick h2{{margin-top:0;font-size:20px}}
.pick ul{{margin:8px 0 0;padding-left:1.2em}}
.pick li{{margin:4px 0}}
.dir{{margin-top:44px;padding:30px;border-radius:22px;background:var(--panel);border:1px solid var(--line)}}
.hero{{display:flex;gap:34px;align-items:flex-start;flex-wrap:wrap}}
.hero a{{flex:0 1 460px;min-width:260px;display:block;border-radius:18px;background:radial-gradient(circle at 50% 45%,#3a3a37,#232321)}}
.big{{display:block;width:100%;height:auto}}
.txt{{flex:1 1 340px;min-width:0}}
.tag{{display:inline-block;font-size:12.5px;font-weight:600;color:#10201d;background:#d8d5cc;border-radius:99px;padding:1px 12px}}
#dir-turquoise .tag{{background:var(--accent)}}
.sw{{display:flex;gap:6px;margin:0 0 14px}}
.sw i{{width:34px;height:20px;border-radius:6px;border:1px solid rgba(255,255,255,.18)}}
.pts{{margin:0 0 14px;padding-left:1.15em;font-size:14.5px;line-height:1.7;color:#d9d6ce}}
.pts li{{margin:5px 0}}
.pts b{{color:var(--ink)}}
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
.wall.dark{{background:radial-gradient(120% 90% at 20% 0%,#3a3550 0%,transparent 60%),radial-gradient(120% 100% at 90% 100%,#4a3324 0%,transparent 60%),#14151c}}
.wall.light{{background:radial-gradient(120% 90% at 15% 0%,#d6e4f4 0%,transparent 60%),radial-gradient(120% 100% at 95% 100%,#f6e2c8 0%,transparent 60%),#e9eef0}}
.dock{{display:flex;align-items:center;gap:2px;padding:6px 8px;border-radius:24px;width:478px;max-width:100%}}
.wall.dark .dock{{background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.22)}}
.wall.light .dock{{background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.8)}}
.dock img{{display:block;flex:0 1 64px;min-width:0;height:auto}}
.ph{{flex:0 1 64px;min-width:0;aspect-ratio:1;display:grid;place-items:center}}
.ph i{{display:block;width:80.5%;height:80.5%;border-radius:22.4%;box-shadow:0 1px 3px rgba(0,0,0,.35)}}
figcaption{{font-size:12px;opacity:.7}}
.wall.light figcaption{{color:#3d3b36}}
.stage{{background:#0c0c0d;border:1px solid var(--line);border-radius:14px;padding:16px;display:flex;flex-direction:column;gap:12px}}
.view{{height:120px;border-radius:10px;background:linear-gradient(180deg,#2c2c2e,#1a1a1c);position:relative}}
.bar{{position:absolute;left:16px;right:16px;bottom:14px;height:5px;border-radius:3px;background:rgba(255,255,255,.16)}}
.bar b{{display:block;width:42%;height:100%;border-radius:3px;background:var(--ac)}}
.strip{{display:flex;gap:8px;justify-content:center}}
.strip i{{flex:0 1 64px;aspect-ratio:4/3;border-radius:7px;background:#2a2a2d;min-width:0}}
.strip i.on{{background:#3a3a3e;outline:2px solid var(--ac);outline-offset:2px}}
.btns{{display:flex;align-items:center;gap:14px;flex-wrap:wrap}}
.btn{{background:var(--ac);color:#101010;font-size:13px;font-weight:600;border-radius:8px;padding:3px 14px}}
.cap{{font-size:12px;color:var(--mute)}}
.cmprow{{display:grid;grid-template-columns:repeat(6,1fr);gap:6px;padding:24px 10px;border-radius:14px;margin-bottom:16px}}
.cmp{{display:flex;flex-direction:column;align-items:center;gap:8px;min-width:0;text-align:center}}
.cmp>img{{width:100%;max-width:150px;height:auto}}
.cmp span{{font-size:13px;font-weight:600}}
.mini{{display:flex;align-items:center;gap:12px}}
footer{{margin-top:40px;color:var(--mute);font-size:13.5px}}
@media (max-width:760px){{.row2{{grid-template-columns:1fr}}.cmprow{{grid-template-columns:repeat(3,1fr)}}.dir{{padding:20px}}h1{{font-size:27px}}.sizes{{gap:18px}}}}
</style></head>
<body><main>
<h1>一览 Yilan · 「长卷」图标配色第二批</h1>
<p class="lead">构图和画法不变，还是抽象简约的「长卷」：平涂色块、半个太阳、一条地平线、两道倒影线、两侧四片玻璃。这一页是另外 4 套新配色，都不用蓝紫色和霓虹渐变，也没有红日配白底。每一套都按同样几条来衡量：适不适合看图看视频、Dock 里好不好认、深浅壁纸上的效果、16 像素清不清楚、能不能当深色界面的品牌色。</p>

<div class="pick">
  <h2>在新旧所有配色里，最推荐「松石绿」</h2>
  <p><b>理由：</b>它是唯一一套同时满足三件事的——在 Dock 里颜色少见、好认；16 像素下明暗分三层，仍然清楚；青绿拿到深色界面里当品牌色很醒目，又不会像红色、橙色那样被误读成「出错」或「警告」。冷色底板配暖色太阳，日出的主题也还在。</p>
  <ul>
    <li><b>第二选择「胶片暖调」</b>（现有）：最有温度，同样清楚；顾虑是橙色容易让人想到另一个常见的播放器 VLC。</li>
    <li><b>「朱砂红」</b>最抢眼、最有东方味道，但红色当界面品牌色时容易和「删除、出错」混淆。</li>
    <li><b>「墨青珊瑚」「石墨金线」</b>和深色界面最统一，但在深色 Dock 里不够显眼；<b>「暖砂松绿」</b>耐看，但小尺寸和品牌色两项偏弱。</li>
  </ul>
</div>

{''.join(section(d) for d in DIRS)}

<section class="dir" id="compare">
  <span class="tag">对比</span>
  <h2>新旧配色并排</h2>
  <p class="files">前四个是这一批的新配色，后两个是现有的胶片暖调和石墨金线，作参照。每个图标下面的两个小图是 32 和 16 像素的简化版。</p>
  {cmp_row('dark')}{cmp_row('light')}
</section>

<footer>说明：这一页只是设计稿，还没有接进 App。Dock 里其余图标是占位色块，不是真实的系统图标；「辨识度」是按常见系统图标的颜色做的判断，没有放进真实的 Dock 里验证。点击每套配色的大图可以打开对应的 SVG 源文件（1024 像素）。</footer>
</main></body></html>
'''
open(f'{D}/index.html', 'w').write(html)
print(len(html))
