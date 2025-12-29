#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 创建 ~/.config/tmux 目录
echo "创建 ~/.config/tmux 目录..."
mkdir -p "$HOME/.config/tmux/scripts"
mkdir -p "$HOME/.config/tmux/tmux-status"

# 复制 scripts
echo "复制 scripts..."
cp -r "$SCRIPT_DIR/tmux/scripts/"* "$HOME/.config/tmux/scripts/"

# 复制 tmux-status
echo "复制 tmux-status..."
cp -r "$SCRIPT_DIR/tmux/tmux-status/"* "$HOME/.config/tmux/tmux-status/"

# 复制 starship 配置
echo "复制 starship-tmux.toml..."
cp "$SCRIPT_DIR/starship-tmux.toml" "$HOME/.config/"

# 复制 fzf_panes.tmux
echo "复制 fzf_panes.tmux..."
cp "$SCRIPT_DIR/tmux/fzf_panes.tmux" "$HOME/.config/tmux/"

echo "完成！配置已应用到 $HOME"
