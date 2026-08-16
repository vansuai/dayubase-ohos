#!/usr/bin/env bash
# 构建并发布 dayubase-ohos 到 ohpm 公共仓库（https://ohpm.openharmony.cn）
#
# 前置条件（一次性，需人工完成）：
#   1. 在 https://ohpm.openharmony.cn 注册账号并完成实名认证；
#   2. 按 ohpm 文档配置发布凭证（~/.ohpm/.ohpmrc 中的 publish_registry / publish_id / key_path / key_passphrase / crypto_path）；
#   3. 执行 ohpm login 完成登录。
#
# 用法：./publish.sh
set -euo pipefail
cd "$(dirname "$0")"

OHPM="$(command -v ohpm || true)"
HVIGORW="$(command -v hvigorw || true)"
if [ -z "$OHPM" ]; then
  OHPM="/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm"
fi
if [ -z "$HVIGORW" ]; then
  HVIGORW="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"
fi

echo "==> 1/4 检查 ohpm registry（需为公共仓库）"
REGISTRY="$("$OHPM" config get registry)"
if [[ "$REGISTRY" != *"ohpm.openharmony.cn"* ]]; then
  echo "❌ 当前 ohpm registry 不是公共仓库: $REGISTRY"
  echo "   请执行: ohpm config set registry https://ohpm.openharmony.cn/ohpm/"
  exit 1
fi
echo "    registry: $REGISTRY"

echo "==> 2/4 构建 HAR"
"$HVIGORW" assembleHar --no-daemon

HAR="$(find library/build/default/outputs/default -maxdepth 1 -name '*.har' 2>/dev/null | head -1)"
if [ -z "$HAR" ]; then
  echo "❌ 未找到 HAR 产物（library/build/default/outputs/default/*.har）"
  exit 1
fi
echo "    产物: $HAR"

echo "==> 3/4 发布预检"
"$OHPM" prepublish "$HAR"

echo "==> 4/4 发布"
"$OHPM" publish "$HAR"
echo "✅ 发布完成。审核通过后即可通过 ohpm install dayubase-ohos 安装。"
