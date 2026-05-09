#!/bin/zsh
set -euo pipefail

WECHAT_APP="/Applications/WeChat.app"
WECHAT2_APP="/Applications/WeChat2.app"
WECHAT2_BUNDLE_ID="com.tencent.xinWeChat2"

say() {
  printf '%s\n' "$1"
}

require_app() {
  if [[ ! -d "$WECHAT_APP" ]]; then
    say "未找到 $WECHAT_APP"
    say "请先安装官方微信，再重新运行这个脚本。"
    exit 1
  fi
}

ensure_wechat2() {
  if [[ -d "$WECHAT2_APP" ]]; then
    return
  fi

  say "未找到 WeChat2.app，正在从官方微信复制一份..."
  if cp -R "$WECHAT_APP" "$WECHAT2_APP" 2>/dev/null; then
    return
  fi

  say "普通复制失败，尝试使用 sudo 复制。可能需要输入 Mac 登录密码。"
  sudo cp -R "$WECHAT_APP" "$WECHAT2_APP"
  sudo chown -R "$(id -un)":admin "$WECHAT2_APP" || true
}

set_bundle_id() {
  say "设置 WeChat2 Bundle ID 为 $WECHAT2_BUNDLE_ID ..."
  if /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $WECHAT2_BUNDLE_ID" "$WECHAT2_APP/Contents/Info.plist" 2>/dev/null; then
    return
  fi

  say "普通写入失败，尝试使用 sudo 修改。可能需要输入 Mac 登录密码。"
  sudo /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $WECHAT2_BUNDLE_ID" "$WECHAT2_APP/Contents/Info.plist"
}

resign_wechat2() {
  say "重新签名 WeChat2.app ..."
  if codesign --force --deep --sign - "$WECHAT2_APP" 2>/dev/null; then
    return
  fi

  say "普通签名失败，尝试使用 sudo 签名。可能需要输入 Mac 登录密码。"
  sudo codesign --force --deep --sign - "$WECHAT2_APP"
}

refresh_launch_services() {
  say "刷新 macOS 应用登记 ..."
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$WECHAT2_APP" || true
}

verify() {
  local bundle_id
  bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$WECHAT2_APP/Contents/Info.plist")

  if [[ "$bundle_id" != "$WECHAT2_BUNDLE_ID" ]]; then
    say "校验失败：当前 WeChat2 Bundle ID 是 $bundle_id"
    exit 1
  fi

  codesign --verify --deep "$WECHAT2_APP" >/dev/null 2>&1 || {
    say "校验失败：WeChat2 签名验证未通过。"
    exit 1
  }

  say "校验通过：WeChat2 已配置为 $WECHAT2_BUNDLE_ID"
}

launch_apps() {
  say "启动官方微信 ..."
  open "$WECHAT_APP" || true

  say "启动 WeChat2 ..."
  nohup "$WECHAT2_APP/Contents/MacOS/WeChat" >/dev/null 2>&1 &

  say "完成。现在可以同时使用两个微信。"
}

main() {
  require_app
  ensure_wechat2
  set_bundle_id
  resign_wechat2
  refresh_launch_services
  verify

  if [[ "${1:-}" == "--fix-only" ]]; then
    say "已完成修复；未启动微信。"
  else
    launch_apps
  fi
}

main "$@"
