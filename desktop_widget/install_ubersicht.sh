#!/bin/bash
# Übersicht Widget 安装脚本

WIDGET_NAME="todo-widget"
UBERSICHT_DIR="$HOME/Library/Application Support/Übersicht/widgets"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "正在安装 Übersicht Widget..."

# 检查 Übersicht 是否安装
if [ ! -d "$UBERSICHT_DIR" ]; then
    echo "错误: 未找到 Übersicht 目录"
    echo "请先安装 Übersicht: https://github.com/felixhageloh/uebersicht"
    exit 1
fi

# 创建 widget 目录
WIDGET_TARGET="$UBERSICHT_DIR/$WIDGET_NAME"
mkdir -p "$WIDGET_TARGET"

# 复制 widget 文件（必须命名为 index.coffee）
echo "复制 widget 文件..."
cp "$CURRENT_DIR/todo-widget.coffee" "$WIDGET_TARGET/index.coffee"

# 如果之前错误地复制成了 todo-widget.coffee，删除它
if [ -f "$WIDGET_TARGET/todo-widget.coffee" ]; then
    echo "删除错误命名的文件..."
    rm "$WIDGET_TARGET/todo-widget.coffee"
fi

echo "✓ Widget 已安装到: $WIDGET_TARGET"
echo ""
echo "下一步："
echo "1. 编辑 $WIDGET_TARGET/index.coffee"
echo "2. 修改 todoFilePath 为你的 TODO 文件路径"
echo "3. 在 Übersicht 中启用该 widget"
echo "4. 可以在 Übersicht 设置中调整 widget 的位置和样式"

