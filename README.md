# WeChatTweak-macOS

[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README-English.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README.md)
[![README](https://img.shields.io/badge/Telegram-WeChatTweak-brightgreen.svg)](https://t.me/wechattweak)

微信 macOS 客户端增强 Tweak 动态库。

## 功能

- 阻止消息撤回
  - 消息列表通知
  - 系统通知
  - 正常撤回自己发出的消息
- 客户端无限多开
  - 右键 Dock icon 登录新的微信账号
  - 命令行执行：`open -n /Applications/WeChat.app`
- 消息处理增强
  - 支持任意表情导出
  - 支持二维码识别
  - 支持右键直接复制链接
  - 支持由系统默认浏览器直接打开
- 重新打开应用无需手机认证
- UI界面设置面板
- 支持 Alfred workflow
- 支持 Launchbar action

## 使用

**首次使用**安装 [WeChatTweak-CLI](https://github.com/Sunnyyoung/WeChatTweak-CLI):

  ```bash
  $ brew install sunnyyoung/repo/wechattweak-cli
  ```

安装/更新/卸载 Tweak:

  ```bash
  $ sudo wechattweak-cli --install   # 安装
  $ sudo wechattweak-cli --uninstall # 卸载
  ```

## 截图

### 整体预览

![Overview](Screenshot/0x01.png)

### Alfred workflow

![Alfred](Screenshot/0x02.png)

### LaunchBar action

![LaunchBar](Screenshot/0x03.png)

## FAQ

1. 功能失效？  
  请提交 **issue** 然后等待，或提交 **pull request** 一起发电。
2. Issue 没有响应 or 回复？  
  开源项目，用爱发电，耐心等。
3. 兼容旧版本客户端吗？  
  不，为了降低维护成本和保证更新速度，默认只支持 **最新 App Store** 版本客户端。
4. 会封号吗？  
  在**只使用该工具**的情况下**没有**出现过封号/风险提示，若有**使用过其他同类工具**则有可能会出现封号/风险提示，因此风险自负。
5. 安装出现 `codesign_allocate helper tool cannot be found or used` 错误？  
  该错误为系统问题，暂未清楚原因，一般情况下重新执行安装操作即可。
6. 安装完打开微信客户端提示 `没有权限打开应用程序`？  
  先卸载，再重新安装一次即可，如仍无法解决请重启电脑。

## 参考

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)
- [让微信 macOS 客户端支持 Alfred](https://blog.sunnyyoung.net/rang-wei-xin-macos-ke-hu-duan-zhi-chi-alfred/)

## 贡献者

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].

[![Contributors](https://opencollective.com/WeChatTweak-macOS/contributors.svg?width=890&button=false)](https://github.com/Sunnyyoung/WeChatTweak-macOS/graphs/contributors)

## License

The [Apache License 2.0](LICENSE).
