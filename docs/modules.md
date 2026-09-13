# tshell 模块清单（九模块冻结，p.9.3.6）

*EN: tshell nine-module catalog (frozen).*

架构文档 tshell-architecture.md §12.1 定义九模块；本批（p.9.3.1-6）已落实现与
边界。每模块为**编译期/嵌入期装配的库级能力单元**（对齐 §12：独立嵌入单元，
`use tshell.<module>` 即取，体积随工作集）。

| 模块 | 文件 | 职责 | 落地子项 |
| ---- | ---- | ---- | -------- |
| `lineedit` | `src/lineedit.tie` | 行编辑状态机：insert/backspace/left/right/home/end/历史上下；复杂编辑（多行续行/括号自动补全/Ctrl-R）定界注明待 tty/终端前端 | p.9.3.2 |
| `complete` | `src/complete.tie` | 可插拔补全源（内建命令 + cwd 文件路径基础源；PATH/标识符源留注册点） | p.9.3.2 |
| `command` | `src/command.tie` | 命令解析（tie→内建→外部）+ 内建命令集（cd/pwd/ls/cat/echo/mv/cp/rm/set/source/exec/history/observe/help/exit）+ did-you-mean | p.9.3.1 |
| `pipeline` | `src/pipeline.tie` | 值管道 `cmd1 | cmd2`（tie 值传值）+ 谓词管段 count/filter/parse + 单命令分派 | p.9.3.1 |
| `render` | `src/render.tie` | 表/文本/流式渲染（r_emit/r_table，输出流可注入） | p.9.3.1 |
| `session` | `src/session.tie` | 历史持久化（~/.tshell/history）+ 配置 td 资产（config.td）+ 别名 | p.9.3.2 |
| `repl` | `src/repl.tie` | 求值循环 · 三通道分派 · 异常捕获 · 执行后端可注入（interp 现役） | p.9.3.1 |
| `run` | `src/run.tie` | 脚本运行时：-e / -f / 裸路径 / shebang / 内建命令函数式调用 | p.9.3.3 |
| `observe` | `src/observe.tie` | tieir 观测/调试/动态加载 **骨架**（接口等待 trm p.7.3）+ `set eval-backend` | p.9.3.5 |

**协议/基础（非九模块，但承重）**：`src/backend_interp.tie`（单点委托 tiec
`interp.eval`，求值内核不自己实现）、`src/zd.tie`（tink 帧编解码）、`src/srv.tie`
（双形态协议服务：同进程 zd 总线 + `--stdio` 帧服务）、`src/sh_util.tie`（共享工具）。

## 依赖方向（对齐 §12.2，下层不依赖上层）

```
sh_util ← { complete, render, pipeline, run, session, observe, srv }
backend_interp ← { repl, pipeline, command }
command ← { backend_interp, session, observe, sh_util }
pipeline ← { command, backend_interp, sh_util }
repl ← { pipeline, command, render, backend_interp, sh_util }
run ← { repl, command, pipeline, backend_interp, sh_util }
observe ← { session }
zd ← (无依赖)
srv ← { zd, repl, sh_util }
```

## 装配子集（按需 include）

- **standalone（全量装配）**：`src/tsh_main.tie`（入口即壳）＝默认全量九模块。
- **tedit 终端模组嵌入子集**：`src/tedit_embed.tie`＝ lineedit + complete + command
  + session + render（+ 不装 repl/run/observe 全量；见 docs/embed.md §tedit）。
- 装配即根入口的 import 集合（tie 静态 import 文本内联）；换装配=换入口文件。

## 验收/探针

| 探针 | 覆盖 |
| ---- | ---- |
| `tests/probe_l2.tie` | lineedit / complete / session（ALL PASS） |
| `tests/probe_zd.tie` | zd 帧编解码（CRC 向量 / 往返 / 篡改 / 多帧） |
| `tests/smoke_stdio.tsh.tie` | `--stdio` 帧往返（1+2→3；tsh 驱动） |
| `tests/demo_script.tie` | 脚本运行时（shebang / 内建函数式调用） |