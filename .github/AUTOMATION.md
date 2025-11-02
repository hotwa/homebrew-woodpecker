# 🤖 自动化更新说明

本仓库配置了 GitHub Actions 自动化工作流，用于自动检测和更新上游 Woodpecker CI 的版本。

## 📋 工作流说明

### 1. Auto Update Workflow（自动更新）

**文件**: `.github/workflows/auto-update.yml`

**功能**:
- ✅ 每天自动检查上游 woodpecker-ci/woodpecker 是否有新版本
- ✅ 检测到新版本时自动更新 Formula 文件
- ✅ 自动创建 Pull Request 供审核
- ✅ 支持手动触发更新

**触发方式**:
1. **定时触发**: 每天 UTC 02:00（北京时间 10:00）自动运行
2. **手动触发**: 
   ```bash
   # 在 GitHub 仓库页面
   Actions → Auto Update Woodpecker Formulae → Run workflow
   ```

**更新内容**:
- `woodpecker-agent.rb`: 更新到最新 release tag
- `woodpecker-cli.rb`: 更新到 main 分支最新 commit
- 自动递增 revision 号

**PR 内容包括**:
- 📦 版本变更说明
- 🔗 上游 Release 链接
- ✅ Ruby 语法检查结果
- 📝 本地测试命令建议

### 2. Test Formula Workflow（测试构建）

**文件**: `.github/workflows/test-formula.yml`

**功能**:
- ✅ 在 Apple Silicon (M1/M2) 和 Intel Mac 上测试构建
- ✅ 验证所有 Formula 可以正常编译安装
- ✅ 自动在 PR 中运行，确保更新不会破坏构建

**触发时机**:
- PR 修改了 `Formula/` 目录下的文件
- 推送到 main 分支时
- 手动触发

## 🚀 使用指南

### 场景 1: 自动更新（推荐）

**无需任何操作！** 工作流会：
1. 每天自动检查新版本
2. 发现新版本时自动创建 PR
3. 你只需要：
   - 查看 PR 内容
   - （可选）本地测试
   - 点击 Merge

### 场景 2: 手动触发更新

当你想立即检查更新时：

1. 进入仓库的 Actions 页面
2. 选择 "Auto Update Woodpecker Formulae"
3. 点击 "Run workflow"
4. （可选）勾选 "强制更新"

### 场景 3: 本地测试 PR 中的更新

```bash
# 1. 切换到 PR 分支
git fetch origin
git checkout auto-update-3.11.0  # 分支名在 PR 中显示

# 2. 测试构建
brew uninstall woodpecker-agent  # 如果已安装
brew install --build-from-source ./Formula/woodpecker-agent.rb

# 3. 验证版本
woodpecker-agent --version

# 4. 测试运行（可选）
brew services start woodpecker-agent
brew services stop woodpecker-agent
```

## ⚙️ 配置说明

### 定时任务修改

如果想调整检查频率，编辑 `.github/workflows/auto-update.yml`:

```yaml
schedule:
  # 每天 UTC 02:00 检查
  - cron: '0 2 * * *'
```

常用 cron 表达式:
- `0 */6 * * *` - 每 6 小时检查一次
- `0 0 * * 1` - 每周一检查
- `0 2 * * *` - 每天 02:00 检查（当前设置）

### 关闭自动更新

如果想暂时关闭自动更新：

**方法 1**: 禁用 workflow
```bash
# 在 GitHub 仓库页面
Actions → Auto Update Woodpecker Formulae → ⋯ → Disable workflow
```

**方法 2**: 注释 schedule
编辑 `.github/workflows/auto-update.yml`:
```yaml
on:
  # schedule:
  #   - cron: '0 2 * * *'
  workflow_dispatch:  # 保留手动触发
```

## 📊 工作流程图

```
上游发布新版本
     ↓
GitHub Actions 定时检查（每天 10:00）
     ↓
发现新版本？
     ↓ 是
更新 Formula 文件
     ↓
运行语法检查
     ↓
创建 Pull Request
     ↓
运行测试构建（在 M1 和 Intel Mac 上）
     ↓
等待人工审核
     ↓
合并 PR
     ↓
用户执行 brew update + brew upgrade
```

## 🔧 故障排查

### PR 创建失败

**可能原因**:
- GitHub Token 权限不足
- 已存在同名分支

**解决方法**:
```bash
# 删除旧的更新分支
git push origin --delete auto-update-3.10.0
```

### 构建测试失败

**可能原因**:
- 上游代码编译错误
- 依赖项变更

**解决方法**:
1. 查看 Actions 日志中的详细错误
2. 在本地重现问题
3. 可能需要调整 Formula 文件（如添加新依赖）

### 版本检测错误

**检查当前检测到的版本**:
```bash
# 手动运行版本检测脚本
curl -s https://api.github.com/repos/woodpecker-ci/woodpecker/releases/latest | jq -r '.tag_name'
```

## 📝 维护建议

1. **定期检查 PR**: 即使自动化了，也建议每周查看一次 PR
2. **测试重要更新**: 对于大版本更新（如 3.x → 4.x），建议本地测试后再合并
3. **关注上游变化**: 订阅 [woodpecker-ci/woodpecker releases](https://github.com/woodpecker-ci/woodpecker/releases)
4. **保持工作流更新**: 定期检查 GitHub Actions 是否有新的最佳实践

## 🎯 进阶配置

### 添加版本更新通知

可以集成 Slack/Discord/邮件通知:

```yaml
- name: 发送通知
  if: steps.compare.outputs.needs_update == 'true'
  uses: 8398a7/action-slack@v3
  with:
    status: custom
    text: '发现 Woodpecker 新版本 ${{ steps.upstream.outputs.latest_tag }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 自动合并小版本更新

如果想自动合并 patch 版本更新（如 3.10.0 → 3.10.1）:

```yaml
- name: 自动合并小版本
  if: steps.compare.outputs.needs_update == 'true'
  run: |
    # 判断是否为 patch 更新
    OLD_VERSION="${{ steps.current.outputs.current_version }}"
    NEW_VERSION="${{ steps.upstream.outputs.latest_version }}"
    
    # 提取主版本号和次版本号
    OLD_MAJOR_MINOR=$(echo $OLD_VERSION | cut -d. -f1-2)
    NEW_MAJOR_MINOR=$(echo $NEW_VERSION | cut -d. -f1-2)
    
    if [ "$OLD_MAJOR_MINOR" == "$NEW_MAJOR_MINOR" ]; then
      echo "is_patch=true" >> $GITHUB_OUTPUT
    fi
```

## 📚 相关链接

- [Woodpecker CI 官网](https://woodpecker-ci.org/)
- [Woodpecker GitHub 仓库](https://github.com/woodpecker-ci/woodpecker)
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

💡 **提示**: 如有问题或建议，欢迎提 Issue！

