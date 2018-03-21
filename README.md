# WeChatTweak-macOS

[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)
[![README](https://img.shields.io/badge/Telegram-WeChatTweak-brightgreen.svg)](https://t.me/joinchat/B0vW8kPU5OrwdC1qRbaqRA)

A dynamic library tweak for WeChat macOS.

## Screenshot

### Overview

![](Screenshot/0x01.png)

### Alfred workflow

![](Screenshot/0x02.png)

### LaunchBar action
![](Screenshot/0x03.png)

## Feature

- Prevent message revoked
    - Message list notification
    - System notification
    - Revoke message you sent
- Multiple WeChat Instance
    - Right click on the dock icon to login another WeChat account
    - Run command: `open -n /Applications/WeChat.app`
- Auto login without authentication
- UI Interface settings panel
- Alfred workflow support
- Launchbar action support

## Quick Start

- `sudo make install` Install or Upgrade the dylib
- `sudo make uninstall` Uninstall the dylib
- open `WeChat.workflow` Install Alfred workflow

## Documentation

For more informations, please go to the [Wiki](https://github.com/Sunnyyoung/WeChatTweak-macOS/wiki).

## Dependency

- [JRSwizzle](https://github.com/rentzsch/jrswizzle)
- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## Reference

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)
- [让微信 macOS 客户端支持 Alfred](https://blog.sunnyyoung.net/rang-wei-xin-macos-ke-hu-duan-zhi-chi-alfred/)

## License

The [MIT License](LICENSE).
