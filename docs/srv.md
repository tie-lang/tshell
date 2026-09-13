# tshell 双形态协议层（L3）· 对接说明（p.9.3.4）

*EN: tshell dual-form protocol layer (L3) — integration notes.*

## 两种形态 / Two forms

| 形态 | 说明 | 载体 |
| ---- | ---- | ---- |
| 同进程 zd 内存总线（tedit 嵌入，默认） | 引擎嵌进宿主进程，只换协议数据不穿对象引用；本批落 **协议最小实现**（zd 帧编解码） | `src/zd.tie`（帧编解码）+ 宿主协议总线 |
| 子进程 `--stdio`（逃生口/远程/WASM） | stdin/stdout 跑 **tink 帧**：`[len u32 BE][payload][crc u32 BE]`（CRC32-IEEE） | `src/srv.tie` |

## tink 帧协议（对齐 std/tink_v2 与 tink-xxx 绑定库）

帧 = `[长度 u32 大端][payload][CRC32 u32 大端]`；CRC32-IEEE 多项式 0xEDB88320，
检查向量 `crc32("123456789")==0xCBF43926`。payload 承载 zd 值（值语义，指纹校验）。

```text
frame := len(4) ++ payload(len) ++ crc(4)
crc   := crc32_ieee(payload)
```

## `--stdio` 服务语义

启动：`tshell --stdio`。子进程（或分布式宿主）逐帧：
`stdin 读帧 → 以 REPL 三通道求值（tie/内建/外部）→ stdout 写响应帧`。

验收：`powershell -File tests/smoke_stdio.ps1`——注入 `1+2` 帧，校验响应帧 payload==`3`
且 CRC 有效（PASS: --stdio roundtrip 1+2 -> 3）。

## tedit 同进程对接（默认形态）

tedit 终端模组 = tiu 终端部件（前端）+ tshell 引擎（后端，`src/zd.tie` 编解码在
进程内直传值，不序列化零拷贝热路径）。宿主把「输入行 / 补全请求 / 输出流 / 任务事件」
协议化为 zd 消息经总线交换；值管道在机内传值，**仅跨模组/跨进程边界自动 zd 帧**。

## 字节原语

编译路径提供 `stdin_read(n)` / `stdout_write_bytes(t)` / `stdout_write_str(s)`；
`--stdio` 据此做二进制帧读写（见 `src/srv.tie` `read_frame` / `srv_stdio`）。