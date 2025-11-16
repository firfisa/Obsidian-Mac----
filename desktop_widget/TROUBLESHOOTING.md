# 故障排除指南

## 问题：Widget 不显示

### 最常见原因：Übersicht 没有运行

**解决方法：**
1. 打开"应用程序"文件夹
2. 找到并打开 "Übersicht" 应用
3. 等待几秒钟，widget 应该会显示

**检查是否运行：**
- 查看菜单栏右上角是否有 Übersicht 图标
- 如果没有，说明应用没有运行

### 其他可能的问题

#### 1. Widget 未启用
- 点击菜单栏的 Übersicht 图标
- 确认 `todo-widget` 旁边有 ✓
- 如果没有，点击启用

#### 2. 辅助功能权限
- 打开"系统设置 > 隐私与安全性 > 辅助功能"
- 确保 Übersicht 已勾选
- 如果没有，点击 + 添加 Übersicht

#### 3. 文件路径错误
- 检查 `index.coffee` 中的 `todoFilePath` 是否正确
- 确保路径使用绝对路径（以 `/` 开头）
- 确保文件确实存在

#### 4. 需要刷新
- 在 Übersicht 菜单中点击 "Refresh Widgets"
- 或者禁用后重新启用 widget

#### 5. 桌面被遮挡
- 最小化所有窗口
- 检查 widget 设置的位置（默认在左上角或右上角）

### 测试步骤

1. **启动 Übersicht**
   ```bash
   open -a Übersicht
   ```

2. **检查菜单栏图标**
   - 应该能看到 Übersicht 图标

3. **启用 Widget**
   - 点击图标，找到 `todo-widget` 并启用

4. **查看桌面**
   - 应该能看到 widget（红色测试框或正常的 TODO 列表）

### 开机自启动

如果希望 Übersicht 开机自动启动：
1. 打开"系统设置 > 通用 > 登录项"
2. 点击 + 添加 Übersicht
3. 这样每次开机 Übersicht 会自动运行

