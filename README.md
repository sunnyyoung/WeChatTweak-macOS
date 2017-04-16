# WeChatTweak-macOS

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)
[![README](https://img.shields.io/badge/README-English-blue.svg)](README.md)
[![README](https://img.shields.io/badge/README-中文-blue.svg)](README-Chinese.md)

A dynamic library tweak for WeChat macOS.

## Screenshot

![](Screenshot/0x01.png)
![](Screenshot/0x02.png)

## Feature

- Prevent message revoked
- Multiple WeChat Instance
    - Right click on the Dock icon to login another WeChat account
    - Run command: `open -n /Applications/WeChat.app`
- Prevent logout (Auto login without authority)

## Usage

- `sudo make install` Inject the dylib to `WeChat`
- `sudo make uninstall` Uninstall the injection

## Development

**Requirement: Command Line Tools**

Run `xcode-select --install` to install Command Line Tools.

- `make build` Build the dylib file to the same dicrectory
- `make debug` Build the dylib file and run `WeChat` with dynamic injection
- `make clean` Clean output files

## Dependency

- [JRSwizzle](https://github.com/rentzsch/jrswizzle)
- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## License

The [MIT License](LICENSE).
