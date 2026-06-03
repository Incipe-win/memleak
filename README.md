# memleak - eBPF 内存泄漏检测工具

基于 eBPF uprobe 的用户态内存泄漏检测工具，无需修改目标程序代码即可实时监控内存分配与释放，定位泄漏的调用栈及源码位置。

## 来源

代码来自 B 站 UP 主 **cppbear** 的视频教程：

https://space.bilibili.com/384754914

## 修改内容

基于原版代码做了以下修改：

- **`memleak.h`**：添加 `#ifndef __BPF__` 条件编译，避免 `vmlinux.h` 与 `<linux/types.h>` 冲突
- **`memleak.c`**：
  - 添加 `#include <stdint.h>` 修复 `uintptr_t`/`uint64_t` 未定义
  - 添加 `blaze_symbolize_src_process.type_size` 初始化，修复 blazesym 解析失败
  - 开启 `debug_syms` 以显示源码文件名和行号
  - 适配新版 blazesym API（`blaze_syms` / `blaze_symbolize_process_abs_addrs` 等）
  - 抑制 libbpf 调试日志，仅保留 warning
- **`memleak.bpf.c`**：添加 `#define __BPF__` 宏
- 新增 `xmake.lua`：xmake 构建系统支持（含 BPF skeleton 自动生成）
- 新增 `build.sh`：一键构建脚本

## 构建

### 依赖

- `clang` (支持 `-target bpf`)
- `bpftool`
- `libbpf-dev`
- `xmake`
- `cargo` (Rust 工具链，用于编译 blazesym)

### 编译

```bash
# 克隆（含 blazesym 子模块）
git clone --recursive <repo-url>
cd memleak

# 一键编译（首次会自动构建 blazesym + 生成 vmlinux.h + 编译 BPF）
xmake
```

## 使用方法

```bash
# 1. 启动测试程序
xmake run test_memleak &

# 2. 启动监控（需要 root 权限加载 BPF）
sudo ./build/linux/x86_64/release/memleak $(pidof test_memleak)

# 3. 触发打印泄漏报告
touch /tmp/memleak_print

# 4. 退出监控
touch /tmp/memleak_quit
```

## 输出示例

```
stack_id=0xcc with outstanding allocations: total_size=12 nr_allocs=3
  0 [<000058742a93f1a5>] alloc_v3+0x1c /home/user/memleak/test_memleak.cpp:6
  1 [<000058742a93f1c8>] alloc_v2+0x19 /home/user/memleak/test_memleak.cpp:27
  2 [<000058742a93f1eb>] alloc_v1+0x19 /home/user/memleak/test_memleak.cpp:32
  3 [<000058742a93f228>] main+0x33     /home/user/memleak/test_memleak.cpp:41
```

## License

LGPL-2.1 OR BSD-2-Clause (上游)
