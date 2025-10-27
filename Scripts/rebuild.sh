#!/bin/bash

# 快速重建脚本 - 清理并重新构建 MicroMasters

set -e

PROJECT_PATH="/Users/shenkeyu/Documents/MicroMasters/MicroMasters.xcodeproj"
SCHEME="MicroMasters"

echo "🧹 清理构建缓存..."
xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Debug

echo ""
echo "🔨 重新构建项目..."
xcodebuild build -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration Debug

echo ""
echo "✅ 构建完成！"
echo ""
echo "现在可以在 Xcode 中运行应用，或使用以下命令："
echo "   open /Users/shenkeyu/Documents/MicroMasters/build/Debug/MicroMasters.app"
