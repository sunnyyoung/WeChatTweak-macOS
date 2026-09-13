# WeChatTweak

[![README](https://img.shields.io/badge/GitHub-black?logo=github&logoColor=white)](https://github.com/sunnyyoung/WeChatTweak)
[![README](https://img.shields.io/badge/Telegram-black?logo=telegram&logoColor=white)](https://t.me/wechattweak)
[![README](https://img.shields.io/badge/FAQ-black?logo=googledocs&logoColor=white)](https://github.com/sunnyyoung/WeChatTweak/wiki/FAQ)

A command-line tool for tweaking WeChat.

## 功能

- 阻止消息撤回
- 阻止自动更新
- 客户端多开

## 安装&使用

```bash
# 安装
brew install sunnyyoung/tap/wechattweak

# 更新
brew upgrade wechattweak

# 执行 Patch
wechattweak patch

# 查看所有支持的 WeChat 版本
wechattweak versions
```

## 本地适配微信 4.1.13（269602，Apple Silicon）

本仓库配置已包含新版业务动态库的防撤回和多开补丁。多开已通过应用副本启动验证；
防撤回已完成静态定位及写入验证，尚待另一账号实际撤回消息验证。
Homebrew 和默认远程配置不会自动使用本地改动。

退出微信后，在仓库目录执行：

```bash
swift build -c release
sudo .build/release/wechattweak patch --config "$PWD/config.json"
```

原文件首次备份为 `Contents/Resources/wechat.dylib.269602.bak`。
配置与回归说明见 [tools/CONFIG.md](tools/CONFIG.md)，定位证据见
[tools/analysis/FINDINGS-269602.md](tools/analysis/FINDINGS-269602.md)。

## 参考

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)
- [让微信 macOS 客户端支持 Alfred](https://blog.sunnyyoung.net/rang-wei-xin-macos-ke-hu-duan-zhi-chi-alfred/)

## 贡献者

This project exists thanks to all the people who contribute.

[![Contributors](https://contrib.rocks/image?repo=sunnyyoung/WeChatTweak)](https://github.com/sunnyyoung/WeChatTweak/graphs/contributors)

## License

The [AGPL-3.0](LICENSE).
