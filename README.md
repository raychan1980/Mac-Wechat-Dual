# 微信双开修复器

一个用于修复 macOS 微信双开的轻量脚本。

当微信更新后，第二个微信 `WeChat2.app` 可能会被还原成和官方微信相同的 Bundle ID，导致 macOS 再次把两个应用识别为同一个微信，从而无法同时打开。本工具会自动把第二个微信改成独立 Bundle ID，并重新签名。

## 适用场景

- 你已经安装了 macOS 官方微信。
- 你希望在同一台 Mac 上同时启动两个微信。
- 你之前可以双开，但微信更新后突然不能双开。
- 你愿意把第二个微信放在 `/Applications/WeChat2.app`。

## 原理说明

macOS 通过应用包内的 `CFBundleIdentifier` 识别应用。

官方微信的 Bundle ID 通常是：

```text
com.tencent.xinWeChat
```

如果直接复制一份微信，两个应用包仍然使用同一个 Bundle ID，系统可能会把它们当成同一个应用处理。这个脚本会把第二个微信修改为：

```text
com.tencent.xinWeChat2
```

然后使用 macOS 自带的 `codesign` 做临时重签名，并刷新 LaunchServices 应用登记。

## 文件说明

```text
fix-dual-wechat.sh      # 主脚本：修复 WeChat2.app，并默认启动两个微信
启动双微信.command       # 双击运行入口，适合日常使用
README.md              # 使用说明
```

## 准备两个微信

脚本约定两个微信必须放在 `/Applications` 目录下，并使用下面的名字：

```text
/Applications/WeChat.app
/Applications/WeChat2.app
```

其中：

- `WeChat.app` 是官方微信，正常安装即可。
- `WeChat2.app` 是第二个微信，可以手动复制，也可以让脚本自动复制。

### 方法一：让脚本自动复制

只要你的电脑里已经有：

```text
/Applications/WeChat.app
```

直接运行脚本即可。如果脚本发现没有：

```text
/Applications/WeChat2.app
```

它会自动从官方微信复制一份出来。

### 方法二：手动复制

你也可以自己复制：

1. 打开 Finder。
2. 进入“应用程序”目录。
3. 找到 `WeChat.app`。
4. 复制一份。
5. 把复制出来的新应用改名为 `WeChat2.app`。
6. 确认最终路径是：

```text
/Applications/WeChat2.app
```

注意：名字必须是 `WeChat2.app`。如果命名为 `微信2.app`、`WeChat Copy.app` 或其他名字，当前脚本不会处理它。

## 使用方法

### 推荐方式：双击运行

双击：

```text
启动双微信.command
```

脚本会自动完成：

1. 检查 `/Applications/WeChat.app` 是否存在。
2. 检查 `/Applications/WeChat2.app` 是否存在。
3. 如果 `WeChat2.app` 不存在，就复制一份。
4. 修改 `WeChat2.app` 的 Bundle ID。
5. 重新签名 `WeChat2.app`。
6. 刷新 macOS 应用登记。
7. 启动官方微信和第二个微信。

第一次运行 `.command` 文件时，macOS 可能会提示来自未验证开发者。可以在“系统设置 > 隐私与安全性”里允许打开，或改用终端运行。

### 终端运行

进入项目目录：

```bash
cd /path/to/微信双开修复器
```

添加执行权限：

```bash
chmod +x fix-dual-wechat.sh 启动双微信.command
```

修复并启动两个微信：

```bash
./fix-dual-wechat.sh
```

只修复，不启动微信：

```bash
./fix-dual-wechat.sh --fix-only
```

## 微信更新后怎么做

微信更新后，如果又不能双开，重新运行一次：

```bash
./fix-dual-wechat.sh
```

原因通常是更新把 `WeChat2.app` 的 Bundle ID 和签名状态恢复成官方版本。脚本会重新修改并签名。

## 需要输入密码吗

大多数情况下不需要。

如果你的 `/Applications/WeChat2.app` 归属权限不允许当前用户修改，脚本会自动尝试使用 `sudo`，这时可能需要输入 Mac 登录密码。

## 适配的 macOS 版本

脚本只依赖 macOS 自带工具：

- `zsh`
- `cp`
- `/usr/libexec/PlistBuddy`
- `codesign`
- `open`
- `lsregister`

理论上适用于包含这些工具的现代 macOS 版本，建议使用：

```text
macOS 10.15 Catalina 或更高版本
```

已知在 Apple Silicon 和 Intel Mac 上都应可工作，因为脚本不修改微信二进制架构，只修改应用包信息并重新签名。

如果未来微信或 macOS 改变应用签名、沙盒、Bundle ID 或启动逻辑，本工具可能需要更新。

## 常见问题

### 运行后还是只能打开一个微信

先确认两个应用路径和名字是否正确：

```bash
ls -ld /Applications/WeChat.app /Applications/WeChat2.app
```

再确认第二个微信的 Bundle ID：

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Applications/WeChat2.app/Contents/Info.plist
```

正确结果应为：

```text
com.tencent.xinWeChat2
```

### WeChat2.app 不存在

直接运行脚本即可，脚本会尝试自动复制。

也可以手动复制 `/Applications/WeChat.app`，并把复制出来的应用命名为 `/Applications/WeChat2.app`。

### 提示权限不足

可以尝试：

```bash
sudo ./fix-dual-wechat.sh
```

或检查 `/Applications/WeChat2.app` 的文件归属。

### 会影响官方微信吗

脚本只会读取 `/Applications/WeChat.app`，不会修改官方微信。

脚本会修改和重签：

```text
/Applications/WeChat2.app
```

## 开源说明

本项目仅用于个人学习和本机自动化。微信是腾讯公司的产品，使用时请遵守微信和 macOS 的相关服务条款与使用规则。

如果你从其他项目了解到类似方法，建议在仓库中注明参考来源。
