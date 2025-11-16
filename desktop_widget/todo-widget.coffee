# Übersicht Widget for Obsidian TODO List
# 在 ~/Library/Application Support/Übersicht/widgets/ 目录下创建 todo-widget 文件夹
# 将此文件放入该文件夹，命名为 index.coffee

# 配置：修改这里的路径为你的 TODO 文件路径
todoFilePath: "/Users/firfis/Documents/Obsidian/记录内容/00-Inbox/TODO list.md"

command: """
  if [ -f "#{todoFilePath}" ]; then
    cat "#{todoFilePath}"
  else
    echo "文件不存在: #{todoFilePath}"
  fi
"""

refreshFrequency: 2000  # 每2秒刷新一次

style: """
  top: 20px
  right: 20px
  width: 400px
  max-height: 600px
  background: rgba(20, 20, 20, 0.85)
  border-radius: 12px
  padding: 20px
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
  font-size: 13px
  color: #e0e0e0
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3)
  backdrop-filter: blur(10px)
  overflow-y: auto
  overflow-x: hidden
  
  .header
    font-size: 18px
    font-weight: 600
    margin-bottom: 15px
    color: #ffffff
    border-bottom: 1px solid rgba(255, 255, 255, 0.1)
    padding-bottom: 10px
    
  .todo-item
    margin: 8px 0
    padding: 8px 12px
    border-radius: 6px
    transition: background 0.2s
    line-height: 1.5
    
  .todo-item:hover
    background: rgba(255, 255, 255, 0.05)
    
  .todo-incomplete
    color: #e0e0e0
    
  .todo-complete
    color: #888
    text-decoration: line-through
    opacity: 0.6
    
  .todo-checkbox
    margin-right: 8px
    font-size: 14px
    
  .section-title
    font-size: 12px
    font-weight: 600
    color: #999
    margin-top: 15px
    margin-bottom: 8px
    text-transform: uppercase
    letter-spacing: 0.5px
    
  .error
    color: #ff6b6b
    padding: 10px
    
  /* 滚动条样式 */
  ::-webkit-scrollbar
    width: 6px
    
  ::-webkit-scrollbar-track
    background: rgba(255, 255, 255, 0.05)
    border-radius: 3px
    
  ::-webkit-scrollbar-thumb
    background: rgba(255, 255, 255, 0.2)
    border-radius: 3px
    
  ::-webkit-scrollbar-thumb:hover
    background: rgba(255, 255, 255, 0.3)
"""

render: (output) ->
  """
    <div class="header">📋 TODO List</div>
    <div class="content">#{@parseMarkdown(output)}</div>
  """

parseMarkdown: (text) ->
  if not text or text.trim() == "" or text.includes("文件不存在")
    return '<div class="error">无法读取 TODO 文件</div>'
  
  lines = text.split('\n')
  html = []
  inIncompleteSection = true
  incompleteCount = 0
  completeCount = 0
  
  # 先统计数量
  for line in lines
    if @isTodoLine(line)
      if @isCompleted(line)
        completeCount++
      else
        incompleteCount++
  
  # 渲染未完成的任务
  if incompleteCount > 0
    html.push '<div class="section-title">待完成 (' + incompleteCount + ')</div>'
    for line in lines
      if @isTodoLine(line) and not @isCompleted(line)
        html.push @renderTodoItem(line, false)
  
  # 渲染已完成的任务
  if completeCount > 0
    html.push '<div class="section-title">已完成 (' + completeCount + ')</div>'
    for line in lines
      if @isTodoLine(line) and @isCompleted(line)
        html.push @renderTodoItem(line, true)
  
  if html.length == 0
    return '<div style="color: #888; padding: 10px;">暂无 TODO 项</div>'
  
  return html.join('')

isTodoLine: (line) ->
  /^\s*-\s+\[[ x]\]/.test(line)

isCompleted: (line) ->
  /^\s*-\s+\[x\]/.test(line)

renderTodoItem: (line, completed) ->
  # 提取内容（去掉 - [x] 或 - [ ]）
  content = line.replace(/^\s*-\s+\[[ x]\]\s*/, '')
  # 转义 HTML
  content = content.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  
  checkbox = if completed then '✓' else '☐'
  className = if completed then 'todo-item todo-complete' else 'todo-item todo-incomplete'
  
  """
    <div class="#{className}">
      <span class="todo-checkbox">#{checkbox}</span>
      <span>#{content}</span>
    </div>
  """

update: (output, domEl) ->
  $(domEl).find('.content').html(@parseMarkdown(output))

