# 🚀 GitHub Actions 快速启动指南

本指南帮助你快速启用自动更新功能。

## ✅ 前置条件

- [x] GitHub 仓库已创建（你的仓库：`homebrew-woodpecker`）
- [x] 已将这些 workflow 文件提交到仓库

## 📦 文件清单

确保以下文件已添加到仓库：

```
.github/
├── workflows/
│   ├── auto-update.yml      # 自动更新工作流
│   └── test-formula.yml     # 测试构建工作流
├── AUTOMATION.md            # 详细文档
└── QUICKSTART.md            # 本文件
```

## 🎯 启用步骤

### 步骤 1: 提交文件到 GitHub

```bash
cd /Users/lingyuzeng/project/homebrew-woodpecker

# 查看新增文件
git status

# 添加所有新文件
git add .github/

# 提交
git commit -m "feat: 添加 GitHub Actions 自动更新功能

- 每天自动检查上游 woodpecker 新版本
- 自动创建 PR 更新 Formula
- 自动测试构建（M1 和 Intel Mac）
"

# 推送到 GitHub
git push origin main
```

### 步骤 2: 启用 GitHub Actions

1. 访问你的 GitHub 仓库页面
2. 点击顶部的 **Actions** 标签
3. 如果看到提示 "Workflows aren't being run on this repository"，点击 **"I understand my workflows, go ahead and enable them"**

### 步骤 3: 验证配置

#### 方法 1: 手动触发测试（推荐）

1. 进入 Actions 页面
2. 左侧选择 **"Auto Update Woodpecker Formulae"**
3. 点击右上角 **"Run workflow"** 按钮
4. 选择 `main` 分支
5. （可选）勾选 "强制更新" 以测试完整流程
6. 点击绿色的 **"Run workflow"** 按钮
7. 等待几分钟，查看运行结果

#### 方法 2: 等待定时任务

- 第一次自动运行时间：明天北京时间 10:00（UTC 02:00）
- 无需任何操作，自动运行

### 步骤 4: 查看运行结果

**成功案例**：
- ✅ 如果发现新版本，会自动创建 PR
- ✅ PR 标题类似：`🤖 自动更新：Woodpecker v3.11.0`
- ✅ PR 中会自动运行构建测试

**无需更新**：
- ℹ️ 如果已是最新版本，workflow 会显示 "无需更新"
- ℹ️ 不会创建 PR

## 🔍 验证清单

运行第一次后，检查以下内容：

- [ ] Actions 页面显示工作流运行记录
- [ ] 如果有新版本，看到自动创建的 PR
- [ ] PR 中的测试构建正常运行
- [ ] PR 内容包含版本变更信息

## 📋 日常使用

### 审核和合并 PR

当收到自动创建的 PR 时：

1. **查看 PR 内容**
   - 检查版本号是否正确
   - 查看上游的 Release Notes

2. **（可选）本地测试**
   ```bash
   # 获取 PR 分支
   git fetch origin
   git checkout auto-update-3.11.0
   
   # 测试构建
   brew install --build-from-source ./Formula/woodpecker-agent.rb
   woodpecker-agent --version
   
   # 清理
   brew uninstall woodpecker-agent
   git checkout main
   ```

3. **合并 PR**
   - 如果测试通过，点击 "Merge pull request"
   - PR 分支会自动删除

4. **用户更新**
   - 用户执行 `brew update && brew upgrade woodpecker-agent` 即可获得新版本

### 调整检查频率

如果想调整自动检查的时间，编辑 `.github/workflows/auto-update.yml`：

```yaml
schedule:
  # 默认：每天 UTC 02:00（北京时间 10:00）
  - cron: '0 2 * * *'
  
  # 改为每 6 小时检查一次：
  # - cron: '0 */6 * * *'
  
  # 改为每周一检查：
  # - cron: '0 2 * * 1'
```

修改后提交：
```bash
git add .github/workflows/auto-update.yml
git commit -m "chore: 调整自动更新频率"
git push
```

## 🛠️ 故障排查

### 问题 1: Actions 没有运行

**可能原因**：
- GitHub Actions 未启用
- workflow 文件有语法错误

**解决方法**：
1. 检查 Actions 页面是否启用
2. 查看 workflow 文件语法（YAML 格式）
3. 查看 Actions 日志中的错误信息

### 问题 2: PR 创建失败

**错误信息**: `refusing to allow a GitHub App to create or update workflow`

**解决方法**：
这是 GitHub 的安全限制，workflow 文件需要手动审核。确认 PR 内容正确后，手动合并即可。

**错误信息**: `Resource not accessible by integration`

**解决方法**：
检查仓库设置：
1. Settings → Actions → General
2. Workflow permissions 选择 "Read and write permissions"
3. 勾选 "Allow GitHub Actions to create and approve pull requests"

### 问题 3: 构建测试失败

**可能原因**：
- 上游代码编译错误
- macOS runner 不可用

**解决方法**：
1. 查看具体的错误日志
2. 本地测试构建：`brew install --build-from-source ./Formula/woodpecker-agent.rb`
3. 如果是上游问题，可以等待上游修复或暂时跳过这个版本

## 📊 监控建议

### 设置通知

为了及时了解更新情况，建议：

1. **Watch 仓库**
   - 在 GitHub 仓库页面点击 "Watch"
   - 选择 "All Activity" 或 "Custom" → 勾选 "Pull requests"

2. **邮件通知**
   - PR 创建时会收到邮件通知
   - Actions 失败时也会收到通知

3. **移动端通知**
   - 安装 GitHub 手机 App
   - 启用推送通知

## 🎉 完成！

现在你的 Homebrew tap 已经具备自动更新能力：

- ✅ 无需手动检查上游版本
- ✅ 自动创建更新 PR
- ✅ 自动测试确保质量
- ✅ 用户始终能获得最新版本

## 📚 下一步

- 阅读 [详细文档](AUTOMATION.md) 了解更多配置选项
- 查看 [Woodpecker CI 文档](https://woodpecker-ci.org/docs/intro) 了解新功能
- 加入 [Woodpecker Discord](https://discord.gg/woodpecker-ci) 社区

---

💡 **提示**: 如有问题，可以查看 Actions 页面的运行日志，或提 Issue 寻求帮助。

