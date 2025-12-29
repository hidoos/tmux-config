#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_BIN="$ROOT_DIR/bin/tracker-server"

if [[ ! -x "$SERVER_BIN" ]]; then
  echo "Error: tracker-server binary not found at $SERVER_BIN" >&2
  echo "Build it with: (cd $ROOT_DIR && ./install.sh)" >&2
  exit 1
fi

# 检测是否以 root 权限运行（安装 systemd 服务需要）
if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root (use sudo)" >&2
  exit 1
fi

# 检测 systemctl 是否可用
if ! command -v systemctl >/dev/null 2>&1; then
  echo "Error: systemctl not found. systemd is required for Linux." >&2
  exit 1
fi

# 创建 systemd 服务文件
SERVICE_NAME="agent-tracker-server"
SERVICE_FILE="/etc/systemd/user/${SERVICE_NAME}.service"
BIN_INSTALL_DIR="/usr/local/bin"

# 安装二进制文件
echo "Installing tracker-server to $BIN_INSTALL_DIR..."
cp "$SERVER_BIN" "$BIN_INSTALL_DIR/tracker-server"
chmod +x "$BIN_INSTALL_DIR/tracker-server"

# 创建 systemd 服务文件
echo "Creating systemd service file..."
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Agent Tracker Server
After=network.target

[Service]
Type=simple
ExecStart=$BIN_INSTALL_DIR/tracker-server
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# 使用用户环境
Environment="HOME=%h"
Environment="XDG_RUNTIME_DIR=%t"

# 工作目录
WorkingDirectory=%h/.config/agent-tracker

[Install]
WantedBy=default.target
EOF

# 重新加载 systemd
systemctl daemon-reload

# 获取实际用户名（因为可能通过 sudo 运行）
REAL_USER="${SUDO_USER:-${USER}}"

# 启用并启动服务（用户级服务）
echo "Enabling and starting service for user: $REAL_USER..."
if sudo -u "$REAL_USER" systemctl --user enable "$SERVICE_NAME" 2>/dev/null; then
  sudo -u "$REAL_USER" systemctl --user restart "$SERVICE_NAME" 2>/dev/null || sudo -u "$REAL_USER" systemctl --user start "$SERVICE_NAME" 2>/dev/null
else
  echo "Warning: Could not enable service automatically. User may need to run:" >&2
  echo "  systemctl --user enable $SERVICE_NAME" >&2
  echo "  systemctl --user start $SERVICE_NAME" >&2
fi

# 检查服务状态
sleep 1
if sudo -u "$REAL_USER" systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "Agent tracker server is running (managed by systemd --user)."
  SERVICE_STATE=$(sudo -u "$REAL_USER" systemctl --user is-active "$SERVICE_NAME" 2>/dev/null || echo "unknown")
  echo "Service status: $SERVICE_STATE"
else
  echo "Warning: Service may not be running. Check with:" >&2
  echo "  systemctl --user status $SERVICE_NAME" >&2
  exit 1
fi
