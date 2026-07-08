#!/bin/bash
# 原力OS · 把你的第二大脑接进 Codex（一条龙）
# 用法（把这一行粘进终端，回车）：
#   curl -fsSL https://raw.githubusercontent.com/moonstachain/yuanli-os-quickstart/main/codex-setup.sh | bash
#
# 它会：①确认第二大脑已装（没装就自动装）②把大脑接进你的 Codex ③告诉你怎么验证。
# 接好后，你在 Codex 里直接说话就能记/查你的判断——不用敲命令。
set -uo pipefail

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; D=$'\033[2m'; N=$'\033[0m'
step(){ printf '\n%s▸ %s%s\n' "$C$B" "$*" "$N"; }
ok(){ printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
info(){ printf '  %s%s%s\n' "$D" "$*" "$N"; }
oops(){ printf '\n%s✗ 卡了一下：%s%s\n' "$R$B" "$*" "$N"; printf '%s把上面这段发给团队，或让技术伙伴看一眼。%s\n' "$D" "$N"; exit 1; }

printf '%s\n' "${C}${B}  原力OS · 把你的第二大脑接进 Codex${N}"

# 1. 确认有 Codex
step "1/4 确认 Codex"
command -v codex >/dev/null 2>&1 || oops "没找到 Codex 命令。你既然用 Codex，应该已经装了它的命令行版（codex CLI，需 v0.130 以上）。先确认能在终端敲 codex，再回来。"
ok "Codex 就绪（$(codex --version 2>/dev/null | head -1)）"

# 2. 确认第二大脑已装（没装就自动装）
step "2/4 确认第二大脑已装"
YOS="$HOME/AI Project/yuanli-strategy-soul/scripts/yos"
if [ -x "$YOS" ] || command -v yos >/dev/null 2>&1; then
  ok "第二大脑已装"
else
  info "还没装第二大脑，先自动装（约 30-45 分钟，中途去忙别的）……"
  curl -fsSL https://raw.githubusercontent.com/moonstachain/yuanli-os-quickstart/main/install.sh | bash || oops "装机没走完，看上面的提示处理后再跑本脚本。"
  ok "第二大脑装好了"
fi

# 3. 确认大脑服务在线（:3131）
step "3/4 启动大脑服务"
if ! curl -sf http://127.0.0.1:3131/health >/dev/null 2>&1; then
  SERVE_PLIST="$HOME/Library/LaunchAgents/com.yuanli.gbrain-serve.plist"
  [ -f "$SERVE_PLIST" ] && { launchctl load "$SERVE_PLIST" 2>/dev/null || true; }
  i=0; until curl -sf http://127.0.0.1:3131/health >/dev/null 2>&1; do i=$((i+1)); [ $i -ge 10 ] && oops "大脑服务没能启动。先跑 yos status 看看状态，或联系团队。"; sleep 2; done
fi
ok "大脑服务在线（127.0.0.1:3131）"

# 4. 把大脑接进 Codex
step "4/4 接入 Codex"
TOKEN_FILE="$HOME/.gbrain/serve-http-token"
[ -f "$TOKEN_FILE" ] || oops "找不到接入凭证（$TOKEN_FILE）。先跑一次第二大脑的安装（install.sh），它会自动生成。"
TOKEN=$(cat "$TOKEN_FILE")
# 幂等把凭证写进 shell 启动文件（token 只在本机，绝不外传）
PROFILE="$HOME/.zshrc"; [ -f "$PROFILE" ] || PROFILE="$HOME/.bash_profile"; [ -f "$PROFILE" ] || PROFILE="$HOME/.zshrc"
touch "$PROFILE"
sed -i '' '/GBRAIN_REMOTE_TOKEN/d' "$PROFILE" 2>/dev/null || sed -i '/GBRAIN_REMOTE_TOKEN/d' "$PROFILE" 2>/dev/null || true
printf 'export GBRAIN_REMOTE_TOKEN=%s\n' "$TOKEN" >> "$PROFILE"
export GBRAIN_REMOTE_TOKEN="$TOKEN"
ok "接入凭证已就绪（存在你本机 shell 里，不外传）"
# 官方一条龙接入 + 冒烟测；不成则退回 codex mcp add
if gbrain connect http://127.0.0.1:3131/mcp --token "$TOKEN" --agent codex --install >/dev/null 2>&1; then
  ok "已接入 Codex（官方接入 + 连通测试通过）"
else
  codex mcp remove gbrain >/dev/null 2>&1 || true
  codex mcp add gbrain --url http://127.0.0.1:3131/mcp --bearer-token-env-var GBRAIN_REMOTE_TOKEN >/dev/null 2>&1 \
    && ok "已接入 Codex" || oops "接入 Codex 没成。把上面的错误发给团队。"
fi

# 完成
cat <<'DONE'

  ╭──────────────────────────────────────────────╮
  │   🎉 接好了！你的第二大脑已经接进 Codex        │
  ╰──────────────────────────────────────────────╯
DONE
printf '  %s第一件事（很重要）：%s关掉现在这个 Codex 会话，%s重新打开一个新的%s——接入才会生效。\n' "$B" "$N" "$B" "$N"
printf '\n  %s然后在新的 Codex 里，问一句验证：%s\n' "$B" "$N"
printf '    %sCall get_brain_identity, then search my brain for 原力%s\n' "$C" "$N"
printf '\n  %s以后就这么用（直接说话，不用敲命令）：%s\n' "$B" "$N"
printf '    · %s「帮我记一条：刚见的客户资源真、但说话留三分，值得长期处」%s → 它存进你的个人空间\n' "$C" "$N"
printf '    · %s「我以前怎么判断这类要长账期的客户？」%s → 它把你过去的判断查给你\n' "$C" "$N"
printf '  %s完整用法与源路由约定见：%shttps://raw.githubusercontent.com/moonstachain/yuanli-os-quickstart/main/for-codex.md%s\n\n' "$D" "$C" "$N"
