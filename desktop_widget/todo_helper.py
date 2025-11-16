#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TODO 文件操作辅助脚本
用于 Übersicht widget 的交互功能
"""

import re
import sys
import argparse
from datetime import datetime
from pathlib import Path

TODAY_REGEX = re.compile(r'\s+-today\b', re.IGNORECASE)
EVERYDAY_REGEX = re.compile(r'\s+-everyday\b', re.IGNORECASE)
DONE_REGEX = re.compile(r'\s+-done:(\d{4}-\d{2}-\d{2}T\d{2}:\d{2})', re.IGNORECASE)


def remove_today_tag(text: str) -> tuple[str, bool]:
    """移除 -today 标签"""
    new_text, count = TODAY_REGEX.subn('', text)
    return new_text.strip(), count > 0


def append_done_tag(text: str) -> str:
    """在内容末尾追加完成时间"""
    cleaned = DONE_REGEX.sub('', text).strip()
    date_str = datetime.now().strftime('%Y-%m-%dT%H:%M')
    if cleaned:
        return f"{cleaned} -done:{date_str}"
    return f"-done:{date_str}"


def restore_today_from_done(text: str) -> tuple[str, bool]:
    """将 -done:YYYY-MM-DDThh:mm 恢复为 -today"""
    cleaned, count = DONE_REGEX.subn('', text)
    if count == 0:
        return text, False
    cleaned = cleaned.strip()
    if TODAY_REGEX.search(cleaned):
        return cleaned, False
    if cleaned:
        return f"{cleaned} -today", True
    return "-today", True


def remove_done_tag(text: str) -> tuple[str, bool]:
    """移除 -done:YYYY-MM-DD 标记"""
    cleaned, count = DONE_REGEX.subn('', text)
    return cleaned.strip(), count > 0


def refresh_everyday_tasks(file_path: Path):
    """将每日任务在新一天开始时重置为未完成"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False
    
    today_str = datetime.now().strftime('%Y-%m-%d')
    pattern = r'^(\s*)(-\s+)(\[([ x])\])(\s+)(.+)$'
    changed = False
    
    for idx, original_line in enumerate(lines):
        line = original_line.rstrip('\n')
        match = re.match(pattern, line)
        if not match:
            continue
        
        status = match.group(4).strip()
        content = match.group(6)
        if not EVERYDAY_REGEX.search(content):
            continue
        
        done_match = DONE_REGEX.search(content)
        done_date = done_match.group(1) if done_match else None
        
        if status == 'x' and done_date != today_str:
            indent = match.group(1)
            dash = match.group(2)
            space = match.group(5)
            new_content, _ = remove_done_tag(content)
            if not EVERYDAY_REGEX.search(new_content):
                new_content = f"{new_content} -everyday".strip()
            lines[idx] = f"{indent}{dash}[ ]{space}{new_content}\n"
            changed = True
    
    if not changed:
        return True
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        return True
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False


def toggle_todo(file_path: Path, line_index: int):
    """切换指定行的 TODO 状态"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False
    
    if line_index < 0 or line_index >= len(lines):
        print(f"错误: 行索引超出范围", file=sys.stderr)
        return False
    
    line = lines[line_index].rstrip('\n')
    
    # 匹配 TODO 行
    pattern = r'^(\s*)(-\s+)(\[([ x])\])(\s+)(.+)$'
    match = re.match(pattern, line)
    
    if not match:
        print(f"错误: 不是有效的 TODO 行", file=sys.stderr)
        return False
    
    indent = match.group(1)
    dash = match.group(2)
    checkbox = match.group(3)
    status = match.group(4)
    space = match.group(5)
    content = match.group(6)
    
    # 切换状态：' ' -> 'x', 'x' -> ' '
    # status 可能是 ' ' 或 'x'
    current_status = status.strip()
    new_status = 'x' if current_status == ' ' or current_status == '' else ' '
    new_content = content
    has_everyday = bool(EVERYDAY_REGEX.search(content))
    if new_status == 'x':
        new_content, had_today = remove_today_tag(new_content)
        if has_everyday and not EVERYDAY_REGEX.search(new_content):
            new_content = f"{new_content} -everyday".strip()
        new_content = append_done_tag(new_content)
    else:
        new_content, _ = remove_done_tag(new_content)
        restored, restored_flag = restore_today_from_done(new_content)
        if restored_flag:
            new_content = restored
    new_line = f"{indent}{dash}[{new_status}]{space}{new_content}\n"
    lines[line_index] = new_line
    
    # 调试输出
    print(f"切换: 行 {line_index}, 从 '{current_status}' 到 '{new_status}'", file=sys.stderr)
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print("成功")
        return True
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False


def add_todo(file_path: Path, content: str):
    """添加新的 TODO 项"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False
    
    # 找到第一个 TODO 行的缩进
    indent = ""
    for line in lines:
        match = re.match(r'^(\s*)(-\s+\[[ x]\])', line)
        if match:
            indent = match.group(1)
            break
    
    # 添加新行
    new_line = f"{indent}- [ ] {content}\n"
    
    # 找到第一个 TODO 行的位置，插入到它之前
    insert_pos = 0
    for i, line in enumerate(lines):
        if re.match(r'^\s*-\s+\[[ x]\]', line):
            insert_pos = i
            break
    
    lines.insert(insert_pos, new_line)
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print("成功")
        return True
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return False


def get_todo_line_index(file_path: Path, content_hash: str):
    """根据内容哈希找到对应的行索引"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print("-1", file=sys.stderr)
        return
    
    todo_index = 0
    for i, line in enumerate(lines):
        if re.match(r'^\s*-\s+\[[ x]\]', line):
            # 计算简单哈希（行号 + 内容前20个字符）
            content = re.sub(r'^\s*-\s+\[[ x]\]\s*', '', line)
            if str(i) == content_hash or content[:20] in content_hash:
                print(i)
                return
            todo_index += 1
    
    print("-1")


def main():
    parser = argparse.ArgumentParser(description='TODO 文件操作辅助脚本')
    parser.add_argument('action', choices=['toggle', 'add', 'find', 'refresh'], help='操作类型')
    parser.add_argument('file_path', type=Path, help='TODO 文件路径')
    parser.add_argument('--line', type=int, help='行索引（toggle 操作）')
    parser.add_argument('--content', type=str, help='任务内容（add 操作）')
    parser.add_argument('--hash', type=str, help='内容哈希（find 操作）')
    
    args = parser.parse_args()
    
    if args.action == 'toggle':
        if args.line is None:
            print("错误: toggle 操作需要 --line 参数", file=sys.stderr)
            sys.exit(1)
        success = toggle_todo(args.file_path, args.line)
        sys.exit(0 if success else 1)
    
    elif args.action == 'add':
        if not args.content:
            print("错误: add 操作需要 --content 参数", file=sys.stderr)
            sys.exit(1)
        success = add_todo(args.file_path, args.content)
        sys.exit(0 if success else 1)
    
    elif args.action == 'find':
        if not args.hash:
            print("错误: find 操作需要 --hash 参数", file=sys.stderr)
            sys.exit(1)
        get_todo_line_index(args.file_path, args.hash)
    
    elif args.action == 'refresh':
        success = refresh_everyday_tasks(args.file_path)
        sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
