# WeChatTweak-macOS

[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README-English.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README.md)
[![README](https://img.shields.io/badge/Telegram-WeChatTweak-brightgreen.svg)](https://t.me/joinchat/B0vW8kPU5OrwdC1qRbaqRA)
[![Backers on Open Collective](https://opencollective.com/WeChatTweak-macOS/backers/badge.svg)](#backers)
[![Sponsors on Open Collective](https://opencollective.com/WeChatTweak-macOS/sponsors/badge.svg)](#sponsors)

A dynamic library tweak for WeChat macOS.

## Screenshot

### Overview

![Overview](Screenshot/0x01.png)

### Alfred workflow

![Alfred](Screenshot/0x02.png)

### LaunchBar action

![LaunchBar](Screenshot/0x03.png)

## Feature

- Prevent message revoked
  - Message list notification
  - System notification
  - Revoke message you sent
- Multiple WeChat Instance
  - Right click on the dock icon to login another WeChat account
  - Run command: `open -n /Applications/WeChat.app`
- URL type messages enhancement
  - Support right-click copy link directly
  - Support opened by the system default browser directly
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

## Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].

[![Contributors](https://opencollective.com/WeChatTweak-macOS/contributors.svg?width=890&button=false)](https://github.com/Sunnyyoung/WeChatTweak-macOS/graphs/contributors)

## Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/WeChatTweak-macOS#backer)]

[![Backers](https://opencollective.com/WeChatTweak-macOS/backers.svg?width=890)](https://opencollective.com/WeChatTweak-macOS#backers)

## Sponsors

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
