# Homebrew Tap: woodpecker-agent (exec runner on macOS)

This tap installs `woodpecker-agent` (exec runner) on macOS, runs it as a **LaunchAgent** via `brew services`, and reads config from **launchd environment** first (`launchctl getenv`), then falls back to `agent.env`.

## 1) Tap & Install

```bash
# 替换 <YOUR_GH_USERNAME> 为你的 GitHub 用户名
brew tap hotwa/woodpecker https://github.com/hotwa/homebrew-woodpecker.git
# 看看 tap 里有哪些 formula/cask
brew tap-info hotwa/woodpecker
brew search hotwa/woodpecker
# 或直接列文件：
ls "$(brew --repo hotwa/woodpecker)"/Formula
brew install woodpecker-agent
```

### 可选：安装 Woodpecker CLI 及常用插件

```bash
brew install hotwa/woodpecker/woodpecker-cli
```

> `woodpecker-agent` 会自动安装 `woodpecker-cli`、`plugin-git`、`plugin-s3`、`plugin-docker-buildx` 以及 `git-lfs`，无需手动再装。

安装完成后，可用 `woodpecker-cli --help` 验证 CLI 是否生效。
首次安装后建议执行 `git lfs install`，以确保 Git LFS 钩子就绪。

## 2) 配置环境（两种任选其一，可混用）

**方案 A：使用 launchctl setenv（推荐，登录后即生效）**

```bash
launchctl setenv WOODPECKER_AGENT_NAME   cloud-mac-mini-01
launchctl setenv WOODPECKER_SERVER       ci-agent.jmsu.top:443
launchctl setenv WOODPECKER_AGENT_SECRET <YOUR_SHARED_SECRET>

# 建议项（走你现有 Traefik TLS 终止）
launchctl setenv WOODPECKER_GRPC_SECURE  true
launchctl setenv WOODPECKER_GRPC_VERIFY  true

# 可选并发/标签
launchctl setenv WOODPECKER_MAX_WORKFLOWS 1
launchctl setenv WOODPECKER_AGENT_LABELS  "platform=darwin/arm64,gpu=metal,host=$(hostname)"

# 可选：避免 3000 端口占用
launchctl setenv WOODPECKER_HEALTHCHECK_ADDR :3001
```

`launchctl getenv VAR` 可检查是否写入成功。
这些变量对本次开机周期有效，若需开机后自动注入，见 `extras/setenv.sh` + `extras/com.example.woodpecker.setenv.plist`。

**方案 B：编辑兜底文件 agent.env**

```bash
# 安装后生成的默认位置（首次安装已写好样例）
vi "$(brew --prefix)/etc/woodpecker/agent.env"
# 写入必要变量（示例）
cat >"$(brew --prefix)/etc/woodpecker/agent.env" <<'EOF'
WOODPECKER_AGENT_NAME=macos-m1-01
WOODPECKER_SERVER=ci-agent.jmsu.top:443
WOODPECKER_AGENT_SECRET=***************
WOODPECKER_GRPC_SECURE=true
WOODPECKER_GRPC_VERIFY=true
# 可选：标签与并发
WOODPECKER_MAX_PROCS=1
WOODPECKER_FILTER_LABELS=gpu=false,os=macos,arch=arm64
# 切换后端为 Local（exec）
WOODPECKER_BACKEND=local
EOF
# 或拷贝样例：
# cp extras/agent.env.sample "$(brew --prefix)/etc/woodpecker/agent.env"
```

修改后重启

```bash
brew services restart woodpecker-agent
tail -f /opt/homebrew/var/log/woodpecker/agent.err.log
```

启动脚本会“先读 launchctl，再读这个文件”，已有的变量不会被 env 文件覆盖。
如果某个值包含空格，请确保使用 ASCII 双引号包裹，例如 `WOODPECKER_AGENT_NAME="Mac mini"`。

## 3) 启动/日志/管理

```bash
brew services start  woodpecker-agent   # 登录后自启
brew services restart woodpecker-agent
brew services stop    woodpecker-agent
tail -f  "$(brew --prefix)/var/log/woodpecker/agent.log"
tail -f  "$(brew --prefix)/var/log/woodpecker/agent.err.log"
```

## 4) 在流水线中选中 macOS + Metal

`.woodpecker.yml` 例子（见 `examples/.woodpecker.yml`）：

```yaml
pipeline:
  metal_job:
    labels:
      gpu: metal
      platform: darwin/arm64
    commands:
      - sw_vers
      - system_profiler SPDisplaysDataType | head -50
      - xcodebuild -version || true
```

## 5) 卸载

```bash
brew services stop woodpecker-agent
brew uninstall woodpecker-agent
```

## 6) 可选：开机后自动注入环境变量

编辑 `extras/agent.env.sample`，然后：

```bash
# 放入你的 $HOME 下的固定目录，比如：
mkdir -p ~/.config/woodpecker && cp extras/agent.env.sample ~/.config/woodpecker/agent.env

# 修改 extras/setenv.sh 里的 ENV_FILE 路径为 ~/.config/woodpecker/agent.env
# 再把 plist 安装到 LaunchAgents
cp extras/setenv.sh ~/
chmod +x ~/setenv.sh
cp extras/com.example.woodpecker.setenv.plist ~/Library/LaunchAgents/

# 加载（登录用户域）
launchctl unload ~/Library/LaunchAgents/com.example.woodpecker.setenv.plist 2>/dev/null || true
launchctl load   ~/Library/LaunchAgents/com.example.woodpecker.setenv.plist

# 验证
launchctl getenv WOODPECKER_AGENT_NAME
```

## Notes

- Formula 会从 `github.com/woodpecker-ci/woodpecker` 源码构建 `cmd/agent`（自带 Go 编译）。
- 默认生成的 fallback `WOODPECKER_AGENT_NAME` 会对 macOS 的 ComputerName 做 slug 化（空格等会替换为 `-`），例如 `Mac mini` → `mac-mini`。
- 默认将健康检查端口改为 `:3001`（通过 env），避免常见的 `:3000` 冲突。
- 提供 `woodpecker-cli`、`plugin-git`、`plugin-s3`、`plugin-docker-buildx` 等 Formula，方便在本地 exec 后端装齐常用工具。
- launch.sh 会预置 PATH（含 /opt/homebrew/bin），确保服务能找到 git-lfs、plugin-* 等依赖。
- 该 Tap 仅安装 exec (native) agent。Docker runner 请使用容器方式。

## 🤖 自动化更新 & 分支策略

本仓库采用**双分支自动化策略**，平衡稳定性与新鲜度：

### 🌳 分支说明

| 分支 | 用途 | 更新方式 | 推荐用户 |
|------|------|----------|----------|
| **`main`** | 稳定版本，经过审核 | 人工审核 PR | ✅ 生产环境 |
| **`auto-sync`** | 最新版本，自动跟随上游 | 自动同步 | 🔬 尝鲜用户 |

### ✨ 自动化特性

- ✅ **每天自动检查**上游是否有新 release（北京时间 10:00）
- ✅ **自动更新 `auto-sync` 分支**到最新版本
- ✅ **自动创建 PR** 从 `auto-sync` → `main`
- ✅ **自动测试构建**（在 Apple Silicon 和 Intel Mac 上）
- ✅ **支持手动触发**立即检查更新

### 📦 用户使用

**方式 1: 使用稳定版（推荐）**
```bash
# 默认使用 main 分支
brew tap hotwa/woodpecker
brew install woodpecker-agent

# 定期更新
brew update
brew upgrade woodpecker-agent
```

**方式 2: 使用最新版**
```bash
# 使用 auto-sync 分支
cd $(brew --repo hotwa/woodpecker)
git checkout auto-sync
brew reinstall woodpecker-agent
```

### 🔄 工作流程

```
上游发布新版本
    ↓ 自动（最晚 24h）
auto-sync 分支自动更新
    ↓ 自动创建 PR
等待人工审核
    ↓ 合并 PR
main 分支更新
    ↓ 用户更新
brew upgrade
```

详细说明请查看：
- [分支策略文档](.github/BRANCH-STRATEGY.md)
- [自动化详细文档](.github/AUTOMATION.md)

---

## 使用说明（快速复习）

推到 GitHub：

- 仓库名建议：`homebrew-woodpecker`（Tap 规范）。

本机执行：

```bash
brew tap <YOUR_GH_USERNAME>/woodpecker https://github.com/<YOUR_GH_USERNAME>/homebrew-woodpecker.git
brew install woodpecker-agent
# 写 env（任选其一）
launchctl setenv WOODPECKER_AGENT_SECRET xxxxx
# 或编辑 $(brew --prefix)/etc/woodpecker/agent.env
brew services restart woodpecker-agent
tail -f $(brew --prefix)/var/log/woodpecker/agent.log
```

如果希望重启后自动注入 env：用 `extras/setenv.sh` + plist 那套；否则直接把变量都写在 `agent.env` 也行（wrapper 会读取）。
