#!/bin/bash
# 使用示例：
#   ./start_memleak.sh ./test_memleak
#   ./start_memleak.sh /path/to/your_program arg1 arg2
#
# $$ 是当前脚本进程的 PID。
# exec "$@" 让目标程序继承这个 PID——所以 memleak 用 $$ 就能找到它。

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/linux/x86_64/release"

if [ -z "$1" ]; then
    echo "用法: $0 <要监控的程序> [参数...]"
    echo "示例: $0 ./test_memleak"
    exit 1
fi

echo "[*] 启动 memleak 监控 (监控 PID=$$)"
sudo "$BUILD_DIR/memleak" $$ &
MEMLEAK_PID=$!

# 等 memleak 把 uprobe 挂好
sleep 1

echo "[*] 启动目标程序: $@"
exec "$@"
