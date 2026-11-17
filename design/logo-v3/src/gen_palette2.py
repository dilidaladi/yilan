# 一览图标 v3 · C「长卷」第二批配色（设计师推荐的 4 套）。画法和 gen_palette.py 完全相同，只换颜色
# 用法：python3 gen_palette2.py [输出目录]   （默认输出到 ../palette2）
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_palette import icon_c
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'palette2')

# 字段含义见 gen_palette.py 的 PALETTES
PALETTES2 = {
 # 松石绿：明亮的青绿底板 + 暖奶黄太阳（冷暖互补）
 'turquoise': dict(cn='松石绿',
  bg=('#3fc4b0', '#128a80'), sky='#0e3b3b', sea='#082a2b', sun='#ffe2a0', line='#fffaf0', refl='#ffe2a0',
  pan=('#f2fffb', .32, .18), stroke=('#fbfffd', .8, .92), edge=('#e0fff8', .28), body_sh='#04302c', lift=('#04302c', .3)),
 # 朱砂红：朱漆一样的橙红底板 + 奶金太阳
 'vermilion': dict(cn='朱砂红',
  bg=('#ea5a3a', '#b9301c'), sky='#44150d', sea='#2e0d08', sun='#ffd9a0', line='#fff1de', refl='#ffd9a0',
  pan=('#ffe9da', .3, .17), stroke=('#fff1de', .78, .9), edge=('#ffe0cc', .28), body_sh='#3a0c04', lift=('#3a0c04', .3)),
 # 暖砂松绿：燕麦色浅底 + 松绿线条和玻璃 + 琥珀太阳
 'sandpine': dict(cn='暖砂松绿',
  bg=('#f3ead8', '#e0d2b6'), sky='#fffbf1', sea='#e9dec6', sun='#f0a63a', line='#173a2e', refl='#2f6a55',
  pan=('#1f5a46', .26, .13), stroke=('#173a2e', .82, .92), edge=('#5a4a2a', .2), body_sh='#3a3020', lift=('#4a4028', .2)),
 # 墨青珊瑚：很深的墨青底板 + 珊瑚色太阳和地平线
 'coral': dict(cn='墨青珊瑚',
  bg=('#1a4041', '#0c2223'), sky='#102c2d', sea='#081a1b', sun='#ff8f66', line='#ffc2a4', refl='#ff8f66',
  pan=('#9fe6da', .16, .08), stroke=('#d8f3ee', .46, .7), edge=('#c8fff4', .16), body_sh='#000a0a', lift=('#000a0a', .4)),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for key, P in PALETTES2.items():
        open(os.path.join(OUT, f'c-{key}.svg'), 'w').write(icon_c(P, False))
        open(os.path.join(OUT, f'c-{key}-small.svg'), 'w').write(icon_c(P, True))
