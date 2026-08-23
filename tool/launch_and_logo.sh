#!/bin/bash
set -e

# ==================================================================================
# 脚本名称: ios_image_setup.sh
# 脚本描述: 处理 iOS 的 AppIcon 和 LaunchImage
# 功能:     1. 将 assets/{项目名}/logo.png 转为 JPG 并更新到 iOS 工程
#           2. 将 assets/{项目名}/launch.png 转为 JPG 并更新到 iOS 工程
#           3. 更新 lib/gen_a/A.dart 资源引用
# ==================================================================================

# 获取项目名
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_NAME=$(basename "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]')
ASSETS_DIR="$PROJECT_ROOT/assets/$PROJECT_NAME"
IOS_APPICON_DIR="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
IOS_LAUNCH_DIR="$PROJECT_ROOT/ios/Runner/Assets.xcassets/LaunchImage.imageset"

echo "========================================"
echo "iOS 图片资源处理"
echo "项目名: $PROJECT_NAME"
echo "========================================"

# 检查 assets 目录
if [ ! -d "$ASSETS_DIR" ]; then
    echo "❌ 错误: assets 目录不存在: $ASSETS_DIR"
    exit 1
fi

# ========================================
# 函数: 查找资源文件
# ========================================
find_asset_file() {
    local pattern
    local ext
    local candidate

    for pattern in "$@"; do
        for ext in png jpg jpeg; do
            candidate=$(find "$ASSETS_DIR" -maxdepth 1 -type f -iname "$pattern.$ext" -print | sort | head -n 1)
            if [ -n "$candidate" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
    done

    return 1
}

# ========================================
# 函数: 规范化资源文件名
# ========================================
normalize_asset_name() {
    local target_base="$1"
    shift

    local candidate
    local ext
    local target_ext
    local target_path

    candidate=$(find_asset_file "$target_base" "$@" || true)
    if [ -z "$candidate" ]; then
        echo "  ⚠️  未找到可重命名为 $target_base 的资源"
        return 0
    fi

    ext=$(printf '%s' "${candidate##*.}" | tr '[:upper:]' '[:lower:]')
    if [ "$ext" = "png" ]; then
        target_ext="png"
    else
        target_ext="jpg"
    fi

    target_path="$ASSETS_DIR/$target_base.$target_ext"

    if [ -e "$target_path" ] && ! [ "$candidate" -ef "$target_path" ]; then
        echo "  ⚠️  $target_base.$target_ext 已存在，跳过重命名: $(basename "$candidate")"
        return 0
    fi

    if [ "$candidate" = "$target_path" ]; then
        echo "  ✅ 文件名已规范: $(basename "$target_path")"
        return 0
    fi

    mv "$candidate" "$target_path"
    echo "  ✅ $(basename "$candidate") -> $(basename "$target_path")"
}

# ========================================
# 预处理: 规范化资源文件名
# ========================================
echo ""
echo "🔎 规范化资源文件名..."
normalize_asset_name "logo" "*logo*"
normalize_asset_name "launch" "*splash*" "*launch*"

# ========================================
# 函数: PNG 转 JPG (ffmpeg + sips)
# ========================================
png_to_jpg() {
    local png_path="$1"
    local jpg_path="$2"

    if [ ! -f "$png_path" ]; then
        echo "  ⚠️  文件不存在: $png_path"
        return 1
    fi

    local tmp_path="$jpg_path.tmp.jpg"

    # ffmpeg 转 JPG
    ffmpeg -i "$png_path" -q:v 3 "$tmp_path" -y -loglevel error

    # sips 确保符合 JFIF 标准
    sips -s format jpeg "$tmp_path" --out "$jpg_path" -s formatOptions 95 2>/dev/null | grep -v "^/"

    # 清理临时文件
    rm -f "$tmp_path" "$png_path"

    echo "  ✅ 转换完成: $(basename "$jpg_path")"
}

# ========================================
# 1. 处理 AppIcon
# ========================================
echo ""
echo "📱 处理 AppIcon..."

LOGO_PNG="$ASSETS_DIR/logo.png"
LOGO_JPG="$ASSETS_DIR/logo.jpg"

if [ -f "$LOGO_PNG" ]; then
    # PNG 转 JPG (保持 1024x1024)
    png_to_jpg "$LOGO_PNG" "$LOGO_JPG"

    # 复制到 iOS 工程 (保持 1024x1024)
    cp "$LOGO_JPG" "$IOS_APPICON_DIR/logo.jpg"
    echo "  ✅ 复制到 iOS 工程 (1024x1024)"

    # 删除旧图标
    rm -f "$IOS_APPICON_DIR"/*.png 2>/dev/null || true

    # 更新 Contents.json
    cat > "$IOS_APPICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "logo.jpg",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    echo "  ✅ 更新 Contents.json"

    # 最后调整 assets 里的 logo 为 512x512
    sips -z 512 512 "$LOGO_JPG" 2>/dev/null | grep -v "^/"
    echo "  ✅ 调整 assets logo 为 512x512"

elif [ -f "$LOGO_JPG" ]; then
    echo "  ⚠️  logo.jpg 已存在，跳过转换"

    # 确保分辨率正确
    sips -z 1024 1024 "$LOGO_JPG" --out "$IOS_APPICON_DIR/logo.jpg" 2>/dev/null | grep -v "^/"
    sips -z 512 512 "$LOGO_JPG" 2>/dev/null | grep -v "^/"
    echo "  ✅ 已更新分辨率"
else
    echo "  ❌ 未找到 logo.png 或 logo.jpg"
fi

# ========================================
# 2. 处理 LaunchImage
# ========================================
echo ""
echo "🚀 处理 LaunchImage..."

LAUNCH_PNG="$ASSETS_DIR/launch.png"
LAUNCH_JPG="$ASSETS_DIR/launch.jpg"

if [ -f "$LAUNCH_PNG" ]; then
    # PNG 转 JPG
    png_to_jpg "$LAUNCH_PNG" "$LAUNCH_JPG"

    # 复制到 iOS 工程
    cp "$LAUNCH_JPG" "$IOS_LAUNCH_DIR/launch.jpg"
    echo "  ✅ 复制到 iOS 工程"

    # 删除旧图片
    rm -f "$IOS_LAUNCH_DIR"/*.png 2>/dev/null || true
    rm -f "$IOS_LAUNCH_DIR"/lauch.jpg 2>/dev/null || true

    # 更新 Contents.json (universal 格式)
    cat > "$IOS_LAUNCH_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "launch.jpg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    echo "  ✅ 更新 Contents.json"

elif [ -f "$LAUNCH_JPG" ]; then
    echo "  ⚠️  launch.jpg 已存在，跳过转换"
    cp "$LAUNCH_JPG" "$IOS_LAUNCH_DIR/launch.jpg"
    echo "  ✅ 已复制到 iOS 工程"
else
    echo "  ❌ 未找到 launch.png 或 launch.jpg"
fi

# ========================================
# 3. 更新 A.dart
# ========================================
dart run ./tools/workflow/update_gen_a.dart