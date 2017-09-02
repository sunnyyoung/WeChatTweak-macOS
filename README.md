# WeChatTweak-macOS

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)

A dynamic library tweak for WeChat macOS.

## Screenshot

![](Screenshot/0x01.png)

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

## Quick Start

- `sudo make install` Install or Upgrade the dylib
- `sudo make uninstall` Uninstall the dylib

## Documentation

For more informations, please go to the [wiki](https://github.com/Sunnyyoung/WeChatTweak-macOS/wiki).

## Dependency

- [JRSwizzle](https://github.com/rentzsch/jrswizzle)
- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## Reference

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)

## License

The [MIT License](LICENSE).
