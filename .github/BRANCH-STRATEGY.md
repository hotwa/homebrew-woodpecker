# 🌳 分支策略说明

本仓库采用**双分支自动化策略**，平衡自动化与稳定性。

## 📊 分支架构

```
上游 woodpecker-ci/woodpecker
         ↓
    [auto-sync 分支]  ← 每天自动同步
         ↓
    [Pull Request]    ← 人工审核
         ↓
    [main 分支]       ← 稳定版本
         ↓
    用户 brew install
```

## 🎯 分支说明

### 1️⃣ `main` 分支（稳定版）

**用途**：生产环境稳定版本

**特点**：
- ✅ 经过人工审核的版本
- ✅ 确保构建测试通过
- ✅ 适合生产环境使用
- ✅ 用户默认使用此分支

**更新方式**：
- 从 `auto-sync` 分支合并 PR（人工审核）
- 也可以手动编辑提交

**用户使用**：
```bash
# 默认使用 main 分支
brew tap hotwa/woodpecker
brew install woodpecker-agent
```

### 2️⃣ `auto-sync` 分支（最新版）

**用途**：自动跟随上游最新版本

**特点**：
- 🔄 每天自动检查上游版本
- 🔄 检测到新版本立即更新
- 🔄 自动提交，无需人工干预
- ⚠️ 可能包含未充分测试的版本

**更新方式**：
- GitHub Actions 自动更新（每天 UTC 02:00）
- 检测到新版本立即提交
- 自动创建 PR 到 main

**用户使用**：
```bash
# 明确指定使用 auto-sync 分支（最新版）
git clone -b auto-sync https://github.com/hotwa/homebrew-woodpecker.git /tmp/tap
brew install /tmp/tap/Formula/woodpecker-agent.rb

# 或者在 tap 后手动切换分支
brew tap hotwa/woodpecker
cd $(brew --repo hotwa/woodpecker)
git checkout auto-sync
brew reinstall woodpecker-agent
```

## 🔄 工作流程

### 自动更新流程

```
1. 定时任务触发（每天 10:00 北京时间）
   └─> GitHub Actions 运行

2. 检查上游版本
   └─> 对比 auto-sync 分支当前版本

3. 如果有新版本
   ├─> 更新 Formula 文件
   ├─> 自动提交到 auto-sync 分支
   ├─> 运行构建测试
   └─> 创建 PR: auto-sync → main

4. 人工审核 PR
   ├─> 查看变更内容
   ├─> （可选）本地测试 auto-sync 分支
   └─> 合并到 main 或关闭 PR

5. 用户获得更新
   └─> brew update && brew upgrade
```

### 手动触发流程

```bash
# 方式 1: GitHub 网页触发
GitHub Actions → Auto Update Woodpecker Formulae → Run workflow

# 方式 2: 本地推送到 auto-sync
git checkout auto-sync
# 修改 Formula 文件
git commit -am "手动更新"
git push origin auto-sync
# 会自动触发 workflow
```

## 📋 使用场景

### 场景 1: 普通用户（推荐使用 main）

```bash
# 安装稳定版
brew tap hotwa/woodpecker
brew install woodpecker-agent

# 定期更新
brew update
brew upgrade woodpecker-agent
```

**优点**：稳定、经过测试、安全

### 场景 2: 尝鲜用户（使用 auto-sync）

```bash
# 方法 1: 直接从 auto-sync 分支安装
cd /tmp
git clone -b auto-sync https://github.com/hotwa/homebrew-woodpecker.git
brew install ./homebrew-woodpecker/Formula/woodpecker-agent.rb

# 方法 2: 切换已有 tap 到 auto-sync
cd $(brew --repo hotwa/woodpecker)
git fetch origin
git checkout auto-sync
brew reinstall woodpecker-agent
```

**优点**：第一时间获得最新功能  
**缺点**：可能遇到未发现的问题

### 场景 3: 开发者/贡献者

```bash
# Fork 仓库后
git clone https://github.com/YOUR_USERNAME/homebrew-woodpecker.git
cd homebrew-woodpecker

# 查看两个分支的差异
git diff main..auto-sync

# 测试 auto-sync 分支
git checkout auto-sync
brew install --build-from-source ./Formula/woodpecker-agent.rb

# 发现问题，修复后提交 PR
git checkout -b fix-something
# 修改文件
git commit -am "fix: 修复某个问题"
git push origin fix-something
# 在 GitHub 创建 PR
```

## 🛠️ 维护指南

### 仓库维护者操作

#### 1. 审核自动更新 PR

```bash
# 收到 PR 通知后

# 1. 查看 PR 内容
# - 检查版本号是否正确
# - 查看上游 Release Notes
# - 检查 CI 测试结果

# 2. 本地测试（可选）
git fetch origin
git checkout auto-sync
brew reinstall --build-from-source woodpecker-agent
woodpecker-agent --version

# 3. 确认无误后合并 PR
# 在 GitHub 网页点击 "Merge pull request"
```

#### 2. 手动更新 main 分支

```bash
# 如果需要跳过某个版本，或者手动调整

git checkout main
# 编辑 Formula 文件
vi Formula/woodpecker-agent.rb

git commit -am "chore: 手动更新到 vX.Y.Z"
git push origin main
```

#### 3. 手动同步 auto-sync 到 main

```bash
# 如果 auto-sync 已经测试稳定，直接合并

git checkout main
git merge auto-sync
git push origin main
```

#### 4. 重置 auto-sync 分支

```bash
# 如果 auto-sync 出现问题，可以重置为 main

git checkout auto-sync
git reset --hard main
git push --force origin auto-sync
```

### 故障恢复

#### 问题 1: auto-sync 分支损坏

```bash
# 从 main 分支重新创建
git checkout main
git branch -D auto-sync
git checkout -b auto-sync
git push --force origin auto-sync
```

#### 问题 2: 自动更新创建了错误的提交

```bash
# 在 auto-sync 分支回滚
git checkout auto-sync
git reset --hard HEAD~1  # 回滚 1 个提交
git push --force origin auto-sync

# 关闭错误的 PR
# 在 GitHub 网页关闭 PR
```

#### 问题 3: PR 冲突

```bash
# 如果 main 和 auto-sync 产生冲突

git checkout auto-sync
git merge main  # 合并 main 到 auto-sync
# 解决冲突
git add .
git commit -m "chore: 解决合并冲突"
git push origin auto-sync

# PR 会自动更新
```

## 📊 分支对比

| 特性 | main 分支 | auto-sync 分支 |
|------|----------|----------------|
| **更新方式** | 人工审核 | 自动同步 |
| **更新频率** | 不定期 | 每天检查 |
| **稳定性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **新鲜度** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **测试保证** | 充分测试 | 自动测试 |
| **推荐用户** | 生产环境 | 尝鲜用户 |
| **版本延迟** | 1-7 天 | 0-24 小时 |
| **风险等级** | 低 | 中 |

## 🎯 最佳实践

### 对于仓库维护者

1. **定期审核 PR**
   - 每周至少查看一次自动创建的 PR
   - 对于小版本更新（patch），可以快速合并
   - 对于大版本更新（major/minor），建议本地测试

2. **保持分支同步**
   - auto-sync 应该始终领先或等于 main
   - 定期合并 main 到 auto-sync（如果手动修改了 main）

3. **监控自动化**
   - 关注 Actions 运行状态
   - 出现失败立即处理
   - 保持 workflow 文件更新

4. **文档维护**
   - 更新 README 反映最新版本
   - 记录重要的版本变更
   - 维护 CHANGELOG

### 对于普通用户

1. **使用 main 分支**（默认）
   ```bash
   brew tap hotwa/woodpecker
   brew install woodpecker-agent
   ```

2. **定期更新**
   ```bash
   brew update
   brew upgrade woodpecker-agent
   ```

3. **如需最新功能**
   - 切换到 auto-sync 分支
   - 自行承担风险
   - 遇到问题及时反馈

### 对于贡献者

1. **基于正确的分支开发**
   - 功能改进：基于 main 分支
   - 版本更新：基于 auto-sync 分支（或等自动更新）

2. **测试充分**
   - 在本地完整测试
   - 提供测试命令和结果
   - 说明测试环境

3. **PR 描述清晰**
   - 说明修改原因
   - 列出测试步骤
   - 关联相关 Issue

## 🔍 监控与维护

### 检查分支状态

```bash
# 查看两个分支的差异
git fetch origin
git log main..origin/auto-sync --oneline

# 查看当前版本
git checkout main
grep "tag:" Formula/woodpecker-agent.rb

git checkout auto-sync
grep "tag:" Formula/woodpecker-agent.rb
```

### 查看自动化日志

```bash
# 在 GitHub 网页
Actions → Auto Update Woodpecker Formulae → 最近的运行

# 或使用 gh CLI
gh run list --workflow=auto-update.yml
gh run view <run-id> --log
```

## 📚 相关文档

- [自动化详细文档](AUTOMATION.md)
- [快速开始指南](QUICKSTART.md)
- [主 README](../README.md)

## ❓ 常见问题

**Q: 为什么需要两个分支？**  
A: main 保证稳定性，auto-sync 保证新鲜度，满足不同用户需求。

**Q: 我应该用哪个分支？**  
A: 普通用户用 main（默认），想尝鲜用 auto-sync。

**Q: auto-sync 多久更新一次？**  
A: 每天检查一次，发现新版本立即更新。

**Q: main 分支会不会过时？**  
A: 不会，每次 auto-sync 更新都会创建 PR，审核后合并到 main。

**Q: 可以只用一个分支吗？**  
A: 可以，但要么牺牲自动化，要么牺牲稳定性。双分支是最佳平衡。

**Q: 如果两个分支差距太大怎么办？**  
A: 批量审核多个版本的变更，或者直接合并（如果都经过测试）。

---

**更新日期**: 2025-11-02  
**维护者**: hotwa  
**状态**: ✅ 生产就绪

