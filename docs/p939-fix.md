# p.9.3.9 tsh REPL 语义修复记录 / tsh REPL Semantics Fix Record

> 2026-09-24。根因修复落点在 tiec 仓（`compiler/interp/interp_p1.tie`，cfde2de）；
> 本仓仅随升格重编 `src/tsh_main.exe`（不入库，.gitignore 约定）。
> EN: Root-cause fix lives in the tiec repo; this repo only rebuilds tsh_main.exe.

## 根因 / Root Cause

`eval_script` 的 `split_top` 把顶层 `var` 归入定义段（`is_def_word("var")`），
var 声明（含带副作用的 init：exec_code / file_read / file_write）在
`register_top_level`（第一趟）即被求值——**先于 main 体全部可执行语句**，
源码顺序被破坏。

此前登记的四个缺陷全部是该根因的表象（底座原语本身无缓存、exec_code =
libc `system()` 本就同步）：

| 原登记缺陷 | 真相 |
| --- | --- |
| ① exec_code 异步返回（须 sleep） | 伪象：var init 里的 exec_code 在注册期执行，语句顺序错位 |
| ② list_dir/file_read/file_exists「首次观测被记住」 | 伪象：读取发生在 var init 求值期（当时文件状态被固化为变量值） |
| ③ 变量赋值不稳定（同轮不同语句见不同值） | 即根因本身：var init 的求值时机与语句序脱钩 |
| ④ exec_output 裸内部命令返回空 | 保留原状：脚本约定 `cmd /c` 显式包装 |

## 修复 / Fix

- tiec `interp_p1.tie`：`is_def_word` 移除 `var`——顶层 var 留在语句段，
  由 `exec_stmt_var_decl` 按源码序执行（顶层落 globals，跨行持久不变；
  函数仍第一趟注册，声明先于调用成立）。
- tiec `scripts/bootstrap-fp.tsh.tie` / `regress-s21.tsh.tie`：移除全部
  `sleep_ms` workaround（验收要求）。

## 验收 / Acceptance

- 探针套件（写后立即读 / exec 后立即读 / 语句顺序 / 环境变量，fresh 场景）全过。
- bootstrap-fp 无 sleep 全绿，且 **[4/4] 打印哈希与产物直核一致**（8292cfa5…，
  此前打印陈旧值也是同一根因）。
- regress-s21 无 sleep：PASS=157 FAIL=8 SKIP=2 与基线一致。
- 不动点 25b9bba9 → **8292cfa5**（interp 经 semantic→mexpand 进 driver 编译
  单元，需三阶自举升格）。

*EN: split_top hoisted top-level `var` declarations (with side-effecting
inits) into the defs segment, evaluating them before every statement —
breaking source order. All four logged defects were symptoms of this single
root cause. Fix keeps var in the statement segment; sleep workarounds
removed; bootstrap-fp printed hash now matches direct product hash; regress
157/8/2 unchanged; new fixed point 8292cfa5.*
