#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Obsidian TODO 列表整理工具
自动将已完成的 TODO 移到底部，未完成的保留在上面
"""

import re
import sys
import argparse
from pathlib import Path
from typing import List, Tuple
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


def parse_todo_line(line: str) -> Tuple[bool, str, str]:
    """
    解析 TODO 行
    返回: (是否是TODO, 是否完成, 完整行内容)
    """
    # 匹配 - [x] 或 - [ ] 格式
    todo_pattern = r'^(\s*)(-\s+\[([ x])\]\s+)(.+)$'
    match = re.match(todo_pattern, line)
    
    if match:
        indent = match.group(1)
        checkbox = match.group(2)
        status = match.group(3)
        content = match.group(4)
        is_completed = status.strip() == 'x'
        full_line = indent + checkbox + content
        return True, is_completed, full_line
    
    return False, False, line


def organize_todos(file_path: Path) -> bool:
    """
    整理 TODO 列表
    返回: 是否进行了修改
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"错误: 无法读取文件 {file_path}: {e}")
        return False
    
    # 分离 TODO 和非 TODO 行
    todo_lines = []  # (原始索引, 是否完成, 行内容)
    all_todo_indices = set()
    
    for idx, line in enumerate(lines):
        is_todo, is_completed, parsed_line = parse_todo_line(line.rstrip('\n'))
        if is_todo:
            todo_lines.append((idx, is_completed, parsed_line))
            all_todo_indices.add(idx)
    
    if not todo_lines:
        print(f"文件 {file_path} 中没有找到 TODO 项")
        return False
    
    # 分离已完成和未完成的 TODO，保留原始格式
    incomplete_todos = []
    complete_todos = []
    
    for idx, is_completed, parsed_line in todo_lines:
        # 保留原始行的完整格式（包括换行符处理）
        original_line = lines[idx].rstrip('\n')
        if is_completed:
            complete_todos.append(original_line)
        else:
            incomplete_todos.append(original_line)
    
    # 重新组织：保留所有非TODO行的原始位置，在TODO区域重新插入
    new_lines = []
    seen_todo_section = False
    
    for idx, line in enumerate(lines):
        if idx not in all_todo_indices:
            # 非TODO行，原样保留
            new_lines.append(line)
        elif not seen_todo_section:
            # 第一次遇到TODO区域
            seen_todo_section = True
            
            # 获取第一个TODO的缩进格式
            first_todo_line = lines[idx]
            first_indent = re.match(r'^(\s*)', first_todo_line).group(1) if first_todo_line.strip() else ''
            
            # 先插入未完成的TODO
            for todo in incomplete_todos:
                # 确保保持原始缩进
                todo_indent = re.match(r'^(\s*)', todo).group(1) if todo.strip() else ''
                if not todo_indent and first_indent:
                    # 如果原TODO没有缩进但第一个有，保持第一个的缩进
                    todo = first_indent + todo.lstrip()
                new_lines.append(todo + '\n')
            
            # 再插入已完成的TODO（在未完成的下方）
            if complete_todos:
                for todo in complete_todos:
                    todo_indent = re.match(r'^(\s*)', todo).group(1) if todo.strip() else ''
                    if not todo_indent and first_indent:
                        todo = first_indent + todo.lstrip()
                    new_lines.append(todo + '\n')
    
    # 检查是否有变化
    original_content = ''.join(lines)
    new_content = ''.join(new_lines)
    
    if original_content == new_content:
        print(f"文件 {file_path} 已经整理完毕，无需修改")
        return False
    
    # 写回文件
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"✓ 已整理 {file_path}")
        print(f"  - 未完成任务: {len(incomplete_todos)} 个")
        print(f"  - 已完成任务: {len(complete_todos)} 个")
        return True
    except Exception as e:
        print(f"错误: 无法写入文件 {file_path}: {e}")
        return False


class TodoFileHandler(FileSystemEventHandler):
    """文件监控处理器"""
    
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.last_modified = file_path.stat().st_mtime if file_path.exists() else 0
    
    def on_modified(self, event):
        if event.src_path == str(self.file_path.absolute()):
            # 防止重复触发
            import time
            current_time = time.time()
            if current_time - self.last_modified < 1:
                return
            self.last_modified = current_time
            
            print(f"\n检测到文件变化: {self.file_path.name}")
            organize_todos(self.file_path)


def main():
    parser = argparse.ArgumentParser(
        description='整理 Obsidian TODO 列表（已完成任务移到底部）',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 整理单个文件
  python todo_organizer.py /path/to/file.md
  
  # 监控文件变化（自动整理）
  python todo_organizer.py /path/to/file.md --watch
  
  # 整理多个文件
  python todo_organizer.py file1.md file2.md
        """
    )
    
    parser.add_argument(
        'files',
        nargs='+',
        type=Path,
        help='要整理的 Markdown 文件路径'
    )
    
    parser.add_argument(
        '--watch', '-w',
        action='store_true',
        help='监控文件变化，自动整理'
    )
    
    args = parser.parse_args()
    
    # 检查文件是否存在
    valid_files = []
    for file_path in args.files:
        if not file_path.exists():
            print(f"警告: 文件不存在 {file_path}")
        else:
            valid_files.append(file_path)
    
    if not valid_files:
        print("错误: 没有有效的文件可处理")
        sys.exit(1)
    
    # 处理文件
    for file_path in valid_files:
        organize_todos(file_path)
    
    # 如果需要监控
    if args.watch:
        if len(valid_files) > 1:
            print("警告: 监控模式只支持单个文件，将监控第一个文件")
        
        file_path = valid_files[0]
        print(f"\n监控模式: 正在监控 {file_path.name}")
        print("按 Ctrl+C 退出")
        
        event_handler = TodoFileHandler(file_path)
        observer = Observer()
        observer.schedule(event_handler, path=str(file_path.parent), recursive=False)
        observer.start()
        
        try:
            import time
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
            print("\n停止监控")
        
        observer.join()


if __name__ == '__main__':
    main()

 