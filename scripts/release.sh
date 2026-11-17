#!/bin/bash
# 构建发布包：Release 构建 -> ad-hoc 签名 -> 打成 zip -> 输出 SHA-256
# 用法：scripts/release.sh
# 没有 Apple 开发者账号，所以只做 ad-hoc 签名，不做公证。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/app"
BUILD_DIR="$APP_DIR/build/release"
DIST_DIR="$ROOT/dist"

# 版本号从 project.yml 里读
VERSION="$(sed -n 's/^ *MARKETING_VERSION: *"\(.*\)"/\1/p' "$APP_DIR/project.yml" | head -n1)"
if [ -z "$VERSION" ]; then
  echo "没有在 project.yml 里找到 MARKETING_VERSION" >&2
  exit 1
fi
if [ -n "${EXPECTED_RELEASE_TAG:-}" ] && [ "$EXPECTED_RELEASE_TAG" != "v$VERSION" ]; then
  echo "标签 $EXPECTED_RELEASE_TAG 与应用版本 $VERSION 不匹配" >&2
  exit 1
fi
echo "==> 版本 $VERSION"

# 1. 重新生成工程并用 Release 配置构建
echo "==> 构建 Release"
(cd "$APP_DIR" && xcodegen generate)
# 隐私：去掉调试符号，并把源码和构建目录的绝对路径映射成相对路径，
# 免得发布出去的程序里带着构建者电脑上的用户名和目录
xcodebuild -project "$APP_DIR/Yilan.xcodeproj" -scheme Yilan -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -destination 'generic/platform=macOS' ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
  DEPLOYMENT_POSTPROCESSING=YES STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=non-global \
  OTHER_SWIFT_FLAGS="\$(inherited) -file-prefix-map $ROOT=. -debug-prefix-map $ROOT=." \
  clean build

APP="$BUILD_DIR/Build/Products/Release/Yilan.app"

# 隐私检查：程序里不能出现构建者的主目录路径或用户名，有就停止发布
strip -S -x "$APP/Contents/MacOS/Yilan"
ARCHITECTURES="$(lipo -archs "$APP/Contents/MacOS/Yilan")"
for architecture in arm64 x86_64; do
  if [[ " $ARCHITECTURES " != *" $architecture "* ]]; then
    echo "发布包缺少 $architecture（实际架构：$ARCHITECTURES）" >&2
    exit 1
  fi
done
if grep -rlaF -e "$HOME" -e "$(id -un)" "$APP" >/dev/null 2>&1; then
  echo "发布包里还带着本机路径或用户名：" >&2
  grep -rlaF -e "$HOME" -e "$(id -un)" "$APP" >&2
  exit 1
fi

# 2. ad-hoc 签名
echo "==> ad-hoc 签名"
xattr -cr "$APP"   # 清掉扩展属性（来源、隔离标记等）
codesign --force --options runtime -s - "$APP"
codesign --verify --deep --strict "$APP"

# 3. 打包（保留 App 目录本身；不带资源分支，zip 里就没有 __MACOSX）
echo "==> 打包"
mkdir -p "$DIST_DIR"
ZIP="$DIST_DIR/Yilan-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --norsrc --keepParent "$APP" "$ZIP"

# 4. 校验和
echo "==> SHA-256"
(cd "$DIST_DIR" && shasum -a 256 "Yilan-$VERSION.zip" | tee "Yilan-$VERSION.zip.sha256")
ls -lh "$ZIP"
