# WeChatTweak-macOS

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)

A dynamic library tweak for WeChat macOS.

## Screenshot

![](Screenshot/WeChatTweak-macOS.png)

## Feature

- Prevent message revoked
- Multiple WeChat Instance
    - Run command: `open -n /Applications/WeChat.app`

## Usage

- `sudo make install`   Inject the dylib to `WeChat` by [insert_dylib](https://github.com/Tyilo/insert_dylib)
- `sudo make uninstall` Uninstall the injection

## Development

**Requirement: Command Line Tools**

Run `xcode-select --install` to install Command Line Tools.

- `make build` Build the dylib file to the same dicrectory
- `make debug` Build the dylib file and run `WeChat` with dynamic injection
- `make clean` Clean output files

## Dependency

- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## License
The [MIT License](LICENSE).
