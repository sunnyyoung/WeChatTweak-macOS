# WeChatHook-macOS

A dynamic library hook for WeChat macOS.

## Screenshot

![](https://raw.githubusercontent.com/Sunnyyoung/WeChatHook-macOS/master/Screenshot/WeChatHook-macOS.png)

## Feature

- Prevent message revoked

## Usage

- `sudo make install` Inject the dylib to `WeChat` by [insert_dylib](https://github.com/Tyilo/insert_dylib)
- `sudo make uninstall` Uninstall the injection.

## Development

**Requirement: Command Line Tools**

Run `xcode-select --install` to install Command Line Tools.

- `make build` Build the dylib file to the same dicrectory.
- `make debug` Build the dylib file and run `WeChat` with dynamic injection.
- `make clean` Clean output files.

## Dependency

- [insert_dylib](https://github.com/Tyilo/insert_dylib)

## License
The [MIT License](LICENSE).
