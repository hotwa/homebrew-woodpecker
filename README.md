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

**方案 B：编辑兜底文件 agent.env（推荐用于持久化配置）**

配置文件位置：`/opt/homebrew/etc/woodpecker/agent.env`

```bash
# 编辑配置文件
vi "$(brew --prefix)/etc/woodpecker/agent.env"
```

**完整配置示例**：

```bash
# Fallback envs for woodpecker-agent (exec).
# 启动脚本会先读 launchctl getenv，再读本文件中未定义的变量。

# === 必需配置 ===
WOODPECKER_AGENT_NAME=Mac-mini                    # Agent 名称（建议使用主机名）
WOODPECKER_SERVER=ci-agent.jmsu.top:443          # Woodpecker Server 地址
WOODPECKER_AGENT_SECRET=YOUR_SECRET_HERE         # Agent 密钥（从 Server 获取）

# === 连接配置 ===
WOODPECKER_GRPC_SECURE=true                       # 使用 TLS 加密连接
WOODPECKER_GRPC_VERIFY=true                       # 验证服务器证书

# === 执行配置 ===
WOODPECKER_BACKEND=local                          # 使用本地（exec）后端
WOODPECKER_MAX_WORKFLOWS=1                        # 最大并发流水线数

# === Agent 标签 ===
# 用于流水线选择此 Agent
WOODPECKER_AGENT_LABELS=platform=darwin/arm64,gpu=metal,host=Mac-mini.local

# === 健康检查 ===
WOODPECKER_HEALTHCHECK_ADDR=:3001                 # 健康检查端口（避免 3000 冲突）

# === 可选：PATH 配置 ===
# 一般不需要手动设置，启动脚本已预置
#PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
```

**配置说明**：

| 配置项 | 说明 | 必需 | 示例值 |
|--------|------|------|--------|
| `WOODPECKER_AGENT_NAME` | Agent 标识名称 | ✅ | `Mac-mini` 或 `macos-m4-01` |
| `WOODPECKER_SERVER` | Server 地址 | ✅ | `ci.example.com:443` 或 `192.168.1.100:9000` |
| `WOODPECKER_AGENT_SECRET` | Agent 密钥 | ✅ | 从 Woodpecker Server 管理界面获取 |
| `WOODPECKER_GRPC_SECURE` | 是否使用 TLS | 推荐 | `true`（HTTPS）或 `false`（HTTP） |
| `WOODPECKER_GRPC_VERIFY` | 是否验证证书 | 推荐 | `true`（验证）或 `false`（自签证书） |
| `WOODPECKER_BACKEND` | 执行后端类型 | ✅ | `local`（exec 模式） |
| `WOODPECKER_MAX_WORKFLOWS` | 并发数 | 可选 | `1`（单任务）或 `2`（双任务） |
| `WOODPECKER_AGENT_LABELS` | Agent 标签 | 可选 | `platform=darwin/arm64,gpu=metal` |
| `WOODPECKER_HEALTHCHECK_ADDR` | 健康检查地址 | 可选 | `:3001`（避免 3000 端口冲突） |

**注意事项**：
- 如果值包含空格，使用双引号包裹：`WOODPECKER_AGENT_NAME="Mac mini"`
- 启动脚本会**先读 launchctl 环境变量，再读此文件**
- 已存在的 launchctl 变量**不会被此文件覆盖**
- 修改后需要重启服务生效

**修改后重启服务**：

```bash
brew services restart hotwa/woodpecker/woodpecker-agent
# 或简写（如果只安装了 woodpecker-agent）
brew services restart woodpecker-agent

# 查看日志确认启动成功
tail -f /opt/homebrew/var/log/woodpecker/agent.log
tail -f /opt/homebrew/var/log/woodpecker/agent.err.log
```

## 3) 启动/日志/管理

### 服务管理命令

```bash
# 启动服务（用户登录后自动启动）
brew services start woodpecker-agent
# 或使用完整名称
brew services start hotwa/woodpecker/woodpecker-agent

# 重启服务（修改配置后需要重启）
brew services restart woodpecker-agent

# 停止服务
brew services stop woodpecker-agent

# 查看服务状态
brew services list
brew services info woodpecker-agent
```

### 开机自启动配置

**Homebrew Services 自动管理 LaunchAgent**：

安装后，Homebrew 会自动创建 LaunchAgent plist 文件：
- 位置：`~/Library/LaunchAgents/homebrew.mxcl.woodpecker-agent.plist`
- 类型：用户级 LaunchAgent（登录后启动）
- 管理：通过 `brew services` 命令

**启用开机自启动**：

```bash
# 启动服务并设置为开机自动启动
brew services start hotwa/woodpecker/woodpecker-agent

# 验证服务状态
brew services list | grep woodpecker
# 应该显示: woodpecker-agent started <用户名> ~/Library/LaunchAgents/homebrew.mxcl.woodpecker-agent.plist

# 确认服务正在运行
ps aux | grep woodpecker-agent
```

**服务特性**：
- ✅ **用户登录后自动启动** - 无需 root 权限
- ✅ **崩溃自动重启** - LaunchAgent 会自动重启崩溃的服务
- ✅ **日志自动管理** - 日志文件自动轮转
- ✅ **环境变量隔离** - 每个用户有独立的环境配置

**禁用开机自启动**：

```bash
# 停止服务并禁用自启动
brew services stop woodpecker-agent

# 服务将不再随用户登录启动
```

### 日志管理

```bash
# 查看标准输出日志
tail -f /opt/homebrew/var/log/woodpecker/agent.log

# 查看错误日志
tail -f /opt/homebrew/var/log/woodpecker/agent.err.log

# 查看最近 100 行日志
tail -n 100 /opt/homebrew/var/log/woodpecker/agent.log

# 实时监控错误（推荐）
tail -f /opt/homebrew/var/log/woodpecker/agent.err.log
```

### 故障排查

```bash
# 1. 检查服务状态
brew services list | grep woodpecker

# 2. 查看进程
ps aux | grep woodpecker-agent

# 3. 检查日志错误
cat /opt/homebrew/var/log/woodpecker/agent.err.log | tail -50

# 4. 测试配置
cat /opt/homebrew/etc/woodpecker/agent.env

# 5. 手动启动测试（调试用）
/opt/homebrew/share/woodpecker-agent/launch.sh

# 6. 检查网络连接
nc -zv ci-agent.jmsu.top 443
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

brew upgrade woodpecker-agent
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
