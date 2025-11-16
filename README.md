# Obsidian TODO 列表整理工具

自动整理 Obsidian TODO 列表，将已完成的任务（`- [x]`）移到底部，未完成的任务（`- [ ]`）保留在上面。

## 安装

```bash
pip install -r requirements.txt
```

## 使用方法

### 1. 手动整理（推荐用于一次性整理）

```bash
# 整理单个文件
python todo_organizer.py /path/to/your/todo.md

# 整理多个文件
python todo_organizer.py file1.md file2.md file3.md
```

### 2. 自动监控模式（推荐用于频繁编辑）

```bash
# 监控文件变化，自动整理
python todo_organizer.py /path/to/your/todo.md --watch
```

监控模式下，每次保存文件时会自动整理。按 `Ctrl+C` 退出。

### 3. 绑定快捷键（最无感的方式）

**macOS (使用 Alfred/Keyboard Maestro/AppleScript):**
- 在 Alfred 中创建一个 Workflow，运行命令：`python3 /path/to/todo_organizer.py "/path/to/todo.md"`
- 或使用 AppleScript 创建服务，绑定快捷键

**或使用 Obsidian 插件:**
- 安装 [Templater](https://github.com/SilentVoid13/Templater) 插件
- 创建模板命令来执行脚本

## 功能特点

- ✅ 保留所有非 TODO 行的原始位置和格式
- ✅ 保持 TODO 项的原始缩进格式
- ✅ 自动分离已完成和未完成的任务
- ✅ 支持文件监控，自动整理
- ✅ 不会修改文件的其他内容（标题、正文等）

## 示例

**整理前：**
```markdown
- [x] 已完成的任务1
- [ ] 未完成的任务1
- [x] 已完成的任务2
- [ ] 未完成的任务2
```

**整理后：**
```markdown
- [ ] 未完成的任务1
- [ ] 未完成的任务2
- [x] 已完成的任务1
- [x] 已完成的任务2
```


