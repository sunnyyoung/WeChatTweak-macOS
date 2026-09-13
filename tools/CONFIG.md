# 维护补丁配置

每个版本可显式指定相对于 `Contents` 的 `binary`：

- 缺省或 `MacOS/WeChat`：旧版主程序。
- `Resources/wechat.dylib`：新版业务动态库。

工具不会根据文件存在情况猜测地址属于哪个二进制。每个 entry 可添加
`expected` 十六进制原始字节（长度须与 `asm` 相同），用于拒绝不匹配的二进制。
目标已经等于 `asm` 时允许重复执行。

新地址须分别验证：静态语义、实际写入字节、签名、启动、对应功能。
“进程未退出”只能作为线索，不能证明多开或防撤回生效。
本地配置使用 `swift run wechattweak patch --config /absolute/path/config.json`；
不传 `--config` 时仍从上游下载配置。

补丁会保留 `<binary>.<version>.bak`。它是首次使用本工具时的文件副本，
不能保证文件此前未被其他工具修改。恢复时应先退出测试应用，复制备份回原路径，
对 `Resources/wechat.dylib`（若存在）及整个 app 重新 ad-hoc 签名，并执行
`codesign --verify --deep --strict`。测试应使用 app 副本，保留原安装作为完整回退。

补丁器边界和原子校验回归可独立运行，无需修改 `Package.swift`：

```bash
swiftc Sources/WeChatTweak/Config.swift Sources/WeChatTweak/Patcher.swift \
  tools/test_patcher_safety.swift -o /tmp/test_patcher_safety
/tmp/test_patcher_safety
```
