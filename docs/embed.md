# tshell 三种嵌入形态 （p.9.3.6）

*EN: tshell three embedding forms.*

架构 tshell-architecture.md §12.3 定义三种嵌入形态；tshell 能力以独立模块交付，
开发者取子集装进自己的应用。独立命令行壳（standalone）只是**默认全量装配**。

## 1. 静态嵌入（路线 A，默认）

把 tie 源码模块静态编进宿主：装配入口 `import`（tie 静态 import 文本内联）所需
子集 → tiec 编译期按装配裁剪未用模块。**零运行时依赖、随宿主尺寸。**

```tie
import "./lineedit.tie"   // 只取行编辑
import "./session.tie"    // + 会话
```
宿主自己包 `main()`；入口文件换装配即换（示例：`src/tedit_embed.tie`）。

## 2. 动态嵌入（路线 B）

import trm 后经 trm Backend / 对象模型装配模块，获得引擎级 GC / 反射 / 热更。
**接口等待**：依赖 trm 引擎 Backend 接口（随 p.7.3 接入）；observe 模块（p.9.3.5）
已落 `set eval-backend` 配置位与 tieir 观测骨架，作为动态嵌入的接线点。

## 3. 进程外嵌入（语言无关）

任意语言宿主驱动 `tshell --stdio`（tink 帧协议：`[len u32 BE][payload][crc u32 BE]`，
CRC32-IEEE），无需 tie 运行时——`stdin 帧 → 求值 → stdout 帧`。ZD 值语义 + CRC 强
校验。对接细节见 `docs/srv.md`；往返验收 `tests/smoke_stdio.ps1`。

## tedit 终端模组嵌入子集

按架构 §12.4，tedit 终端模组 = **取 lineedit + complete + command + session +
render**（+ repl 可选），**不装 observe / run 全量**。该子集=命令引擎 + 会话 + 行编
辑/补全/渲染，前端（tiu 终端部件）持有渲染与终端 UI，与引擎只走协议数据。

`src/tedit_embed.tie` 为子集装配示例（命令行驱动，演示仅装配会话层能力）。

## 装配协议（最小实现）

- 装配 = 根入口 `import` 集（tie 静态）；`standalone` 入口 = 全量；嵌入者自备宿主，
  只取能力模块。
- `build.ps1` 一次构建两种装配：`src/tsh_main.exe`（standalone）+ `src/tedit_embed.exe`
  （终端模组子集）。