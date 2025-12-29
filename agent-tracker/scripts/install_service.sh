#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 检测操作系统
OS="$(uname -s)"
case "$OS" in
  Darwin)
    echo "Detected macOS, using Homebrew service..."
    ./scripts/install_brew_service.sh
    ;;
  Linux)
    echo "Detected Linux, using systemd service..."
    if ! command -v systemctl >/dev/null 2>&1; then
      echo "Error: systemctl not found. systemd is required for Linux." >&2
      exit 1
    fi
    # 检查是否有 sudo 权限
    if sudo -n true 2>/dev/null; then
      sudo ./scripts/install_systemd_service.sh
    else
      echo "This script needs sudo privileges to install systemd service."
      echo "Please run: sudo ./scripts/install_systemd_service.sh"
      exit 1
    fi
    ;;
  *)
    echo "Error: Unsupported operating system: $OS" >&2
    echo "Only Linux and macOS (Darwin) are supported." >&2
    echo "Please install the service manually." >&2
    exit 1
    ;;
esac
