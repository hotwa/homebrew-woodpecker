class WoodpeckerAgent < Formula
  desc "Woodpecker CI agent (exec runner) for macOS with brew services"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  # 使用 git 源码构建，免 sha256；如需锁定版本，可换 tag
  url "https://github.com/woodpecker-ci/woodpecker.git",
      tag:      "v3.10.0",
      shallow:  false
  head "https://github.com/woodpecker-ci/woodpecker.git", branch: "main"

  depends_on "go" => :build

  def install
    # Build agent
    cd "cmd/agent" do
      system "go", "build", "-trimpath", "-o", bin/"woodpecker-agent"
    end

    # paths
    (etc/"woodpecker").mkpath
    (var/"log/woodpecker").mkpath
    (pkgshare).mkpath

    # default fallback env file (create if not exists)
    env_file = etc/"woodpecker/agent.env"
    unless env_file.exist?
      cpu = Hardware::CPU.arm? ? "arm64" : "amd64"
      env_file.write <<~EOS
        # Fallback envs for woodpecker-agent (exec).
        # 启动脚本会先读 launchctl getenv，再读本文件中未定义的变量。
        WOODPECKER_AGENT_NAME=#{`scutil --get ComputerName`.strip rescue "mac-agent"}
        WOODPECKER_SERVER=ci-agent.jmsu.top:443
        WOODPECKER_GRPC_SECURE=true
        WOODPECKER_GRPC_VERIFY=true
        WOODPECKER_AGENT_SECRET=CHANGE_ME
        WOODPECKER_MAX_WORKFLOWS=1
        WOODPECKER_HEALTHCHECK_ADDR=:3001
        WOODPECKER_AGENT_LABELS=platform=darwin/#{cpu},gpu=metal,host=#{`hostname`.strip}
      EOS
    end

    # wrapper: read launchctl getenv first, then fallback to etc env file
    (pkgshare/"launch.sh").write <<~SH
      #!/bin/sh
      set -e
      # 先从 launchd 环境拿变量（若有就导出）
      for k in WOODPECKER_AGENT_NAME WOODPECKER_SERVER WOODPECKER_AGENT_SECRET \\
               WOODPECKER_GRPC_SECURE WOODPECKER_GRPC_VERIFY \\
               WOODPECKER_MAX_WORKFLOWS WOODPECKER_AGENT_LABELS WOODPECKER_HEALTHCHECK_ADDR
      do
        v="$(launchctl getenv "$k" || true)"
        if [ -n "$v" ]; then export "$k=$v"; fi
      done
      # 再从 etc 兜底（不会覆盖已存在的变量）
      if [ -f "#{etc}/woodpecker/agent.env" ]; then
        set -a
        . "#{etc}/woodpecker/agent.env"
        set +a
      fi
      exec "#{opt_bin}/woodpecker-agent"
    SH
    chmod 0755, (pkgshare/"launch.sh")
  end

  def post_install
    env_file = etc/"woodpecker/agent.env"
    system "chmod", "600", env_file if env_file.exist?
  end

  service do
    # LaunchAgent（用户登录即起）
    run [opt_pkgshare/"launch.sh"]
    keep_alive true
    log_path var/"log/woodpecker/agent.log"
    error_log_path var/"log/woodpecker/agent.err.log"
    # 默认运行在用户会话，无需指定 working_dir
  end

  test do
    # 简单自检：打印帮助
    system "#{bin}/woodpecker-agent", "--help"
  end
end
