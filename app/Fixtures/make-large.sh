#!/bin/zsh
# 生成一个 1000 个文件的文件夹，用于测试缩略图栏滚动和预加载性能。
# 用法：./make-large.sh [数量，默认 1000] [目标目录，默认 /tmp/yilan-large]
# 文件是对 sample 里图片/视频的硬链接（不占额外磁盘），名字带序号，检验自然排序。
set -euo pipefail

COUNT=${1:-1000}
DEST=${2:-/tmp/yilan-large}
SRC_DIR="${0:A:h}/sample"

# 只用能正常打开的文件做素材（不含 broken.jpg 和 notes.txt）
sources=()
for f in "$SRC_DIR"/*.(jpg|png|heic|tif|bmp|gif|svg|mp4|mov)(N); do
  [[ "${f:t}" == "broken.jpg" ]] && continue
  sources+=("$f")
done
(( ${#sources} > 0 )) || { echo "没有找到素材：$SRC_DIR" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"
for (( i = 1; i <= COUNT; i++ )); do
  src=${sources[$(( (i - 1) % ${#sources} + 1 ))]}
  ext=${src:e}
  # 硬链接失败（跨磁盘）时退回复制
  ln "$src" "$DEST/photo_$i.$ext" 2>/dev/null || cp "$src" "$DEST/photo_$i.$ext"
done
echo "已生成 $COUNT 个文件：$DEST"
