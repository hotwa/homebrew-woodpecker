# 自动化功能更新日志

## 2025-11-02 - 添加 GitHub Actions 自动更新功能

### 🎉 新增功能

#### 1. 自动版本检测与更新
- **每日自动检查**: 每天北京时间 10:00（UTC 02:00）自动检查上游 Woodpecker CI 是否有新版本
- **智能对比**: 自动对比本地版本和上游最新 release
- **自动更新 Formula**: 检测到新版本时自动更新所有相关 Formula 文件
  - `woodpecker-agent.rb`: 更新到最新 release tag
  - `woodpecker-cli.rb`: 更新到 main 分支最新 commit
  - 自动递增 revision 号

#### 2. 自动化 PR 创建
- **自动创建 Pull Request**: 发现新版本时自动创建格式化的 PR
- **详细变更说明**: PR 中包含完整的版本变更信息
- **上游链接**: 直接链接到上游的 Release Notes
- **测试建议**: 提供本地测试命令供审核使用

#### 3. 自动构建测试
- **多平台测试**: 在 Apple Silicon (M1/M2) 和 Intel Mac 上自动测试构建
- **全面验证**: 测试所有 Formula 文件（agent、cli、plugins）
- **自动运行**: PR 创建时自动触发，确保更新不会破坏构建

#### 4. 手动触发支持
- **灵活控制**: 可随时手动触发版本检查
- **强制更新选项**: 支持强制更新（即使版本相同）
- **即时响应**: 不需要等待定时任务

### 📁 新增文件

```
.github/
├── workflows/
│   ├── auto-update.yml           # 主自动更新工作流
│   └── test-formula.yml          # 自动构建测试工作流
├── AUTOMATION.md                 # 详细文档（4000+ 字）
├── QUICKSTART.md                 # 快速开始指南
└── check-setup.sh                # 配置验证脚本
```

### 📝 文件更新

- `README.md`: 添加自动化功能说明章节

### 🔧 技术实现

#### 版本检测机制
```yaml
# 使用 GitHub API 获取最新 release
curl -s https://api.github.com/repos/woodpecker-ci/woodpecker/releases/latest

# 使用 git ls-remote 获取最新 commit
git ls-remote https://github.com/woodpecker-ci/woodpecker.git refs/heads/main
```

#### Formula 更新逻辑
- 使用 `sed` 命令精确替换版本号和 commit hash
- 自动计算并递增 revision 号
- 保持文件格式和注释不变

#### 构建测试策略
- 使用 GitHub Actions 的 macOS runners
- 测试完整的依赖链（agent → cli → plugins）
- 验证二进制文件可执行性和版本输出

### 📊 预期效果

#### 维护成本降低
- ❌ 之前: 手动检查上游版本 → 手动修改 Formula → 手动测试 → 手动提交
- ✅ 现在: 自动检查 → 自动更新 → 自动测试 → 只需审核和合并 PR

#### 版本更新及时性
- 上游发布新版本后，最晚 24 小时内自动创建更新 PR
- 支持手动触发，可在 5 分钟内完成版本检测和 PR 创建

#### 用户体验改善
- 用户始终能通过 `brew upgrade` 获得最新版本
- 减少版本滞后问题
- 提高 tap 的活跃度和可信度

### 🎯 使用场景

#### 场景 1: 日常维护（全自动）
```
上游发布 v3.11.0
    ↓ 自动（最晚 24h）
GitHub Actions 创建 PR
    ↓ 人工审核
查看 PR，确认变更
    ↓ 点击合并
合并 PR
    ↓ 用户更新
brew update && brew upgrade
```

#### 场景 2: 紧急更新（手动触发）
```
发现重要安全更新
    ↓ 立即操作
手动触发 workflow
    ↓ 5 分钟内
自动创建 PR
    ↓ 快速审核
合并并通知用户
```

#### 场景 3: 版本测试（本地验证）
```
收到自动 PR
    ↓ 本地测试
git checkout auto-update-3.11.0
brew install --build-from-source ./Formula/woodpecker-agent.rb
    ↓ 验证通过
合并 PR
```

### 🔐 安全性考虑

1. **人工审核机制**: 所有更新都通过 PR，需要人工审核
2. **自动测试验证**: 合并前自动运行构建测试
3. **权限最小化**: GitHub Actions 只有必要的读写权限
4. **透明可追溯**: 所有更新都有完整的 git 历史记录

### 📈 监控与通知

- GitHub Actions 运行结果邮件通知
- PR 创建时自动通知仓库 watchers
- Actions 页面可查看完整的运行日志
- 失败时自动发送通知邮件

### 🚀 后续计划

可选的增强功能（未实现）：
- [ ] 添加 Slack/Discord 通知集成
- [ ] 自动合并小版本更新（patch 版本）
- [ ] 生成详细的变更日志
- [ ] 添加性能测试基准
- [ ] 集成 Homebrew 官方 tap 审计工具

### 📚 相关资源

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Homebrew Formula 文档](https://docs.brew.sh/Formula-Cookbook)
- [Woodpecker CI Release 页面](https://github.com/woodpecker-ci/woodpecker/releases)
- [peter-evans/create-pull-request Action](https://github.com/peter-evans/create-pull-request)

### 💡 最佳实践

1. **定期查看 PR**: 建议每周至少查看一次自动创建的 PR
2. **关注重大更新**: 对于大版本更新（如 3.x → 4.x），建议本地测试后再合并
3. **保持文档同步**: 如果上游有重大变更，及时更新 README 和文档
4. **监控 Actions 状态**: 定期检查 Actions 是否正常运行

### 🎓 学习价值

这套自动化方案展示了：
- GitHub Actions workflow 的实践应用
- 多平台 CI/CD 测试策略
- 开源项目的自动化维护模式
- Homebrew Formula 的持续集成

### 🙏 致谢

本自动化方案参考了：
- Homebrew 官方 tap 的最佳实践
- GitHub Actions 社区的优秀案例
- Woodpecker CI 的开发模式

---

**版本**: 1.0.0  
**日期**: 2025-11-02  
**作者**: AI Assistant (Claude)  
**状态**: ✅ 生产就绪

