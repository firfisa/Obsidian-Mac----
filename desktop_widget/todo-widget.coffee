# Übersicht Widget for Obsidian TODO List
# 配置：修改这里的路径为你的 TODO 文件路径
todoFilePath: "/Users/firfis/Documents/Obsidian/记录内容/00-Inbox/TODO list.md"
helperScript: "/Users/firfis/Code/projects/Obsidian_TODO_list管理/desktop_widget/todo_helper.py"

command: """
  FILE_PATH="/Users/firfis/Documents/Obsidian/记录内容/00-Inbox/TODO list.md"
  HELPER="/Users/firfis/Code/projects/Obsidian_TODO_list管理/desktop_widget/todo_helper.py"
  if [ -f "$FILE_PATH" ]; then
    /usr/bin/python3 "$HELPER" refresh "$FILE_PATH" >/dev/null 2>&1 || true
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
  $(domEl).on 'click', '.tag-chk', (e) =>
    e.stopPropagation()
    $form = $(e.currentTarget).closest('.add-todo-form')
    $input = $form.find('.new-todo-input')
    $input.data('editing', true)
    setTimeout(() =>
      $input.focus()
    , 0)
  
  $(domEl).on 'click', '.new-todo-submit', (e) =>
    e.preventDefault()
    e.stopPropagation()
    @handleAddSubmit()
  
  $(domEl).on 'click', '.todo-checkbox', (e) =>
    e.stopPropagation()
    e.preventDefault()
    console.log('点击事件触发')
    $item = $(e.currentTarget).closest('.todo-item')
    if $item.length == 0
      $item = $(e.currentTarget)
    lineIndex = $item.data('line-index')
    console.log('行索引:', lineIndex, '类型:', typeof lineIndex)
    if lineIndex != undefined and lineIndex != null and lineIndex != ''
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
      @handleAddSubmit()
  
  # 绑定输入框输入事件（标记为正在编辑）
  $(domEl).on 'input', '.new-todo-input', (e) =>
    $(e.currentTarget).data('editing', true)
  
  # 绑定输入框失焦（点击外部时隐藏）
  $(domEl).on 'blur', '.new-todo-input', (e) =>
    $input = $(e.currentTarget)
    $input.data('editing', false)
    # 延迟隐藏，避免与点击事件冲突
    setTimeout(() =>
      $form = $input.closest('.add-todo-form')
      if $input.val().trim() == '' and $form.find(':focus').length == 0
        $form.hide()
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
  $content = $('.todo-widget-container .content')
  $form = $content.find('.add-todo-form')
  if $form.length == 0
    $form = $(@newTodoFormTemplate())
    $content.prepend($form)
  
  $form.show()
  setTimeout(() =>
    $form.find('.new-todo-input').focus().data('editing', true)
  , 100)

newTodoFormTemplate: ->
  """
    <div class="add-todo-form">
      <div class="new-todo-shell">
        <div class="tag-group">
          <label><input type="checkbox" class="tag-chk" data-tag="-today"> 今日</label>
          <label><input type="checkbox" class="tag-chk" data-tag="-everyday"> 每日</label>
          <label><input type="checkbox" class="tag-chk" data-tag="-imp"> 重要</label>
          <label><input type="checkbox" class="tag-chk" data-tag="-emer"> 紧急</label>
        </div>
        <div class="new-todo-row">
          <input type="text" class="new-todo-input" placeholder="输入新任务..." />
          <button class="new-todo-submit">添加</button>
        </div>
      </div>
    </div>
  """

handleAddSubmit: ->
  $form = $('.add-todo-form:visible')
  return unless $form.length
  $input = $form.find('.new-todo-input')
  content = $input.val().trim()
  return unless content.length
  tags = []
  $form.find('.tag-chk:checked').each (idx, el) ->
    tags.push($(el).data('tag'))
  fullContent = "#{content} #{tags.join(' ')}".trim()
  $input.data('editing', false)
  $input.val('')
  $form.find('.tag-chk').prop('checked', false)
  $form.hide()
  @addTodo(fullContent)

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
    background: rgba(0, 0, 0, 0.1)
    
  .new-todo-shell
    background: rgba(0, 0, 0, 0.15)
    border-radius: 12px
    padding: 12px
    display: flex
    flex-direction: column
    gap: 12px
  
  .tag-group
    display: flex
    flex-wrap: wrap
    gap: 12px
    font-size: 12px
    color: #c0c7e3
  .tag-group label
    display: flex
    align-items: center
    gap: 6px
    background: rgba(255, 255, 255, 0.06)
    padding: 4px 10px
    border-radius: 999px
    border: 1px solid transparent
  .tag-group input[type="checkbox"]
    accent-color: #818cf8
  
  .new-todo-row
    display: flex
    gap: 8px
    align-items: center
  
  .new-todo-input
    flex: 1
    background: rgba(255, 255, 255, 0.08)
    border: 1px solid rgba(255, 255, 255, 0.15)
    border-radius: 10px
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
  
  .new-todo-submit
    padding: 10px 18px
    border-radius: 10px
    border: none
    background: linear-gradient(135deg, #6366f1, #8b5cf6)
    color: #fff
    font-weight: 600
    cursor: pointer
    transition: transform 0.2s ease, opacity 0.2s ease
  .new-todo-submit:hover
    transform: translateY(-1px)
    
  .new-todo-input::placeholder
    color: rgba(255, 255, 255, 0.4)
    
  .summary-panel
    padding: 18px 28px 6px
    display: grid
    grid-template-columns: repeat(3, minmax(0, 1fr))
    gap: 12px
    border-bottom: 1px solid rgba(255, 255, 255, 0.06)
  
  .summary-card
    background: rgba(255, 255, 255, 0.04)
    border: 1px solid rgba(255, 255, 255, 0.08)
    border-radius: 12px
    padding: 12px
    display: flex
    flex-direction: column
    gap: 4px
    transition: border 0.2s ease, transform 0.2s ease
  .summary-card.highlight
    background: linear-gradient(145deg, rgba(97, 218, 251, 0.18), rgba(129, 140, 248, 0.25))
    border-color: rgba(129, 140, 248, 0.35)
  .summary-card:hover
    border-color: rgba(255, 255, 255, 0.2)
    transform: translateY(-2px)
  
  .summary-label
    font-size: 11px
    letter-spacing: 1px
    text-transform: uppercase
    color: #a6b0d8
  
  .summary-value
    font-size: 24px
    font-weight: 700
    color: #ffffff
  
  .summary-subtitle
    font-size: 12px
    color: #b9c2e3
  
  .progress-wrapper
    grid-column: 1 / -1
    margin-top: 6px
  
  .progress-header
    display: flex
    justify-content: space-between
    font-size: 12px
    color: #b9c2e3
    margin-bottom: 6px
  
  .progress-track
    width: 100%
    height: 8px
    border-radius: 999px
    background: rgba(255, 255, 255, 0.08)
    overflow: hidden
  
  .progress-fill
    height: 100%
    border-radius: 999px
    background: linear-gradient(135deg, #34d399, #10b981)
    transition: width 0.3s ease
  
  .today-section
    padding: 20px 24px
    border-radius: 18px
    border: 1px solid rgba(255, 255, 255, 0.08)
    background: rgba(255, 255, 255, 0.03)
    display: flex
    flex-direction: column
    gap: 16px
  .today-header
    display: flex
    justify-content: space-between
    align-items: center
  .today-title
    font-size: 16px
    font-weight: 700
  .today-subtitle
    font-size: 12px
    color: #a4acc8
    margin-top: 4px
  .today-count
    width: 42px
    height: 42px
    border-radius: 14px
    background: rgba(129, 140, 248, 0.15)
    color: #c7d2fe
    font-weight: 700
    display: flex
    align-items: center
    justify-content: center
    font-size: 18px
  .today-body
    display: flex
    flex-direction: column
    gap: 8px
  .today-empty
    text-align: center
    color: #9aa4c6
    font-size: 13px
    padding: 24px 0
    border: 1px dashed rgba(255, 255, 255, 0.15)
    border-radius: 12px
  
  .content
    flex: 1
    overflow-y: scroll
    overflow-x: hidden
    padding: 18px 28px 24px 28px
    max-height: calc(750px - 120px)
    box-sizing: border-box
    display: flex
    flex-direction: column
    gap: 18px
    
  .section
    display: flex
    flex-direction: column
    gap: 10px
  
  .section-header
    display: flex
    justify-content: space-between
    align-items: center
    font-size: 12px
    letter-spacing: 1px
    text-transform: uppercase
    color: #9ba4c6
  
  .section-count
    padding: 2px 8px
    border-radius: 999px
    background: rgba(255, 255, 255, 0.08)
    font-size: 11px
  
  .section-body
    display: flex
    flex-direction: column
  
  .todo-content-block
    display: flex
    flex-direction: column
    gap: 4px
  
  .todo-meta
    font-size: 11px
    color: #9098b6
    display: flex
    justify-content: space-between
    align-items: center
    gap: 8px
  .todo-badge
    font-size: 10px
    text-transform: uppercase
    letter-spacing: 0.6px
    padding: 2px 8px
    border-radius: 999px
    background: rgba(255, 255, 255, 0.12)
    color: #e2e8ff
  .todo-badge.today
    background: rgba(248, 250, 146, 0.25)
    color: #fef9c3
  .todo-badge.duo
    background: rgba(94, 234, 212, 0.2)
    color: #99f6e4
  .todo-badge.everyday
    background: rgba(96, 165, 250, 0.2)
    color: #bfdbfe
  .todo-badge.important
    background: rgba(249, 115, 22, 0.3)
    color: #ffedd5
  .todo-badge.urgent
    background: rgba(59, 130, 246, 0.3)
    color: #dbeafe
  .todo-badge.critical
    background: rgba(239, 68, 68, 0.4)
    color: #fee2e2
    
  .todo-item
    margin: 4px 0
    padding: 8px 12px
    border-radius: 8px
    transition: all 0.2s
    line-height: 1.5
    display: flex
    align-items: flex-start
    cursor: default
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
  .todo-item.is-important:not(.todo-complete) .todo-checkbox
    border-color: rgba(249, 115, 22, 0.9)
    color: #ffedd5
  .todo-item.is-urgent:not(.todo-complete) .todo-checkbox
    border-color: rgba(59, 130, 246, 0.9)
    color: #dbeafe
  .todo-item.is-critical:not(.todo-complete) .todo-checkbox
    border-color: rgba(239, 68, 68, 1)
    background: rgba(239, 68, 68, 0.2)
    color: #fee2e2
    
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
    font-size: 17px
    line-height: 1.7
    color: #f7f7fb
    display: inline-flex
    flex-wrap: wrap
    gap: 4px
    align-items: baseline
  .todo-tags
    display: inline-flex
    gap: 6px
  .todo-badge
    font-size: 10px
    text-transform: uppercase
    letter-spacing: 0.6px
    padding: 2px 8px
    border-radius: 999px
    background: rgba(255, 255, 255, 0.12)
    color: #e2e8ff
  .todo-badge.today
    background: rgba(248, 250, 146, 0.25)
    color: #fef9c3
  .todo-badge.duo
    background: rgba(94, 234, 212, 0.2)
    color: #99f6e4
    
  .todo-complete .todo-content
    text-decoration: line-through
    
  .todo-meta
    font-size: 12px
    color: #aab0cf
    margin-top: 4px
    
  .empty-state
    padding: 80px 20px
    text-align: center
    color: #c2c9e3
    border: 1px dashed rgba(255, 255, 255, 0.2)
    border-radius: 14px
    background: rgba(255, 255, 255, 0.02)
  
  .empty-icon
    font-size: 36px
    margin-bottom: 12px
  
  .empty-title
    font-size: 20px
    font-weight: 700
  
  .empty-subtitle
    font-size: 13px
    margin-top: 6px
    color: #9faad0
    
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
  return '<div class="error">文件为空或无法读取</div>' unless text and text.trim() != ""
  return '<div class="error">' + text + '</div>' if text.indexOf("文件不存在") == 0
  
  data = @extractTodos(text)
  total = data.todos.length
  return @renderEmptyState() if total == 0
  
  html = []
  html.push @renderSummaryPanel(data)
  html.push @renderTodaySection(@sortTasksByPriority(data.todayIncomplete))
  
  if data.incomplete.length > 0
    html.push @renderSection('待完成', @sortTasksByPriority(data.incomplete))
  
  if data.complete.length > 0
    html.push @renderSection('已完成', data.complete)
  
  html.join('')

isTodoLine: (line) ->
  /^\s*-\s+\[[ x]\]/.test(line)

isCompleted: (line) ->
  /^\s*-\s+\[x\]/.test(line)

renderTodoItem: (task) ->
  checkbox = if task.completed then '✓' else ''
  baseClass = if task.completed then 'todo-item todo-complete' else 'todo-item todo-incomplete'
  priorityClasses = []
  priorityClasses.push('is-important') if task.isImportant
  priorityClasses.push('is-urgent') if task.isUrgent
  priorityClasses.push('is-critical') if task.isImportant and task.isUrgent
  className = [baseClass].concat(priorityClasses).join(' ')
  content = @escapeHtml(task.content)
  tagsHtml = if task.badges?.length
    ordered = @orderBadges(task.badges, task)
    badgeHtml = ordered.map((badge) =>
      "<span class=\"todo-badge #{badge}\">#{@badgeLabel(badge)}</span>"
    ).join('')
    " <span class=\"todo-tags\">#{badgeHtml}</span>"
  else
    ''
  metaText = ''
  if task.completed and task.completedOn
    metaText = '完成于 ' + task.completedOn
  metaBlock = if metaText then "<div class=\"todo-meta\">#{metaText}</div>" else ''
  """
    <div class="#{className}" data-line-index="#{task.lineIndex}">
      <span class="todo-checkbox">#{checkbox}</span>
      <div class="todo-content-block">
        <span class="todo-content">#{content}#{tagsHtml}</span>
        #{metaBlock}
      </div>
    </div>
  """

renderSection: (title, tasks) ->
  items = tasks.map((task) => @renderTodoItem(task)).join('')
  """
    <div class="section">
      <div class="section-header">
        <span class="section-name">#{title}</span>
        <span class="section-count">#{tasks.length}</span>
      </div>
      <div class="section-body">
        #{items}
      </div>
    </div>
  """

renderSummaryPanel: (data) ->
  total = data.todos.length
  completeCount = data.complete.length
  incompleteCount = data.incomplete.length
  todayCount = data.todayIncomplete.length
  progress = if total == 0 then 0 else Math.round((completeCount / total) * 100)
  """
    <div class="summary-panel">
      <div class="summary-card highlight">
        <div class="summary-label">今日待办</div>
        <div class="summary-value">#{todayCount}</div>
        <div class="summary-subtitle">今天必须完成</div>
      </div>
      <div class="summary-card">
        <div class="summary-label">未完成</div>
        <div class="summary-value">#{incompleteCount}</div>
        <div class="summary-subtitle">包含今日与待办</div>
      </div>
      <div class="summary-card">
        <div class="summary-label">已完成</div>
        <div class="summary-value">#{completeCount}</div>
        <div class="summary-subtitle">坚持就是胜利</div>
      </div>
      <div class="progress-wrapper">
        <div class="progress-header">
          <span>整体进度</span>
          <span>#{progress}%</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill" style="width: #{progress}%;"></div>
        </div>
      </div>
    </div>
  """

renderTodaySection: (tasks) ->
  body = if tasks.length > 0
    tasks.map((task) => @renderTodoItem(task)).join('')
  else
    '<div class="today-empty">今日任务已全部完成 ✅</div>'
  """
    <div class="today-section">
      <div class="today-header">
        <div>
          <div class="today-title">今日任务</div>
          <div class="today-subtitle">#{if tasks.length > 0 then '聚焦最重要的几件事' else '没有新的今日任务'}</div>
        </div>
        <div class="today-count">#{tasks.length}</div>
      </div>
      <div class="today-body">
        #{body}
      </div>
    </div>
  """

renderEmptyState: ->
  """
    <div class="empty-state">
      <div class="empty-icon">✨</div>
      <div class="empty-title">暂无任务</div>
      <div class="empty-subtitle">点击右上角按钮，记录第一条待办</div>
    </div>
  """

extractTodos: (text) ->
  todos = []
  lines = text.split('\n')
  for line, idx in lines
    continue unless @isTodoLine(line)
    completed = @isCompleted(line)
    content = line.replace(/^\s*-\s+\[[ x]\]\s*/, '').trim()
    meta = @parseTodoContent(content)
    todos.push({
      lineIndex: idx
      completed: completed
      content: meta.content
      completedOn: meta.completedOn
      badges: meta.badges
      isToday: meta.isToday
      isEveryday: meta.isEveryday
      isImportant: meta.isImportant
      isUrgent: meta.isUrgent
    })
  {
    todos: todos
    incomplete: todos.filter((t) -> not t.completed)
    complete: todos.filter((t) -> t.completed)
    todayIncomplete: todos.filter((t) -> t.isToday and not t.completed)
  }

parseTodoContent: (rawText) ->
  text = rawText or ''
  info =
    content: text
    badges: []
    isToday: false
    isEveryday: false
    isImportant: false
    isUrgent: false
    completedOn: null
  
  content = text
  content = content.replace(/\s+-today\b/ig, (match) =>
    info.isToday = true
    info.badges.push('today') if info.badges.indexOf('today') == -1
    ''
  )
  content = content.replace(/\s+-everyday\b/ig, (match) =>
    info.isToday = true
    info.isEveryday = true
    info.badges.push('everyday') if info.badges.indexOf('everyday') == -1
    ''
  )
  content = content.replace(/\s+-duo\b/ig, (match) =>
    info.badges.push('duo') if info.badges.indexOf('duo') == -1
    ''
  )
  content = content.replace(/\s+-done:(\d{4}-\d{2}-\d{2})/i, (match, date) =>
    info.completedOn = date
    ''
  )
  content = content.replace(/\s+-imp\b/ig, (match) =>
    info.isImportant = true
    info.badges.push('important') if info.badges.indexOf('important') == -1
    ''
  )
  content = content.replace(/\s+-emer\b/ig, (match) =>
    info.isUrgent = true
    info.badges.push('urgent') if info.badges.indexOf('urgent') == -1
    ''
  )
  info.content = content.trim()
  info

badgeLabel: (badge) ->
  switch badge
    when 'today' then '今日'
    when 'everyday' then '每日'
    when 'duo' then 'DUO'
    when 'important' then '重要'
    when 'urgent' then '紧急'
    else badge.toUpperCase()

orderBadges: (badges, task) ->
  priority = ['critical', 'important', 'urgent', 'today', 'everyday', 'duo']
  normalized = badges.slice()
  showCritical = task.isImportant and task.isUrgent
  if showCritical and normalized.indexOf('critical') == -1
    normalized.unshift('critical')
  normalized.sort (a, b) ->
    indexA = priority.indexOf(a)
    indexB = priority.indexOf(b)
    indexA = 999 if indexA == -1
    indexB = 999 if indexB == -1
    indexA - indexB
  normalized

sortTasksByPriority: (tasks) ->
  return tasks unless tasks?.length
  tasks.slice().sort (a, b) =>
    @priorityScore(b) - @priorityScore(a)

priorityScore: (task) ->
  return 3 if task.isImportant and task.isUrgent
  return 2 if task.isImportant
  return 1 if task.isUrgent
  0

escapeHtml: (text) ->
  return '' unless text?
  text.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')

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
      $form = $(@newTodoFormTemplate())
      $content.prepend($form)
    $form.show()
    $newInput = $form.find('.new-todo-input')
    $newInput.val(inputValue)
    if inputValue.length > 0
      $newInput.data('editing', true)
