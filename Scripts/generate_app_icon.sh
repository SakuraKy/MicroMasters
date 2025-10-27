#!/bin/bash

cd /Users/shenkeyu/Documents/MicroMasters/MicroMasters/Assets.xcassets/AppIcon.appiconset

SOURCE="/Users/shenkeyu/Documents/MicroMasters/MicroMasters/Resources/Assets.xcassets/MenuIcon.imageset/magic@2x.png"

echo "🎨 开始生成应用图标..."

# 生成各种尺寸
sips -z 16 16 "$SOURCE" --out icon_16x16.png >/dev/null 2>&1
sips -z 32 32 "$SOURCE" --out icon_16x16@2x.png >/dev/null 2>&1
sips -z 32 32 "$SOURCE" --out icon_32x32.png >/dev/null 2>&1
sips -z 64 64 "$SOURCE" --out icon_32x32@2x.png >/dev/null 2>&1
sips -z 128 128 "$SOURCE" --out icon_128x128.png >/dev/null 2>&1
sips -z 256 256 "$SOURCE" --out icon_128x128@2x.png >/dev/null 2>&1
sips -z 256 256 "$SOURCE" --out icon_256x256.png >/dev/null 2>&1
sips -z 512 512 "$SOURCE" --out icon_256x256@2x.png >/dev/null 2>&1
sips -z 512 512 "$SOURCE" --out icon_512x512.png >/dev/null 2>&1
sips -z 1024 1024 "$SOURCE" --out icon_512x512@2x.png >/dev/null 2>&1

echo "✅ 所有尺寸的图标已生成"
ls -lh icon_*.png | awk '{print $9, $5}'
