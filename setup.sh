#!/bin/bash

# Claude Code Communication Setup Script
# This script sets up the tmux environment for hierarchical agent communication

echo "🚀 Claude Code Communication Setup"
echo "=================================="

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "❌ tmux is not installed. Please install tmux first."
    exit 1
fi

# Kill existing sessions if they exist
echo "🧹 Cleaning up existing sessions..."
tmux kill-session -t multiagent 2>/dev/null || true
tmux kill-session -t president 2>/dev/null || true

# Create directories if they don't exist
echo "📁 Creating necessary directories..."
mkdir -p ./tmp
mkdir -p ./logs
mkdir -p ./instructions

# Clean up any existing done files
echo "🗑️  Cleaning up old completion files..."
rm -f ./tmp/worker*_done.txt

# Create multiagent session with 4 panes
echo "🏗️  Creating multiagent session..."
tmux new-session -d -s multiagent -n agents

# Split the window into 4 panes (2x2 grid)
tmux split-window -h -t multiagent:0
tmux split-window -v -t multiagent:0.0
tmux split-window -v -t multiagent:0.1

# Set pane titles (requires tmux 2.3+)
tmux select-pane -t multiagent:0.0 -T "boss1"
tmux select-pane -t multiagent:0.1 -T "worker1"
tmux select-pane -t multiagent:0.2 -T "worker2"
tmux select-pane -t multiagent:0.3 -T "worker3"

# Create president session
echo "👔 Creating president session..."
tmux new-session -d -s president -n president
tmux select-pane -t president:0.0 -T "PRESIDENT"

# Enable pane borders and titles
tmux set -t multiagent pane-border-status top
tmux set -t president pane-border-status top

# Set working directory for all panes
for session in multiagent president; do
    for pane in $(tmux list-panes -t $session -F '#{pane_id}'); do
        tmux send-keys -t $pane "cd $(pwd)" C-m
    done
done

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Attach to sessions:"
echo "   tmux attach-session -t multiagent"
echo "   tmux attach-session -t president"
echo ""
echo "2. Start Claude Code:"
echo "   - First in president session: claude"
echo "   - Then in all multiagent panes: for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude' C-m; done"
echo ""
echo "3. Start the demo in president session:"
echo "   あなたはpresidentです。指示書に従って"
echo ""
echo "🎯 Happy communicating!"