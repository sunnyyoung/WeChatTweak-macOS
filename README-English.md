# WeChatTweak-macOS

[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README-English.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README.md)
[![README](https://img.shields.io/badge/Telegram-WeChatTweak-brightgreen.svg)](https://t.me/wechattweak)

A dynamic library tweak for WeChat macOS.

## Features

- Anti message revoked
  - Message list notification
  - System notification
  - Revoke message you sent
- Multiple WeChat Instance
  - Launch from Dock menu
  - Run command: `open -n /Applications/WeChat.app`
- Messages enhancement
  - Support stickers exporting
  - Support QRCode identifying
  - Support right-click copy link directly
  - Support opened by the system default browser directly
- Auto login without authentication
- UI Interface settings panel
- Alfred workflow support
- Launchbar action support

## Usage

Install command line tool [WeChatTweak-CLI](https://github.com/Sunnyyoung/WeChatTweak-CLI):

  ```bash
  $ brew tap sunnyyoung/repo
  $ brew install wechattweak-cli
  ```

Install/Upgrade/Uninstall Tweak:

  ```bash
  $ sudo wechattweak-cli --install   # Install
  $ sudo wechattweak-cli --uninstall # Uninstall
  ```

## Screenshots

### Overview

![Overview](Screenshot/0x01.png)

### Alfred workflow

![Alfred](Screenshot/0x02.png)

### LaunchBar action

![LaunchBar](Screenshot/0x03.png)

## References

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)
- [让微信 macOS 客户端支持 Alfred](https://blog.sunnyyoung.net/rang-wei-xin-macos-ke-hu-duan-zhi-chi-alfred/)

## Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].

[![Contributors](https://opencollective.com/WeChatTweak-macOS/contributors.svg?width=890&button=false)](https://github.com/Sunnyyoung/WeChatTweak-macOS/graphs/contributors)

## License

The [Apache License 2.0](LICENSE).
