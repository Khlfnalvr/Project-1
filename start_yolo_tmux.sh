#!/bin/bash

# Kill existing tmux session if exists
tmux kill-session -t yolo 2>/dev/null

# Start new tmux session in detached mode
tmux new-session -d -s yolo "cd /home/pi/yolo5 && ./start_yolo.sh"

echo "✅ YOLO started in tmux session 'yolo'"
echo "📺 To view output: tmux attach -t yolo"
echo "⌨️  To detach: Press Ctrl+B then D"
echo "🛑 To stop: tmux kill-session -t yolo"
