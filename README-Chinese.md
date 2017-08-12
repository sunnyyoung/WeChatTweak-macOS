# WeChatTweak-macOS

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)

微信 macOS 客户端 Tweak 动态库。

## 截图

![](Screenshot/0x01.png)

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

## 使用

- `sudo make install` 安装或者更新动态库
- `sudo make uninstall` 卸载动态库

## 开发调试

**Requirement: Xcode**

### 编译

1. 运行 `pod install`
2. 打开 `WeChatTweak.xcworkspace` 并编译

### 调试

- `make debug` 临时注入微信 macOS 客户端
- `make clean` 清除生成文件

## 依赖

- [JRSwizzle](https://github.com/rentzsch/jrswizzle)
- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## 参考

- [微信 macOS 客户端无限多开功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-wu-xian-duo-kai-gong-neng-shi-jian/)
- [微信 macOS 客户端拦截撤回功能实践](https://blog.sunnyyoung.net/wei-xin-macos-ke-hu-duan-lan-jie-che-hui-gong-neng-shi-jian/)

## License

The [MIT License](LICENSE).
