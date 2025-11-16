# Übersicht Widget 安装指南

## 快速开始

### 1. 安装 Übersicht

**使用 Homebrew（最简单）：**
```bash
brew install --cask ubersicht
```

**或手动下载：**
- 访问：https://github.com/felixhageloh/uebersicht
- 下载最新的 `.dmg` 文件并安装

### 2. 安装 TODO Widget

```bash
cd /Users/firfis/Code/projects/Obsidian_TODO_list管理/desktop_widget
./install_ubersicht.sh
```

### 3. 配置 TODO 文件路径

编辑配置文件：
```bash
open ~/Library/Application\ Support/Übersicht/widgets/todo-widget/index.coffee
```

修改第 6 行：
```coffee
todoFilePath: "/你的/实际/路径/todo.md"
```

### 4. 启用 Widget

1. 打开 Übersicht 应用
2. 点击菜单栏的 Übersicht 图标
3. 找到 `todo-widget` 并启用

## 详细说明

### Übersicht 是什么？

[Übersicht](https://github.com/felixhageloh/uebersicht) 是一个 macOS 桌面小部件工具，允许你在桌面上显示自定义的 HTML/CSS/JavaScript 内容。

### Widget 文件结构

安装后的文件位置：
```
~/Library/Application Support/Übersicht/widgets/todo-widget/
└── index.coffee  # Widget 主文件
```

### 自定义样式

编辑 `index.coffee` 中的 `style` 部分可以修改：

**位置调整：**
```coffee
style: """
  top: 20px      # 距离顶部 20px
  right: 20px    # 距离右边 20px
  left: 20px     # 或距离左边 20px
  bottom: 20px   # 或距离底部 20px
  ...
"""
```

**尺寸调整：**
```coffee
  width: 400px        # 宽度
  max-height: 600px  # 最大高度
```

**颜色和透明度：**
```coffee
  background: rgba(20, 20, 20, 0.85)  # 背景色和透明度
  color: #e0e0e0                       # 文字颜色
```

**字体：**
```coffee
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
  font-size: 13px
```

### 刷新频率

修改 `refreshFrequency` 值（单位：毫秒）：
```coffee
refreshFrequency: 2000  # 每 2 秒刷新一次
```

### 常见问题

**Q: Widget 不显示怎么办？**
A: 
1. 检查 Übersicht 是否在运行
2. 检查 widget 是否已启用
3. 检查文件路径是否正确
4. 查看 Übersicht 日志（菜单栏 > Übersicht > Logs）

**Q: 如何卸载 Widget？**
A: 删除文件夹即可：
```bash
rm -rf ~/Library/Application\ Support/Übersicht/widgets/todo-widget
```

**Q: 可以同时显示多个 TODO 文件吗？**
A: 可以！复制 `todo-widget` 文件夹，重命名为 `todo-widget-2`，然后修改其中的文件路径即可。

**Q: 如何让 Widget 开机自启动？**
A: Übersicht 本身支持开机自启动，在"系统设置 > 通用 > 登录项"中添加 Übersicht 即可。

## 参考资源

- [Übersicht 官方文档](https://github.com/felixhageloh/uebersicht)
- [Übersicht Widget 示例](https://github.com/felixhageloh/uebersicht/wiki/Widgets-Gallery)


