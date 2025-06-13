# Claude Code Agent Communication System

## システム概要
このプロジェクトは、Claude Codeを使用した階層型エージェント間通信システムのデモンストレーションです。

## アーキテクチャ

```
PRESIDENT (統括責任者)
    ↓
boss1 (チームリーダー)
    ↓
├── worker1 (実行担当者)
├── worker2 (実行担当者)
└── worker3 (実行担当者)
```

## ディレクトリ構造

```
/
├── setup.sh              # tmux環境構築スクリプト
├── agent-send.sh         # エージェント間通信スクリプト
├── CLAUDE.md            # このファイル
├── instructions/        # 各エージェントの指示書
│   ├── president.md
│   ├── boss.md
│   └── worker.md
├── tmp/                 # 作業ファイル格納
│   └── worker*_done.txt # 完了フラグファイル
└── logs/                # ログファイル格納
    └── send_log.txt     # 送信ログ
```

## 通信プロトコル

### 1. 指示系統
- PRESIDENT → boss1: プロジェクト開始指示
- boss1 → workers: 個別タスク指示
- workers → boss1: 完了報告（最後のworker）
- boss1 → PRESIDENT: 全体完了報告

### 2. メッセージ送信方法
```bash
./agent-send.sh [エージェント名] [メッセージ]
```

### 3. tmuxセッション構成
- **president セッション**: PRESIDENT専用（1ペイン）
- **multiagent セッション**: boss1とworkers用（4ペイン）
  - pane 0: boss1
  - pane 1: worker1
  - pane 2: worker2
  - pane 3: worker3

## 完了判定ロジック

### Worker側
1. 各workerは作業完了時に`./tmp/workerX_done.txt`を作成
2. 最後に完了したworkerが全員分の完了を確認
3. 全員完了を確認したらboss1に報告

### Boss側
1. workerからの完了報告を受信
2. 完了ファイルの存在を確認
3. PRESIDENTに最終報告

## デバッグ情報

### ログ確認
```bash
# 全送信ログ
cat logs/send_log.txt

# 特定エージェントのログ
grep "boss1" logs/send_log.txt
```

### セッション状態確認
```bash
# セッション一覧
tmux list-sessions

# ペイン詳細
tmux list-panes -t multiagent -F "#{pane_index}: #{pane_title}"
```

### 完了状態確認
```bash
# 完了ファイル一覧
ls -la ./tmp/worker*_done.txt

# 完了数カウント
ls ./tmp/worker*_done.txt 2>/dev/null | wc -l
```

## トラブルシューティング

### Q: エージェントにメッセージが届かない
A: tmuxセッションが起動しているか確認してください
```bash
tmux list-sessions
```

### Q: 完了ファイルが作成されない
A: tmpディレクトリの権限を確認してください
```bash
ls -ld ./tmp
```

### Q: ログが記録されない
A: logsディレクトリが存在するか確認してください
```bash
mkdir -p ./logs
```

## 注意事項
- Claude Codeの認証はPRESIDENTセッションで最初に行ってください
- 各エージェントは独立したClaude Codeインスタンスとして動作します
- メッセージは非同期で処理されるため、タイミングに注意してください