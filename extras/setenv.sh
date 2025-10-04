#!/bin/sh
# 将 ENV_FILE 中的键值注入到 launchd 用户环境（登录后自动生效）
# 配套 plist: com.example.woodpecker.setenv.plist

set -e

# 修改成你的路径
ENV_FILE="${HOME}/.config/woodpecker/agent.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[setenv] ENV_FILE not found: $ENV_FILE" >&2
  exit 0
fi

# 只处理非注释行的 KEY=VAL
# shellcheck disable=SC2162
while IFS= read -r line; do
  case "$line" in
    ''|\#*) continue ;;
    *)
      key="$(printf "%s" "$line" | cut -d= -f1)"
      val="$(printf "%s" "$line" | cut -d= -f2-)"
      # 去掉首尾引号（若有）
      val="${val#\"}"; val="${val%\"}"
      val="${val#\'}"; val="${val%\'}"
      launchctl setenv "$key" "$val"
      ;;
  esac
done < "$ENV_FILE"

echo "[setenv] launchctl env updated from $ENV_FILE"
