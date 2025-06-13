# Claude Code Agent Communication Demo

階層型マルチエージェント通信システムのデモンストレーション

## 🎯 概要
PRESIDENT → BOSS → Workers の階層構造でタスクを実行するシステム

## 🚀 クイックスタート

### 1. 環境構築
```bash
./setup.sh
```

### 2. セッションアタッチ
```bash
# 別々のターミナルで実行
tmux attach-session -t president
tmux attach-session -t multiagent
```

### 3. Claude Code起動
1. PRESIDENTで認証: `claude`
2. 全エージェント起動: `for i in {0..3}; do tmux send-keys -t multiagent:0.$i 'claude' C-m; done`

### 4. デモ実行
PRESIDENTセッションで:
```
あなたはpresidentです。指示書に従って
```

## 📁 ファイル構成
- `setup.sh` - 環境構築スクリプト
- `agent-send.sh` - エージェント間通信ツール
- `instructions/` - 各エージェントの指示書
- `CLAUDE.md` - 詳細ドキュメント

## 🔧 手動操作
```bash
# メッセージ送信
./agent-send.sh [エージェント名] [メッセージ]

# エージェント一覧
./agent-send.sh --list
```