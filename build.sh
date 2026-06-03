#!/bin/bash
set -e

# ============================================================
# Step 1: install xmake if missing
# ============================================================
if ! command -v xmake &>/dev/null; then
    echo "[*] Installing xmake..."
    curl -fsSL https://xmake.io/shget.text | bash
    # or: sudo apt install xmake
fi

# ============================================================
# Step 2: build memleak (BPF skeleton + user-space binary)
# ============================================================
echo "[*] Building memleak..."
xmake build memleak

# ============================================================
# Step 3: build test_memleak
# ============================================================
echo "[*] Building test_memleak..."
xmake build test_memleak

echo ""
echo "[OK] Build complete!"
echo "  binaries located in: build/linux/x86_64/release/"
ls -lh build/linux/x86_64/release/memleak build/linux/x86_64/release/test_memleak 2>/dev/null || \
ls -lh build/linux/x86_64/debug/memleak build/linux/x86_64/debug/test_memleak 2>/dev/null
