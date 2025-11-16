# Übersicht Widget for Obsidian TODO List
# 配置：修改这里的路径为你的 TODO 文件路径
todoFilePath: "/Users/firfis/Documents/Obsidian/记录内容/00-Inbox/TODO list.md"
helperScript: "/Users/firfis/Code/projects/Obsidian_TODO_list管理/desktop_widget/todo_helper.py"

command: """
  FILE_PATH="/Users/firfis/Documents/Obsidian/记录内容/00-Inbox/TODO list.md"
  if [ -f "$FILE_PATH" ]; then
    cat "$FILE_PATH"
  else
    echo "文件不存在: $FILE_PATH"
  fi
"""

refreshFrequency: 3000  # 每3秒刷新一次（降低频率，减少干扰）

# 记录正在切换的任务，避免 update 时覆盖
pendingToggles: {}

# 启用交互（需要在 Übersicht 设置中配置快捷键）
afterRender: (domEl) ->
  # 绑定点击事件 - 点击整个任务项或复选框都可以
  $(domEl).on 'click', '.todo-item, .todo-checkbox', (e) =>
    e.stopPropagation()
    e.preventDefault()
    console.log('点击事件触发')
    $item = $(e.currentTarget).closest('.todo-item')
    if $item.length == 0
      $item = $(e.currentTarget)
    lineIndex = $item.data('line-index')
    console.log('行索引:', lineIndex, '类型:', typeof lineIndex)
    if lineIndex != undefined and lineIndex != null and lineIndex != ''
      # 确保是数字
      lineIndex = parseInt(lineIndex)
      if !isNaN(lineIndex)
        console.log('调用 toggleTodo，行索引:', lineIndex)
        @toggleTodo(lineIndex)
      else
        console.error('行索引不是有效数字:', lineIndex)
    else
      console.error('行索引无效:', lineIndex)
  
  # 绑定添加任务按钮
  $(domEl).on 'click', '.add-todo-btn', (e) =>
    e.stopPropagation()
    @showAddTodoDialog()
  
  # 绑定输入框回车
  $(domEl).on 'keypress', '.new-todo-input', (e) =>
    if e.which == 13  # Enter 键
      content = $(e.currentTarget).val()
      if content.trim()
        $(e.currentTarget).data('editing', false)
        @addTodo(content.trim())
        $(e.currentTarget).val('')
        $(e.currentTarget).closest('.add-todo-form').hide()
  
  # 绑定输入框输入事件（标记为正在编辑）
  $(domEl).on 'input', '.new-todo-input', (e) =>
    $(e.currentTarget).data('editing', true)
  
  # 绑定输入框失焦（点击外部时隐藏）
  $(domEl).on 'blur', '.new-todo-input', (e) =>
    $input = $(e.currentTarget)
    $input.data('editing', false)
    # 延迟隐藏，避免与点击事件冲突
    setTimeout(() =>
      if $input.val().trim() == ''
        $input.closest('.add-todo-form').hide()
    , 200)

toggleTodo: (lineIndex) ->
  console.log('切换任务，行索引:', lineIndex)
  {run} = require 'uebersicht'
  FILE_PATH = @todoFilePath
  HELPER = @helperScript
  
  # 立即更新UI样式（不等待服务器响应）
  $items = $('.todo-item[data-line-index="' + lineIndex + '"]')
  isCurrentlyIncomplete = false
  
  $items.each((index, element) =>
    $item = $(element)
    $checkbox = $item.find('.todo-checkbox')
    
    # 记录当前状态
    isCurrentlyIncomplete = $item.hasClass('todo-incomplete')
    
    # 标记为正在切换，防止 update 覆盖
    @pendingToggles[lineIndex] = !isCurrentlyIncomplete
    
    # 切换样式
    if isCurrentlyIncomplete
      # 从未完成变为完成
      $item.removeClass('todo-incomplete').addClass('todo-complete')
      $checkbox.html('✓')
      $item.find('.todo-content').css('text-decoration', 'line-through')
    else
      # 从完成变为未完成
      $item.removeClass('todo-complete').addClass('todo-incomplete')
      $checkbox.html('')
      $item.find('.todo-content').css('text-decoration', 'none')
  )
  
  # 使用绝对路径确保能找到脚本
  command = "python3 \"#{HELPER}\" toggle \"#{FILE_PATH}\" --line #{lineIndex}"
  console.log('执行命令:', command)
  
  run(command)
    .then((output) =>
      console.log('切换成功:', output)
      # 清除待处理标记
      delete @pendingToggles[lineIndex]
      # 延迟刷新，确保文件已写入，并且给UI足够时间显示变化
      setTimeout(() =>
        @refresh()
      , 1000)
    )
    .catch((err) =>
      console.error('切换失败:', err)
      # 清除待处理标记
      delete @pendingToggles[lineIndex]
      # 如果失败，恢复原样式
      $items.each((index, element) =>
        $item = $(element)
        $checkbox = $item.find('.todo-checkbox')
        if isCurrentlyIncomplete
          # 恢复为未完成
          $item.removeClass('todo-complete').addClass('todo-incomplete')
          $checkbox.html('')
          $item.find('.todo-content').css('text-decoration', 'none')
        else
          # 恢复为完成
          $item.removeClass('todo-incomplete').addClass('todo-complete')
          $checkbox.html('✓')
          $item.find('.todo-content').css('text-decoration', 'line-through')
      )
      alert('切换失败: ' + err) if typeof alert != 'undefined'
    )

addTodo: (content) ->
  {run} = require 'uebersicht'
  FILE_PATH = @todoFilePath
  HELPER = @helperScript
  # 转义内容中的特殊字符
  escapedContent = content.replace(/"/g, '\\"').replace(/\$/g, '\\$')
  
  run("#{HELPER} add \"#{FILE_PATH}\" --content \"#{escapedContent}\"")
    .then(() =>
      @refresh()
    )
    .catch((err) =>
      console.error('添加失败:', err)
    )

showAddTodoDialog: ->
  # 从 afterRender 中获取 domEl，需要通过闭包保存
  # 这里使用全局查找，因为 afterRender 中已经绑定了事件
  $content = $('.todo-widget-container .content')
  if $content.length == 0
    $content = $('.content')
  
  $form = $content.find('.add-todo-form')
  if $form.length == 0
    $form = $('<div class="add-todo-form"><input type="text" class="new-todo-input" placeholder="输入新任务..."></div>')
    $content.prepend($form)
  
  $form.show()
  # 延迟聚焦，确保 DOM 已更新
  setTimeout(() =>
    $input = $form.find('.new-todo-input')
    $input.focus()
    # 标记输入框状态，防止 update 时清除
    $input.data('editing', true)
  , 100)

style: """
  top: 50px
  right: 50px
  width: 480px
  max-height: 750px
  background: linear-gradient(135deg, rgba(30, 30, 40, 0.98) 0%, rgba(25, 25, 35, 0.98) 100%)
  border-radius: 16px
  padding: 0
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif
  font-size: 18px
  color: #e8e8e8
  box-shadow: 0 12px 48px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.05)
  backdrop-filter: blur(20px)
  overflow: hidden
  display: flex
  flex-direction: column
  box-sizing: border-box
  
  .header
    font-size: 22px
    font-weight: 700
    margin: 0
    padding: 24px 28px 20px
    color: #ffffff
    background: linear-gradient(135deg, rgba(100, 120, 255, 0.15) 0%, rgba(150, 100, 255, 0.1) 100%)
    border-bottom: 1px solid rgba(255, 255, 255, 0.1)
    display: flex
    justify-content: space-between
    align-items: center
    
  .header-title
    display: flex
    align-items: center
    gap: 10px
    
  .add-todo-btn
    background: rgba(100, 120, 255, 0.2)
    border: 1px solid rgba(100, 120, 255, 0.3)
    border-radius: 8px
    padding: 6px 14px
    color: #a0b0ff
    font-size: 12px
    font-weight: 600
    cursor: pointer
    transition: all 0.2s
    user-select: none
    
  .add-todo-btn:hover
    background: rgba(100, 120, 255, 0.3)
    border-color: rgba(100, 120, 255, 0.5)
    transform: translateY(-1px)
    
  .add-todo-form
    padding: 16px 28px
    border-bottom: 1px solid rgba(255, 255, 255, 0.08)
    background: rgba(0, 0, 0, 0.2)
    
  .new-todo-input
    width: 100%
    background: rgba(255, 255, 255, 0.08)
    border: 1px solid rgba(255, 255, 255, 0.15)
    border-radius: 8px
    padding: 10px 14px
    color: #ffffff
    font-size: 13px
    font-family: inherit
    outline: none
    transition: all 0.2s
    
  .new-todo-input:focus
    background: rgba(255, 255, 255, 0.12)
    border-color: rgba(100, 120, 255, 0.5)
    box-shadow: 0 0 0 3px rgba(100, 120, 255, 0.1)
    
  .new-todo-input::placeholder
    color: rgba(255, 255, 255, 0.4)
    
  .content
    flex: 1
    overflow-y: scroll
    overflow-x: hidden
    padding: 16px 28px 20px 28px
    max-height: calc(750px - 100px)
    box-sizing: border-box
    
  .section-title
    font-size: 11px
    font-weight: 700
    color: #888
    margin-top: 16px
    margin-bottom: 8px
    text-transform: uppercase
    letter-spacing: 1px
    
  .section-title:first-child
    margin-top: 0
    
  .todo-item
    margin: 4px 0
    padding: 8px 12px
    border-radius: 8px
    transition: all 0.2s
    line-height: 1.5
    display: flex
    align-items: flex-start
    cursor: pointer
    border: 1px solid transparent
    
  .todo-item:hover
    background: rgba(255, 255, 255, 0.06)
    border-color: rgba(255, 255, 255, 0.08)
    transform: translateX(2px)
    
  .todo-incomplete
    color: #e8e8e8
    
  .todo-complete
    color: #666
    opacity: 0.7
    
  .todo-checkbox
    margin-right: 12px
    font-size: 20px
    line-height: 1
    cursor: pointer
    user-select: none
    transition: all 0.2s
    flex-shrink: 0
    margin-top: 2px
    width: 24px
    height: 24px
    display: inline-flex
    align-items: center
    justify-content: center
    border-radius: 6px
    background: rgba(255, 255, 255, 0.05)
    border: 2px solid rgba(255, 255, 255, 0.2)
    
  .todo-incomplete .todo-checkbox
    color: #a0b0ff
    border-color: #a0b0ff
    
  .todo-incomplete .todo-checkbox:hover
    color: #b0c0ff
    border-color: #b0c0ff
    background: rgba(160, 176, 255, 0.1)
    transform: scale(1.05)
    
  .todo-complete .todo-checkbox
    color: #4ade80
    border-color: #4ade80
    background: rgba(74, 222, 128, 0.15)
    
  .todo-content
    flex: 1
    word-wrap: break-word
    font-size: 15px
    line-height: 1.6
    
  .todo-complete .todo-content
    text-decoration: line-through
    
  .error
    color: #ff6b6b
    padding: 20px
    background: rgba(255, 107, 107, 0.1)
    border-radius: 10px
    border: 1px solid rgba(255, 107, 107, 0.2)
    margin: 20px
    
  /* 滚动条样式 */
  ::-webkit-scrollbar
    width: 8px
    
  ::-webkit-scrollbar-track
    background: rgba(255, 255, 255, 0.03)
    border-radius: 4px
    
  ::-webkit-scrollbar-thumb
    background: rgba(255, 255, 255, 0.15)
    border-radius: 4px
    
  ::-webkit-scrollbar-thumb:hover
    background: rgba(255, 255, 255, 0.25)
"""

render: (output) ->
  output = output or ""
  if output.includes("文件不存在") or output.trim() == ""
    html = """
      <div class="todo-widget-container">
        <div class="header">
          <div class="header-title">📋 TODO List</div>
        </div>
        <div class="error">#{output or "无法读取文件"}</div>
      </div>
    """
  else
    parsedContent = @parseMarkdown(output)
    html = """
      <div class="todo-widget-container">
        <div class="header">
          <div class="header-title">📋 TODO List</div>
          <button class="add-todo-btn">+ 添加</button>
        </div>
        <div class="content">#{parsedContent}</div>
      </div>
    """
  return html

parseMarkdown: (text) ->
  if not text or text.trim() == ""
    return '<div class="error">文件为空或无法读取</div>'
  if text.includes("文件不存在")
    return '<div class="error">' + text + '</div>'
  
  lines = text.split('\n')
  html = []
  incompleteCount = 0
  completeCount = 0
  todoLineIndex = 0
  
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
    for i in [0...lines.length]
      line = lines[i]
      if @isTodoLine(line) and not @isCompleted(line)
        html.push @renderTodoItem(line, false, i, todoLineIndex)
        todoLineIndex++
  
  # 渲染已完成的任务
  if completeCount > 0
    html.push '<div class="section-title">已完成 (' + completeCount + ')</div>'
    for i in [0...lines.length]
      line = lines[i]
      if @isTodoLine(line) and @isCompleted(line)
        html.push @renderTodoItem(line, true, i, todoLineIndex)
        todoLineIndex++
  
  if html.length == 0
    return '<div style="color: #888; padding: 20px; text-align: center;">暂无 TODO 项</div>'
  
  return html.join('')

isTodoLine: (line) ->
  /^\s*-\s+\[[ x]\]/.test(line)

isCompleted: (line) ->
  /^\s*-\s+\[x\]/.test(line)

renderTodoItem: (line, completed, fileLineIndex, todoIndex) ->
  # 提取内容（去掉 - [x] 或 - [ ]）
  content = line.replace(/^\s*-\s+\[[ x]\]\s*/, '')
  # 转义 HTML
  content = content.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  
  # 使用更好的复选框图标
  checkbox = if completed then '✓' else ''
  className = if completed then 'todo-item todo-complete' else 'todo-item todo-incomplete'
  
  # 确保 fileLineIndex 是数字
  lineIndex = parseInt(fileLineIndex)
  if isNaN(lineIndex)
    lineIndex = fileLineIndex
  
  """
    <div class="#{className}" data-line-index="#{lineIndex}">
      <span class="todo-checkbox">#{checkbox}</span>
      <span class="todo-content">#{content}</span>
    </div>
  """

update: (output, domEl) ->
  output = output or ""
  # 检查是否有输入框正在显示
  $form = $(domEl).find('.add-todo-form')
  $input = $form.find('.new-todo-input')
  
  # 如果输入框正在编辑（有焦点或有内容），不更新（避免打断输入）
  isEditing = $input.length > 0 and ($input.is(':focus') or $input.data('editing') or $input.val().length > 0)
  if $form.is(':visible') and isEditing
    return
  
  # 检查是否有正在切换的任务，如果有则跳过更新（避免覆盖立即更新的UI）
  hasPendingToggles = false
  for lineIndex, newState of @pendingToggles
    hasPendingToggles = true
    break
  
  if hasPendingToggles
    console.log('有任务正在切换，跳过 update')
    return
  
  # 保存输入框状态
  inputValue = if $input.length then $input.val() else ''
  isFormVisible = $form.is(':visible')
  
  # 更新内容
  $content = $(domEl).find('.content')
  if $content.length == 0
    # 如果内容区域不存在，重新渲染整个 widget
    $(domEl).html(@render(output))
    return
  
  $content.html(@parseMarkdown(output))
  
  # 恢复输入框状态（如果需要）
  if isFormVisible and inputValue
    $form = $(domEl).find('.add-todo-form')
    if $form.length == 0
      # 如果表单不存在，重新创建
      $form = $('<div class="add-todo-form"><input type="text" class="new-todo-input" placeholder="输入新任务..."></div>')
      $content.prepend($form)
    $form.show()
    $newInput = $form.find('.new-todo-input')
    $newInput.val(inputValue)
    if inputValue.length > 0
      $newInput.data('editing', true)
