#!/bin/bash
# 原力OS · 第二个大脑 —— 一键傻瓜安装器
# 用法（把这一行粘进"终端"，回车）：
#   curl -fsSL https://raw.githubusercontent.com/moonstachain/yuanli-os-quickstart/main/install.sh | bash
#
# 它会自动帮你装好：命令行工具 / Ollama（本地思考核心）/ 两个 AI 模型 / 引擎 / 你的大脑。
# 全程约 30-45 分钟，大部分时间在下载，你可以去忙别的。你的资料只存在这台电脑，不上云。
set -uo pipefail

# ── 友好输出 ─────────────────────────────────────────────
B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; D=$'\033[2m'; N=$'\033[0m'
step(){ printf '\n%s▸ %s%s\n' "$C$B" "$*" "$N"; }
ok(){ printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
info(){ printf '  %s%s%s\n' "$D" "$*" "$N"; }
warn(){ printf '  %s⚠ %s%s\n' "$Y" "$*" "$N"; }
oops(){ printf '\n%s✗ 遇到一点问题：%s%s\n' "$R$B" "$*" "$N"; printf '%s别急，把上面这段红字截图发给我们团队，或让你的技术伙伴看一眼。%s\n' "$D" "$N"; exit 1; }

clear 2>/dev/null || true
cat <<'BANNER'
  ╭──────────────────────────────────────────────╮
  │                                                │
  │     原力OS · 你的第二个大脑                     │
  │     让你的判断力，越用越值钱                    │
  │                                                │
  ╰──────────────────────────────────────────────╯
BANNER
printf '%s  正在为你准备第二大脑。全程约 30-45 分钟，大部分是自动下载。\n' "$D"
printf '  你可以去忙别的，装好会有提示。你的资料只存在这台电脑，不上云。%s\n' "$N"

# ── 0. 环境检查 ──────────────────────────────────────────
step "第 1 步 / 共 5 步：检查你的电脑"
[ "$(uname)" = "Darwin" ] || oops "这个版本目前只支持苹果 Mac 电脑。"
ARCH=$(uname -m)
[ "$ARCH" = "arm64" ] && ok "苹果芯片 Mac，很适合" || warn "你的是 Intel 芯片 Mac，也能用，但本地模型会慢一些"
command -v curl >/dev/null || oops "系统缺 curl（很少见），请联系技术伙伴。"

# ── 1. 命令行工具（git）──────────────────────────────────
step "第 2 步 / 共 5 步：准备基础工具"
if command -v git >/dev/null 2>&1; then
  ok "基础工具已就绪"
else
  info "需要装一个苹果自带的"命令行工具"（免费，装一次以后就有了）"
  info "屏幕上会弹出一个苹果的安装窗口——请点【安装】，然后等它装完"
  xcode-select --install 2>/dev/null || true
  printf '  %s等待你在弹窗里点【安装】并完成……（装好后本脚本会自动继续）%s\n' "$Y" "$N"
  i=0; until command -v git >/dev/null 2>&1; do i=$((i+1)); [ $i -ge 180 ] && oops "等了很久还没装好命令行工具。装完后，把开头那一行命令再粘一次即可（做过的步骤会自动跳过）。"; sleep 10; done
  ok "基础工具装好了"
fi

# ── 2. Ollama（本地思考核心）+ 起服务 ────────────────────
step "第 3 步 / 共 5 步：装本地思考核心（Ollama）"
if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
  ok "Ollama 已在运行"
else
  if command -v ollama >/dev/null 2>&1; then
    ok "Ollama 已安装，正在启动"
  else
    info "正在自动安装 Ollama（让你的大脑在本地思考、资料不外传）"
    if command -v brew >/dev/null 2>&1; then
      brew install ollama >/dev/null 2>&1 && ok "Ollama 装好了（通过 Homebrew）" || warn "Homebrew 安装没成，改用官方安装包"
    fi
    if ! command -v ollama >/dev/null 2>&1; then
      TMP=$(mktemp -d); info "正在下载 Ollama 官方安装包……"
      if curl -fsSL -o "$TMP/Ollama.dmg" "https://ollama.com/download/Ollama.dmg" 2>/dev/null; then
        MP=$(hdiutil attach "$TMP/Ollama.dmg" -nobrowse -quiet | grep -o '/Volumes/.*' | head -1)
        [ -d "$MP/Ollama.app" ] && { cp -R "$MP/Ollama.app" /Applications/ && ok "Ollama 装好了"; } || warn "自动装 Ollama 没成"
        hdiutil detach "$MP" -quiet 2>/dev/null || true; rm -rf "$TMP"
      else
        warn "下载 Ollama 没成（可能网络问题）"
      fi
    fi
    command -v ollama >/dev/null 2>&1 || [ -d /Applications/Ollama.app ] || oops "没能自动装好 Ollama。请去 ollama.com 手动下载安装（双击拖进"应用程序"即可），然后把开头那行命令再粘一次。"
  fi
  # 起服务
  open -ga Ollama 2>/dev/null || (nohup ollama serve >/dev/null 2>&1 &)
  i=0; until curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; do i=$((i+1)); [ $i -ge 20 ] && oops "Ollama 装好了但没能启动。手动打开一次 Ollama 应用，再把开头那行命令粘一遍。"; sleep 3; done
  ok "本地思考核心已就绪"
fi

# ── 3. 下载两个 AI 模型 ──────────────────────────────────
step "第 4 步 / 共 5 步：下载大脑的思考核心（约 6GB，取决于网速，可能要一会儿）"
if ollama list 2>/dev/null | grep -q "bge-m3"; then ok "记忆模型 bge-m3 已就绪"; else
  info "正在下载记忆模型 bge-m3（帮它记住和检索你的资料）……"; ollama pull bge-m3 && ok "bge-m3 就绪" || oops "bge-m3 下载失败，多半是网络，稍后把命令再粘一次续传。"; fi
if ollama list 2>/dev/null | grep -q "deepseek-r1:8b"; then ok "思考模型 deepseek-r1:8b 已就绪"; else
  info "正在下载思考模型 deepseek-r1:8b（帮它整理和推理，约 5GB）……"; ollama pull deepseek-r1:8b && ok "deepseek-r1:8b 就绪" || warn "思考模型没下全，不影响基本使用，稍后可续。"; fi

# ── 4. clone 大脑正本 + 交给 yos 装机（复用已跑通的装机流程）──
step "第 5 步 / 共 5 步：安装你的第二大脑"
AIP="$HOME/AI Project"; SOUL="$AIP/yuanli-strategy-soul"; mkdir -p "$AIP"
if [ -d "$SOUL/.git" ]; then
  info "更新大脑正本……"; git -C "$SOUL" pull --rebase --autostash -q 2>/dev/null || true
else
  info "下载大脑正本（公开知识底座）……"
  git clone -q https://github.com/moonstachain/yuanli-strategy-soul.git "$SOUL" || oops "下载大脑正本失败（网络问题？），把命令再粘一次即可。"
fi
ok "大脑正本就位"
info "开始安装（引擎 / 建脑 / 接入，约 5-15 分钟自动完成）……"
bash "$SOUL/scripts/yos" install --role colleague || oops "安装最后一步没走完。把命令再粘一次续跑（做过的会自动跳过）；仍不行请联系团队。"

# ── 完成 ─────────────────────────────────────────────────
cat <<'DONE'

  ╭──────────────────────────────────────────────╮
  │   🎉 装好了！你的第二大脑已经就位              │
  ╰──────────────────────────────────────────────╯
DONE
printf '  %s怎么检查它好不好：%s在终端输入 %syos status%s，看到一排绿色的勾就对了。\n' "$B" "$N" "$C" "$N"
printf '  %s怎么开始用它：%s翻开这份指南 —— %shttps://moonstachain.github.io/yuanli-os-quickstart/%s\n' "$B" "$N" "$C" "$N"
printf '  %s从"喂它第一条关于你最近一个重要客户的判断"开始，一周后你就懂它的价值了。%s\n\n' "$D" "$N"
