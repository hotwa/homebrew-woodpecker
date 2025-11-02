# 🧪 自动化系统测试指南

本指南帮助你验证双分支自动化更新系统是否正常工作。

## ✅ 已完成的初始化

- [x] 创建 `auto-sync` 分支
- [x] 配置自动更新 workflow
- [x] 配置自动测试 workflow
- [x] 更新文档说明双分支策略
- [x] 推送两个分支到 GitHub

## 🎯 测试步骤

### 步骤 1: 验证 GitHub 仓库配置 ✅

1. **访问仓库**: https://github.com/hotwa/homebrew-woodpecker

2. **检查分支是否创建成功**:
   - 点击分支下拉菜单
   - 应该看到 `main` 和 `auto-sync` 两个分支

3. **配置 Actions 权限**:
   ```
   Settings → Actions → General
   
   Workflow permissions:
   ✅ 选择 "Read and write permissions"
   ✅ 勾选 "Allow GitHub Actions to create and approve pull requests"
   
   点击 Save
   ```

4. **启用 GitHub Actions**:
   ```
   Actions 标签页
   → 如果看到提示，点击 "I understand my workflows, go ahead and enable them"
   
   左侧应该看到两个 workflow:
   - 🤖 Auto Update Woodpecker Formulae
   - 🧪 Test Formula Build
   ```

### 步骤 2: 手动触发测试（推荐） ⏳

现在我们手动触发一次更新，验证整个流程：

#### 2.1 触发自动更新

1. **进入 Actions 页面**:
   - https://github.com/hotwa/homebrew-woodpecker/actions

2. **选择工作流**:
   - 左侧点击 "Auto Update Woodpecker Formulae"

3. **手动触发**:
   - 点击右上角 "Run workflow" 按钮
   - Branch: 选择 `auto-sync`
   - ✅ 勾选 "强制更新（即使版本相同）"
   - 点击绿色的 "Run workflow" 按钮

4. **观察运行**:
   - 刷新页面，应该看到一个新的运行记录
   - 点击进入查看详细日志
   - 等待 3-5 分钟

#### 2.2 预期结果

**场景 A: 有新版本（当前：v3.10.0 → v3.11.0）**

```
✅ 检测到新版本
✅ 更新 Formula 文件
✅ 验证 Ruby 语法
✅ 提交到 auto-sync 分支
✅ 创建 PR: auto-sync → main
✅ 触发构建测试
```

你应该会看到：
- auto-sync 分支有新提交（版本更新）
- 自动创建了一个 PR
- PR 标题：`🤖 [auto-sync → main] 更新 Woodpecker 到 v3.11.0`

**场景 B: 已是最新版本**

```
ℹ️  当前版本已是最新
ℹ️  无需更新
✅ 工作流正常完成
```

### 步骤 3: 验证 auto-sync 分支更新 🔍

#### 3.1 检查 GitHub 上的提交

1. **切换到 auto-sync 分支**:
   - 在仓库页面，点击分支下拉菜单
   - 选择 `auto-sync`

2. **查看最新提交**:
   - 应该看到一个自动提交
   - 提交者：`github-actions[bot]`
   - 提交信息：`chore: 自动更新 Woodpecker 到 v3.11.0`

3. **检查 Formula 文件**:
   - 点击 `Formula/woodpecker-agent.rb`
   - 查看 `tag:` 行，应该是 `v3.11.0`
   - 查看 `revision` 行，应该递增了

#### 3.2 本地验证（可选）

```bash
cd /Users/lingyuzeng/project/homebrew-woodpecker

# 获取最新的 auto-sync 分支
git fetch origin
git checkout auto-sync
git pull origin auto-sync

# 查看最新提交
git log -1

# 查看版本号
grep "tag:" Formula/woodpecker-agent.rb
# 应该输出: tag: "v3.11.0"

# 测试构建
brew uninstall woodpecker-agent 2>/dev/null || true
brew install --build-from-source ./Formula/woodpecker-agent.rb

# 验证版本
woodpecker-agent --version
# 应该输出: v3.11.0

# 清理
brew uninstall woodpecker-agent
```

### 步骤 4: 验证自动创建的 PR 📋

#### 4.1 查看 PR

1. **进入 Pull Requests 页面**:
   - https://github.com/hotwa/homebrew-woodpecker/pulls

2. **应该看到自动创建的 PR**:
   - 标题：`🤖 [auto-sync → main] 更新 Woodpecker 到 v3.11.0`
   - 标签：`automated`, `dependencies`, `enhancement`, `auto-sync`
   - 来源：`auto-sync` → 目标：`main`

3. **查看 PR 内容**:
   - 版本变更说明
   - 上游 Release 链接
   - 测试建议
   - 分支策略说明

#### 4.2 验证自动测试

1. **在 PR 页面**:
   - 滚动到底部，查看 "Checks" 部分
   - 应该看到 "Test Formula Build" 正在运行或已完成

2. **点击 "Details" 查看测试日志**:
   - 应该在 macOS-14 (M1) 和 macOS-13 (Intel) 上都测试通过
   - 测试内容：构建并验证所有 Formula

3. **等待所有检查通过**:
   ```
   ✅ Test Formula Build / test-build (macos-14)
   ✅ Test Formula Build / test-build (macos-13)
   ```

### 步骤 5: 测试 PR 合并流程 🔀

#### 5.1 本地测试（推荐）

```bash
cd /Users/lingyuzeng/project/homebrew-woodpecker

# 确保在 auto-sync 分支
git checkout auto-sync
git pull origin auto-sync

# 完整测试
echo "🧪 开始测试..."

# 测试 CLI
brew uninstall woodpecker-cli 2>/dev/null || true
brew install --build-from-source ./Formula/woodpecker-cli.rb
woodpecker-cli --version || woodpecker --version

# 测试 Agent（包含所有依赖）
brew uninstall woodpecker-agent 2>/dev/null || true
brew install --build-from-source ./Formula/woodpecker-agent.rb
woodpecker-agent --version

# 检查配置文件
ls -la $(brew --prefix)/etc/woodpecker/

# 检查启动脚本
ls -la $(brew --prefix)/share/woodpecker-agent/

echo "✅ 测试完成"

# 清理
brew uninstall woodpecker-agent woodpecker-cli
```

#### 5.2 合并 PR 到 main

如果测试通过：

1. **在 GitHub PR 页面**:
   - 点击 "Merge pull request" 按钮
   - 选择 "Create a merge commit" 或 "Squash and merge"
   - 点击 "Confirm merge"

2. **验证 main 分支**:
   ```bash
   git checkout main
   git pull origin main
   grep "tag:" Formula/woodpecker-agent.rb
   # 应该是 v3.11.0
   ```

3. **验证用户体验**:
   ```bash
   # 模拟用户更新
   brew tap hotwa/woodpecker
   brew reinstall woodpecker-agent
   woodpecker-agent --version
   ```

### 步骤 6: 验证定时任务配置 ⏰

#### 6.1 检查 workflow 配置

```bash
# 查看定时任务配置
cat .github/workflows/auto-update.yml | grep -A 2 "schedule:"

# 应该输出:
# schedule:
#   - cron: '0 2 * * *'
```

这意味着：
- **每天 UTC 02:00**（北京时间 10:00）自动运行
- 明天上午 10 点会自动检查一次

#### 6.2 等待第一次自动运行

- **时间**: 明天北京时间 10:00
- **预期**: 如果上游有新版本，会自动更新 auto-sync 并创建 PR
- **监控**: 查看 Actions 页面或等待邮件通知

## 📊 测试检查清单

### 初始化 ✅

- [x] auto-sync 分支已创建
- [x] main 分支有 workflow 文件
- [x] auto-sync 分支有 workflow 文件
- [x] 两个分支都推送到 GitHub

### GitHub 配置 ⏳

- [ ] Actions 已启用
- [ ] Workflow permissions 设置为 "Read and write"
- [ ] 允许 Actions 创建 PR

### 功能测试 ⏳

- [ ] 手动触发 workflow 成功
- [ ] auto-sync 分支自动更新
- [ ] 自动创建 PR 到 main
- [ ] 自动测试构建成功（M1 和 Intel）
- [ ] PR 内容格式正确

### 分支策略 ⏳

- [ ] auto-sync 有最新版本（v3.11.0）
- [ ] main 分支保持稳定
- [ ] PR 可以正常合并
- [ ] 合并后 main 更新到新版本

### 用户体验 ⏳

- [ ] 用户可以使用 main 分支（稳定版）
- [ ] 用户可以切换到 auto-sync（最新版）
- [ ] brew install 正常工作
- [ ] brew upgrade 正常工作

## 🎯 成功标准

### 最小成功标准

- ✅ auto-sync 分支自动更新到 v3.11.0
- ✅ 自动创建了 PR
- ✅ 构建测试通过
- ✅ PR 可以成功合并

### 完整成功标准

- ✅ 所有自动化流程无错误
- ✅ 文档清晰易懂
- ✅ 两个分支策略正常工作
- ✅ 用户可以选择使用稳定版或最新版
- ✅ 定时任务配置正确

## 🐛 常见问题处理

### 问题 1: Actions 没有权限创建 PR

**错误信息**: `Resource not accessible by integration`

**解决方法**:
```
Settings → Actions → General
→ Workflow permissions
→ 选择 "Read and write permissions"
→ 勾选 "Allow GitHub Actions to create and approve pull requests"
→ Save
```

### 问题 2: 构建测试失败

**检查**:
1. 查看 Actions 日志中的具体错误
2. 本地重现问题：`brew install --build-from-source ./Formula/woodpecker-agent.rb`
3. 检查上游源码是否有编译问题

### 问题 3: workflow 没有触发

**检查**:
1. workflow 文件语法是否正确
2. Actions 是否已启用
3. 分支名是否正确（应该在 auto-sync 分支运行）

### 问题 4: PR 没有自动创建

**可能原因**:
1. auto-sync 和 main 版本相同（没有变更）
2. 权限不足
3. 已存在相同的 PR

**解决**:
- 勾选"强制更新"重新运行
- 检查权限配置
- 关闭旧的 PR 后重新运行

## 📝 测试日志

### 测试执行记录

```
日期: 2025-11-02
测试人: [你的名字]

测试项目:
□ 手动触发 workflow
□ 验证 auto-sync 更新
□ 验证 PR 创建
□ 验证构建测试
□ 验证 PR 合并
□ 本地功能测试

结果: [ ] 通过 / [ ] 失败

备注:
__________________________________
__________________________________
__________________________________
```

## 🎉 测试完成后

当所有测试通过后：

1. **关闭本文档的测试任务**
2. **记录首次自动更新的时间**（明天 10:00）
3. **设置提醒**，明天检查自动运行结果
4. **通知用户**仓库已启用自动更新

## 📚 相关文档

- [分支策略](BRANCH-STRATEGY.md)
- [自动化文档](AUTOMATION.md)
- [快速开始](QUICKSTART.md)

---

**创建时间**: 2025-11-02  
**状态**: 🧪 测试中  
**下次更新**: 明天北京时间 10:00（首次自动运行）

