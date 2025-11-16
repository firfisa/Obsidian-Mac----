#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TODO 列表桌面显示工具（使用 Tkinter）
在 Mac 桌面显示透明的 TODO 列表窗口
"""

import re
import tkinter as tk
from tkinter import scrolledtext
from pathlib import Path
import argparse
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


class TodoDesktopApp:
    """TODO 桌面应用"""
    
    def __init__(self, todo_file: Path, refresh_interval: int = 2):
        self.todo_file = todo_file
        self.refresh_interval = refresh_interval * 1000  # 转换为毫秒
        
        # 创建主窗口
        self.root = tk.Tk()
        self.setup_window()
        self.setup_widgets()
        
        # 初始化内容
        self.refresh_content()
        
        # 设置定时刷新
        self.root.after(self.refresh_interval, self.schedule_refresh)
    
    def setup_window(self):
        """设置窗口属性"""
        self.root.title("TODO List")
        self.root.geometry("400x600+100+100")  # 宽度x高度+x坐标+y坐标
        
        # 设置窗口透明和置顶
        self.root.attributes('-alpha', 0.9)  # 透明度
        self.root.attributes('-topmost', True)  # 置顶
        self.root.overrideredirect(False)  # 保留窗口边框，方便拖动
        
        # 设置背景色
        self.root.configure(bg='#141414')
        
        # 设置窗口无焦点时也可见（macOS）
        try:
            self.root.attributes('-transparent', False)
        except:
            pass
    
    def setup_widgets(self):
        """设置界面组件"""
        # 标题栏
        header_frame = tk.Frame(self.root, bg='#141414', height=40)
        header_frame.pack(fill=tk.X, padx=0, pady=0)
        header_frame.pack_propagate(False)
        
        title_label = tk.Label(
            header_frame,
            text="📋 TODO List",
            font=('SF Pro Display', 16, 'bold'),
            bg='#141414',
            fg='#ffffff',
            anchor='w'
        )
        title_label.pack(side=tk.LEFT, padx=15, pady=10)
        
        # 关闭按钮
        close_btn = tk.Button(
            header_frame,
            text="×",
            font=('SF Pro Display', 20),
            bg='#141414',
            fg='#888888',
            activebackground='#ff4444',
            activeforeground='#ffffff',
            border=0,
            command=self.root.quit,
            width=3,
            cursor='hand2'
        )
        close_btn.pack(side=tk.RIGHT, padx=5)
        
        # 主内容区域（使用 Canvas + Frame 实现自定义滚动条）
        canvas_frame = tk.Frame(self.root, bg='#141414')
        canvas_frame.pack(fill=tk.BOTH, expand=True, padx=0, pady=0)
        
        # 创建 Canvas 和滚动条
        canvas = tk.Canvas(
            canvas_frame,
            bg='#141414',
            highlightthickness=0,
            bd=0
        )
        
        scrollbar = tk.Scrollbar(
            canvas_frame,
            orient="vertical",
            command=canvas.yview,
            bg='#333333',
            troughcolor='#141414',
            activebackground='#555555',
            width=6
        )
        
        self.content_frame = tk.Frame(canvas, bg='#141414')
        
        # 配置滚动区域
        self.content_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=self.content_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # 鼠标滚轮支持
        def on_mousewheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        
        canvas.bind_all("<MouseWheel>", on_mousewheel)
        
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    
    def parse_todo_line(self, line: str) -> tuple:
        """解析 TODO 行"""
        pattern = r'^\s*-\s+\[([ x])\]\s+(.+)$'
        match = re.match(pattern, line)
        if match:
            status = match.group(1)
            content = match.group(2)
            return True, status.strip() == 'x', content
        return False, False, line
    
    def refresh_content(self):
        """刷新内容"""
        # 清除现有内容
        for widget in self.content_frame.winfo_children():
            widget.destroy()
        
        # 读取文件
        if not self.todo_file.exists():
            error_label = tk.Label(
                self.content_frame,
                text=f"文件不存在:\n{self.todo_file}",
                font=('SF Pro Display', 12),
                bg='#141414',
                fg='#ff6b6b',
                justify=tk.LEFT,
                padx=20,
                pady=20
            )
            error_label.pack(anchor='w')
            return
        
        try:
            with open(self.todo_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            error_label = tk.Label(
                self.content_frame,
                text=f"读取错误: {e}",
                font=('SF Pro Display', 12),
                bg='#141414',
                fg='#ff6b6b',
                padx=20,
                pady=20
            )
            error_label.pack(anchor='w')
            return
        
        # 解析 TODO 项
        incomplete_todos = []
        complete_todos = []
        
        for line in lines:
            is_todo, is_completed, content = self.parse_todo_line(line.rstrip('\n'))
            if is_todo:
                if is_completed:
                    complete_todos.append(content)
                else:
                    incomplete_todos.append(content)
        
        # 显示未完成的任务
        if incomplete_todos:
            section_label = tk.Label(
                self.content_frame,
                text=f"待完成 ({len(incomplete_todos)})",
                font=('SF Pro Display', 10, 'bold'),
                bg='#141414',
                fg='#999999',
                anchor='w',
                padx=20,
                pady=(15, 5)
            )
            section_label.pack(fill=tk.X, anchor='w')
            
            for todo in incomplete_todos:
                self.create_todo_item(todo, False)
        
        # 显示已完成的任务
        if complete_todos:
            section_label = tk.Label(
                self.content_frame,
                text=f"已完成 ({len(complete_todos)})",
                font=('SF Pro Display', 10, 'bold'),
                bg='#141414',
                fg='#999999',
                anchor='w',
                padx=20,
                pady=(15, 5)
            )
            section_label.pack(fill=tk.X, anchor='w')
            
            for todo in complete_todos:
                self.create_todo_item(todo, True)
        
        if not incomplete_todos and not complete_todos:
            empty_label = tk.Label(
                self.content_frame,
                text="暂无 TODO 项",
                font=('SF Pro Display', 12),
                bg='#141414',
                fg='#888888',
                padx=20,
                pady=20
            )
            empty_label.pack(anchor='w')
    
    def create_todo_item(self, content: str, completed: bool):
        """创建 TODO 项组件"""
        item_frame = tk.Frame(self.content_frame, bg='#141414')
        item_frame.pack(fill=tk.X, padx=20, pady=2, anchor='w')
        
        # 复选框符号
        checkbox = '✓' if completed else '☐'
        checkbox_label = tk.Label(
            item_frame,
            text=checkbox,
            font=('SF Pro Display', 14),
            bg='#141414',
            fg='#888888' if completed else '#e0e0e0',
            width=2
        )
        checkbox_label.pack(side=tk.LEFT)
        
        # 内容文本
        text_color = '#888888' if completed else '#e0e0e0'
        text_style = 'normal'
        if completed:
            # 为已完成的任务添加删除线效果（通过叠加标签实现）
            content_label = tk.Label(
                item_frame,
                text=content,
                font=('SF Pro Display', 13),
                bg='#141414',
                fg=text_color,
                anchor='w',
                justify=tk.LEFT,
                wraplength=320
            )
            content_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
        else:
            content_label = tk.Label(
                item_frame,
                text=content,
                font=('SF Pro Display', 13),
                bg='#141414',
                fg=text_color,
                anchor='w',
                justify=tk.LEFT,
                wraplength=320
            )
            content_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # 鼠标悬停效果
        def on_enter(e):
            item_frame.configure(bg='#1a1a1a')
            checkbox_label.configure(bg='#1a1a1a')
            content_label.configure(bg='#1a1a1a')
        
        def on_leave(e):
            item_frame.configure(bg='#141414')
            checkbox_label.configure(bg='#141414')
            content_label.configure(bg='#141414')
        
        item_frame.bind("<Enter>", on_enter)
        item_frame.bind("<Leave>", on_leave)
        checkbox_label.bind("<Enter>", on_enter)
        checkbox_label.bind("<Leave>", on_leave)
        content_label.bind("<Enter>", on_enter)
        content_label.bind("<Leave>", on_leave)
    
    def schedule_refresh(self):
        """定时刷新"""
        self.refresh_content()
        self.root.after(self.refresh_interval, self.schedule_refresh)
    
    def run(self):
        """运行应用"""
        self.root.mainloop()


class TodoFileWatcher(FileSystemEventHandler):
    """文件监控器"""
    
    def __init__(self, app: TodoDesktopApp):
        self.app = app
    
    def on_modified(self, event):
        if event.src_path == str(self.app.todo_file.absolute()):
            # 延迟一下，确保文件写入完成
            self.app.root.after(500, self.app.refresh_content)


def main():
    parser = argparse.ArgumentParser(
        description='在 Mac 桌面显示 TODO 列表',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 显示 TODO 列表
  python todo_desktop.py /path/to/todo.md
  
  # 自定义刷新间隔（秒）
  python todo_desktop.py /path/to/todo.md --refresh 5
  
  # 启用文件监控（实时更新）
  python todo_desktop.py /path/to/todo.md --watch
        """
    )
    
    parser.add_argument(
        'todo_file',
        type=Path,
        help='TODO 文件路径'
    )
    
    parser.add_argument(
        '--refresh', '-r',
        type=int,
        default=2,
        help='刷新间隔（秒），默认 2 秒'
    )
    
    parser.add_argument(
        '--watch', '-w',
        action='store_true',
        help='启用文件监控，文件变化时自动刷新'
    )
    
    args = parser.parse_args()
    
    if not args.todo_file.exists():
        print(f"错误: 文件不存在 {args.todo_file}")
        return
    
    # 创建应用
    app = TodoDesktopApp(args.todo_file, args.refresh)
    
    # 如果启用监控
    if args.watch:
        event_handler = TodoFileWatcher(app)
        observer = Observer()
        observer.schedule(event_handler, path=str(args.todo_file.parent), recursive=False)
        observer.start()
        print(f"文件监控已启用: {args.todo_file}")
    
    print(f"TODO 列表已显示在桌面")
    print("按窗口的 × 按钮或 Ctrl+C 退出")
    
    try:
        app.run()
    except KeyboardInterrupt:
        print("\n退出应用")
    finally:
        if args.watch:
            observer.stop()
            observer.join()


if __name__ == '__main__':
    main()


