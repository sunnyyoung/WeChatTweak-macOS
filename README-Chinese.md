# WeChatTweak-macOS

[![README](https://img.shields.io/badge/README-English-blue.svg)](https://github.com/Sunnyyoung/WeChatTweak-macOS/blob/master/README.md) [![README](https://img.shields.io/badge/README-中文-blue.svg)](https://github.com/Sunnyyoung/WeChatTweak-macOS/blob/master/README-Chinese.md)

微信macOS客户端消息撤回拦截动态库。

## 截图

![](https://raw.githubusercontent.com/Sunnyyoung/WeChatTweak-macOS/master/Screenshot/WeChatTweak-macOS.png)

## 功能

- 阻止消息撤回

## 使用

- `sudo make install`   安装动态库
- `sudo make uninstall` 卸载动态库

## 开发调试

**Requirement: Command Line Tools**

运行命令：`xcode-select --install` 安装Command Line Tools。

- `make build` 编译dylib动态库到当前目录下
- `make debug` 编译dylib动态库并临时注入微信macOS客户端
- `make clean` 清除生成文件

## 依赖

- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## License
The [MIT License](LICENSE).
