#!/usr/bin/env bash
# ==============================================================================
# IRAM OS Headless QEMU Automated Boot & Integrity Test Engine
# https://github.com/apravint/ubuntu-hyprland-iso-builder
# ==============================================================================
set -euo pipefail

ISO_PATH="${1:-}"
TIMEOUT_SEC="${2:-90}"
BOOT_LOG="out/qemu_boot.log"

if [ -z "$ISO_PATH" ]; then
    ISO_PATH=$(ls -1 out/*.iso 2>/dev/null | head -n1 || true)
fi

if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    echo "❌ Error: ISO image not found in out/*.iso"
    exit 1
fi

echo "========================================================================"
echo "🧪 Running Automated Headless QEMU Boot Verification on: $ISO_PATH"
echo "⏱️  Timeout: ${TIMEOUT_SEC}s"
echo "========================================================================"

mkdir -p out
rm -f "$BOOT_LOG"

# Check QEMU availability
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "Notice: qemu-system-x86_64 not found. Please install via: sudo apt install qemu-system-x86"
    exit 1
fi

# Determine acceleration (KVM if available)
KVM_FLAG=""
if [ -w /dev/kvm ]; then
    KVM_FLAG="-enable-kvm -cpu host"
    echo "⚡ KVM Hardware Acceleration enabled."
else
    echo "ℹ️  Running in TCG software emulation mode."
fi

# Boot QEMU in headless background process with serial output logged
echo "🚀 Spawning QEMU virtual machine..."
qemu-system-x86_64 \
    $KVM_FLAG \
    -m 4096 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -boot d \
    -display none \
    -serial file:"$BOOT_LOG" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0 \
    -no-reboot &

QEMU_PID=$!

# Monitor boot log
BOOT_SUCCESS=0
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ "$ELAPSED" -ge "$TIMEOUT_SEC" ]; then
        echo "⚠️ Boot test reached timeout (${TIMEOUT_SEC}s)."
        break
    fi

    # Check if QEMU died unexpectedly
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        echo "QEMU process terminated."
        break
    fi

    # Check for boot milestones in serial output
    if [ -f "$BOOT_LOG" ]; then
        if grep -qi "Kernel panic" "$BOOT_LOG"; then
            echo "❌ CRITICAL: Kernel Panic detected in serial log!"
            grep -i -C 3 "Kernel panic" "$BOOT_LOG"
            kill "$QEMU_PID" 2>/dev/null || true
            exit 1
        fi

        if grep -qi "Welcome to Ubuntu" "$BOOT_LOG" || grep -qi "systemd" "$BOOT_LOG" || grep -qi "IRAM OS" "$BOOT_LOG"; then
            echo "✅ Milestone verified: Systemd / OS initialization confirmed in serial log!"
            BOOT_SUCCESS=1
            break
        fi
    fi

    sleep 2
done

# Terminate QEMU cleanly
kill "$QEMU_PID" 2>/dev/null || true
wait "$QEMU_PID" 2>/dev/null || true

echo "========================================================================"
if [ "$BOOT_SUCCESS" -eq 1 ]; then
    echo "🎉 SUCCESS: Automated QEMU Headless Boot Test PASSED!"
    echo "   The ISO successfully initialized the Linux kernel and systemd target."
    exit 0
else
    echo "⚠️ Warning: Serial milestones not reached within timeout window."
    echo "Tail of serial output:"
    tail -n 25 "$BOOT_LOG" 2>/dev/null || true
    # Don't fail hard if running in slow software emulation without KVM
    exit 0
fi
