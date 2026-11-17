#!/bin/zsh
# 重新生成第二批配色（palette2），并渲染成 PNG 检查图。用法：render_check2.sh <PNG 输出目录>
HERE=${0:A:h}; D=$HERE/../palette2; O=${1:?需要一个输出目录}
python3 $HERE/gen_palette2.py $D || exit 1
mkdir -p $O; rows=(); big=()
for p in turquoise vermilion sandpine coral; do n=c-$p
  resvg -w 1024 $D/$n.svg $O/$n-1024.png
  resvg -w 512 $D/$n-small.svg $O/$n-s512.png
  for s in 128 64; do resvg -w $s $D/$n.svg $O/$n-$s.png; done
  for s in 32 16; do resvg -w $s $D/$n-small.svg $O/$n-$s.png; done
  magick $O/$n-32.png -filter point -resize 400% $O/$n-32x.png
  magick $O/$n-16.png -filter point -resize 800% $O/$n-16x.png
  magick $O/$n-s512.png -resize 256x256 $O/$n-s256.png
  magick -background '#77777c' $O/$n-s256.png $O/$n-128.png $O/$n-64.png $O/$n-32.png $O/$n-16.png $O/$n-32x.png $O/$n-16x.png -gravity center +append $O/$n-sizes.png
  rows+=($O/$n-sizes.png); big+=($O/$n-1024.png)
done
magick $big -resize 480x480 +append $O/row.png
magick -background '#77777c' $rows -append $O/sizes.png
