# TODO 列表桌面显示工具

两种方式在 Mac 桌面显示 TODO 列表：

## 方案一：Übersicht Widget（推荐）✨

**优点：**
- 美观，支持 HTML/CSS
- 性能好，低占用
- 可自定义样式
- 支持 React/JSX（高级用法）

**安装步骤：**

### 第一步：安装 Übersicht 应用

Übersicht 是一个 macOS 桌面小部件工具，可以通过以下方式安装：

**方法 A：使用 Homebrew（推荐）**
```bash
brew install --cask ubersicht
```

**方法 B：手动下载安装**
1. 访问 [Übersicht GitHub 页面](https://github.com/felixhageloh/uebersicht)
2. 下载最新的 `.dmg` 文件
3. 打开 `.dmg` 文件，将 Übersicht 拖拽到应用程序文件夹
4. 首次运行时，需要在"系统设置 > 隐私与安全性"中允许 Übersicht 的辅助功能权限

### 第二步：安装 TODO Widget

安装好 Übersicht 后，运行安装脚本：

```bash
cd desktop_widget
chmod +x install_ubersicht.sh
./install_ubersicht.sh
```

或者手动安装：
```bash
# 创建 widget 目录
mkdir -p ~/Library/Application\ Support/Übersicht/widgets/todo-widget

# 复制 widget 文件
cp desktop_widget/todo-widget.coffee ~/Library/Application\ Support/Übersicht/widgets/todo-widget/index.coffee
```

### 第三步：配置 Widget

编辑 widget 配置文件：
```bash
open ~/Library/Application\ Support/Übersicht/widgets/todo-widget/index.coffee
```

或者使用你喜欢的编辑器打开该文件，修改第 6 行的 TODO 文件路径：
```coffee
todoFilePath: "/Users/firfis/你的/实际/路径/todo.md"
```

### 第四步：启用 Widget

1. **打开 Übersicht 应用**
   - 在应用程序中找到并打开 Übersicht
   - 首次打开后，Übersicht 图标会出现在菜单栏（右上角）

2. **启用 Widget**
   - 点击菜单栏的 Übersicht 图标
   - 在列表中找到 `todo-widget`
   - 点击启用（如果已启用，会显示 ✓）

3. **调整位置和样式**
   - 在 Übersicht 菜单中，选择 "Open Widgets Folder" 可以快速打开 widgets 目录
   - 编辑 `index.coffee` 文件中的 `style` 部分可以自定义：
     - 位置：修改 `top`, `right`, `left`, `bottom` 值
     - 大小：修改 `width`, `max-height` 值
     - 颜色和透明度：修改 `background` 值
     - 字体：修改 `font-family`, `font-size` 值

### 第五步：设置权限（如需要）

如果 widget 无法正常工作，可能需要：
1. 打开"系统设置 > 隐私与安全性 > 辅助功能"
2. 确保 Übersicht 已勾选
3. 如果已勾选但仍不工作，取消勾选后重新勾选

### 故障排除

**Widget 不显示：**
- 检查 Übersicht 是否在运行（查看菜单栏图标）
- 检查 widget 是否已启用
- 检查 TODO 文件路径是否正确
- 查看 Übersicht 日志：菜单栏 > Übersicht > Logs

**文件路径问题：**
- 确保使用绝对路径（以 `/` 开头）
- 路径中包含空格时不需要转义（CoffeeScript 会自动处理）
- 如果路径包含中文字符，确保文件系统编码正确

**样式不生效：**
- 修改 `index.coffee` 后，在 Übersicht 菜单中点击 "Refresh Widgets" 刷新
- 或者禁用后重新启用 widget

## 方案二：Python Tkinter 桌面窗口

**优点：**
- 无需安装额外软件（Python 内置）
- 完全可控
- 支持文件监控

**安装步骤：**

1. **运行应用**
   ```bash
   # 基本使用
   python3 desktop_widget/todo_desktop.py /path/to/your/todo.md
   
   # 启用文件监控（文件变化时自动刷新）
   python3 desktop_widget/todo_desktop.py /path/to/your/todo.md --watch
   
   # 自定义刷新间隔（秒）
   python3 desktop_widget/todo_desktop.py /path/to/your/todo.md --refresh 5
   ```

2. **开机自启动（可选）**
   
   **使用 Automator 创建启动项：**
   
   - 打开 Automator
   - 创建"应用程序"
   - 添加"运行 Shell 脚本"
   - 输入：
     ```bash
     cd /Users/firfis/Code/projects/Obsidian_TODO_list管理
     python3 desktop_widget/todo_desktop.py /path/to/your/todo.md --watch &
     ```
   - 保存为应用程序
   - 在"系统设置 > 通用 > 登录项"中添加该应用程序

## 方案对比

| 特性 | Übersicht | Tkinter |
|------|-----------|---------|
| 美观度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 性能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 安装难度 | 中等 | 简单 |
| 自定义性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 额外依赖 | 需要安装 | 无需 |

## 样式自定义

### Übersicht Widget

编辑 `index.coffee` 中的 `style` 部分，可以修改：
- 位置（`top`, `right`, `left`, `bottom`）
- 尺寸（`width`, `height`）
- 背景色和透明度
- 字体和颜色
- 圆角、阴影等效果

### Python Tkinter

编辑 `todo_desktop.py` 中的样式设置：
- 窗口大小和位置（`geometry`）
- 透明度（`alpha`）
- 颜色（`bg`, `fg`）
- 字体（`font`）

## 故障排除

### Übersicht Widget 不显示

1. 检查 Übersicht 是否在运行
2. 检查 widget 是否在 Übersicht 中启用
3. 检查文件路径是否正确
4. 查看 Übersicht 日志（菜单栏 > Übersicht > Logs）

### Python 窗口无法置顶

某些 macOS 版本可能需要额外的权限。尝试：
- 在"系统设置 > 隐私与安全性 > 辅助功能"中添加 Terminal/iTerm2
- 使用 `--topmost` 选项（如果支持）

### 文件路径包含中文

确保文件路径使用正确的编码。如果遇到问题，尝试：
- 使用英文路径
- 确保终端编码为 UTF-8

