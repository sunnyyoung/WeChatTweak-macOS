# WeChatTweak-macOS

[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)
[![README](https://img.shields.io/badge/Telegram-WeChatTweak-brightgreen.svg)](https://t.me/joinchat/B0vW8kPU5OrwdC1qRbaqRA)
[![Backers on Open Collective](https://opencollective.com/WeChatTweak-macOS/backers/badge.svg)](#backers)
[![Sponsors on Open Collective](https://opencollective.com/WeChatTweak-macOS/sponsors/badge.svg)](#sponsors)

微信 macOS 客户端 Tweak 动态库。

## 截图

### 整体预览

![Overview](Screenshot/0x01.png)

### Alfred workflow

![Alfred](Screenshot/0x02.png)

### LaunchBar action

![LaunchBar](Screenshot/0x03.png)

## 功能

- 阻止消息撤回
  - 消息列表通知
  - 系统通知
  - 正常撤回自己发出的消息
- 客户端无限多开
  - 右键 dock icon 登录新的微信账号
  - 命令行执行：`open -n /Applications/WeChat.app`
- 重新打开应用无需手机认证
- UI界面设置面板
- 支持 Alfred workflow
- 支持 Launchbar action

## 使用

- `sudo make install` 安装或者更新动态库
- `sudo make uninstall` 卸载动态库
- open `WeChat.workflow` 安装 Alfred workflow

## 文档

获取更多信息, 请到 [Wiki](https://github.com/Sunnyyoung/WeChatTweak-macOS/wiki)。

## 依赖

- [JRSwizzle](https://github.com/rentzsch/jrswizzle)
- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## 参考

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)
- [让微信 macOS 客户端支持 Alfred](https://blog.sunnyyoung.net/rang-wei-xin-macos-ke-hu-duan-zhi-chi-alfred/)

## 贡献者

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].

[![Contributors](https://opencollective.com/WeChatTweak-macOS/contributors.svg?width=890&button=false)](/graphs/contributors)

## 支持者

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/WeChatTweak-macOS#backer)]

[![Backers](https://opencollective.com/WeChatTweak-macOS/backers.svg?width=890)](https://opencollective.com/WeChatTweak-macOS#backers)

## 赞助者

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/WeChatTweak-macOS#sponsor)]

[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/0/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/0/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/1/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/1/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/2/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/2/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/3/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/3/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/4/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/4/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/5/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/5/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/6/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/6/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/7/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/7/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/8/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/8/website)
[![Sponsor](https://opencollective.com/WeChatTweak-macOS/sponsor/9/avatar.svg)](https://opencollective.com/WeChatTweak-macOS/sponsor/9/website)

## License

The [Apache License 2.0](LICENSE).
