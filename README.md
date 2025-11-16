<div align="center">

# macOS TODO Widget for Obsidian
<img width="479" height="707" alt="image" src="https://github.com/user-attachments/assets/123ea476-885f-4a68-bed4-357cc15ee0c4" />

把 Obsidian 的 `todo.md` 以玻璃拟态小组件的形式钉在桌面上，支持优先级、今日清单、每日循环、键盘添加等特性。

</div>

> 本 repo 仍然保留早期的 `todo_organizer.py`，但推荐使用 `desktop_widget` 目录下的 Übersicht Widget。下面的文档仅覆盖小组件方案。

## 功能总览

- **每日看板**：自动把 `-today` 或 `-everyday` 的任务放入“今日任务”区块，显示待完成/已完成统计和完成度。
- **优先级徽章**：支持 `-imp`（重要）、`-emer`（紧急）；两个标签同时存在时会合并为醒目的 `critical`。徽章和复选框颜色与四象限优先级对应。
- **即时添加面板**：在 Widget 顶部点击 “+ 添加” 即可展开输入框，可通过复选框勾选 `今日/每日/重要/紧急` 标签，自动拼接到 Markdown 中。
- **文件双向同步**：Widget 每 3 秒读取一次指定的 `.md` 文件，勾选任务会调用 `desktop_widget/todo_helper.py` 直接修改文件。所有任务完成后都会追加 `-done:YYYY-MM-DDThh:mm` 的时间戳。
- **样式可调**：使用纯 CoffeeScript + CSS，方便调整位置、字体、透明度；也可以继续扩展 React/JSX 版本。

## 安装前置

1. **安装 Übersicht**（macOS 桌面 Widget 平台）
   ```bash
   brew install --cask ubersicht
   ```
   首次启动后在“系统设置 > 隐私与安全性 > 辅助功能”勾选 Übersicht。

2. **准备你的 TODO 文件**：确保有一个 Markdown 文件，例如 `~/Documents/Obsidian/记录内容/00-Inbox/TODO list.md`。

3. **可选依赖**：如需使用 Python 版桌面窗口，可 `pip install -r requirements.txt`（仅含 `watchdog`）。

## 安装 Widget

```bash
git clone https://github.com/your-name/Obsidian_TODO_list管理.git
cd Obsidian_TODO_list管理/desktop_widget
chmod +x install_ubersicht.sh
./install_ubersicht.sh
```

脚本会把 `todo-widget.coffee` 复制到：
```
~/Library/Application Support/Übersicht/widgets/todo-widget/index.coffee
```

### 手动安装

```bash
mkdir -p ~/Library/Application\ Support/Übersicht/widgets/todo-widget
cp desktop_widget/todo-widget.coffee \
  ~/Library/Application\ Support/Übersicht/widgets/todo-widget/index.coffee
```

随后编辑 `index.coffee` 的前几行，指定你的 Markdown 路径和 `todo_helper.py` 的绝对路径：

```coffee
todoFilePath: "/absolute/path/to/todo.md"
helperScript: "/absolute/path/to/desktop_widget/todo_helper.py"
```

## 在 Übersicht 中启用

1. 打开 Übersicht（Launchpad 或 Spotlight）。
2. Menubar > Übersicht > **Enable** `todo-widget`。
3. 需要调整位置/大小时，在 `index.coffee` 的 `style` 段落中修改 `top/right/width` 等属性，保存后在 Übersicht 菜单中选择 “Refresh Widgets”。

## Markdown 语法约定

| 标签 | 作用 | 备注 |
|------|------|------|
| `-today` | 今日任务，进入“今日任务”区块 | 在今日区块不会再额外显示 “今日” 徽章 |
| `-everyday` | 每日循环，次日自动重置为未完成 | 与 `-today` 同时使用可确保当天显示 |
| `-imp` | 重要事项，橙色徽章/边框 | |
| `-emer` | 紧急事项，蓝色徽章/边框 | 与 `-imp` 同时出现时合并为红色 `critical` |
| `-done:YYYY-MM-DDThh:mm` | 完成时间戳 | 勾选任务时自动写入，所有任务均适用 |
| 其它任意文本/链接 | 原样显示 | 支持 Markdown 链接/中文 |

示例：

```markdown
- [ ] 写 README -today -imp
- [ ] 每日阅读 10 分钟 -everyday -today
- [ ] 服务器例行巡检 -emer
- [x] 发布 v1.0 -imp -emer -done:2025-02-18T09:42
```

## 快速使用

1. **添加任务**：点击 Widget 右上角 “+ 添加”，在输入框中输入任务内容，勾选需要的标签，按 Enter 或点击 “添加” 即可写入 Markdown。
2. **切换状态**：点击每条任务左侧的方框，即刻在 UI 中切换状态，并调用 `todo_helper.py` 修改原文件。
3. **查看统计**：顶端 Summary 卡片实时显示待办/已完成数量以及完成率；今日区块使用四象限排序（Critical → Important → Urgent → 其他）。
4. **每日重置**：`todo_helper.py` 会在每次刷新时运行 `refresh`，自动把前一天勾选的 `-everyday` 任务恢复为未完成。

## 常见问题

### Widget 无法显示
- 确认 `todoFilePath` 指向的文件存在且可读。
- 重新在 Übersicht 菜单里 `Refresh Widgets`。
- 在菜单 `Übersicht > Logs` 查看错误（如 `unexpected if` 多半是编辑器破坏了 CoffeeScript 缩进）。

### 勾选/添加无响应
- `todo_helper.py` 必须有执行权限，并能被 `python3` 正确运行；可以在终端里手动执行：
  ```bash
  python3 desktop_widget/todo_helper.py toggle /path/to/todo.md --line 0
  ```
- 若任务带有中文路径，确保终端编码为 UTF-8。

### 如何自定义样式
- Widget 所有视觉都写在 `style: """ ... """` 中，修改后保存即生效。
- 可以为 `.todo-item`、`.summary-card` 等类新增 CSS，打造自己的主题。

## Python Tkinter 版本（可选）

虽然主力是 Übersicht Widget，但 `desktop_widget/todo_desktop.py` 依旧可用：

```bash
python3 desktop_widget/todo_desktop.py /path/to/todo.md --watch
```

它会打开一个置顶透明窗口显示同一个 Markdown 文件，适合不想安装 Übersicht 的场景。

---

如需继续拓展（例如添加任务筛选、与 Obsidian 插件联动），欢迎提交 Issue 或 PR。祝使用愉快！

