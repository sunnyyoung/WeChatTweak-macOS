# tools/analysis — 269602 逆向分析原型脚本

本目录是 2026-09-13 会话中定位微信 4.1.13 (CFBundleVersion=269602) 补丁偏移的原型脚本，
最新结论见 [FINDINGS-269602.md](FINDINGS-269602.md)：多开地址为 `0x27370c`，防撤回地址为 `0x44de938`。

仅供维护 config.json 时参考，不参与 wechattweak 构建。交接文档见仓库根目录
`HANDOFF-269602.md`。

| 文件 | 用途 |
|---|---|
| `funcgraph.py` | 解析 LC_FUNCTION_STARTS 得到精确函数边界表；建 BL 调用图；提取函数内引用的字符串。被其他脚本 import |
| `xref.py` | 定位锚点字符串（is_revoke / revoke_time 等）的 VA，并反向扫描 adrp+add 交叉引用 |
| `shape.py` | 形状搜索：按"函数大小 + 被引用次数 + 含 [x8,#0x50] 虚调用 + cset 结尾"找 revoke thunk 的跨版本对应物（**已成功定位 revoke=0x44de938**） |
| `find_thunk.py` | 掩码字节搜索（BL/adrp 立即数归零后全文匹配），32288→269602 未命中 |
| `cluster_strings.py` | 扫描 32288 revoke 簇内函数的字符串引用 |
| `fp-32288.json` | 32288 的函数指纹（locate.py fingerprint 产出） |
| `candidates-269602.txt` | wechat.dylib 中 refcount==1 的常量返回函数（29 个），multiInstance 补丁试验候选清单 |
| `probe.c` / `probe2.c` | DYLD_INSERT 探针：interpose exit / connect / sendto 并打印回溯 |
| `probe5.c` | **补丁试验探针**：使用 dyld 回调并校验代码范围；wechat.dylib 加载后把 `WECHAT_PATCH_ADDR` 指定的函数原地改成 `mov w0,#1; ret`（旧编译产物有错误，请从当前源码重新编译） |

脚本硬编码了 /tmp 路径（`/tmp/wecomtweak/WeChat_arm64` 等），见交接文档 §6 重新生成。
