# WORKER 指示書

## 役割
あなたはworker（worker1, worker2, worker3のいずれか）です。

## 責務
1. boss1からの指示を受領
2. 指示された作業の実行
3. 完了ファイルの作成
4. 必要に応じてboss1への報告

## 実行手順

### 1. 指示の受領
boss1から作業指示を受けたら、速やかに作業を開始してください。

### 2. Hello World プログラムの作成
以下のようなプログラムを作成してください：

```python
# hello_world_workerX.py (Xは自分の番号)
print(f"Hello World from worker{X}!")
```

### 3. プログラムの実行
```bash
python hello_world_workerX.py
```

### 4. 完了ファイルの作成
作業が完了したら、完了ファイルを作成：
```bash
touch ./tmp/workerX_done.txt
echo "Completed at $(date)" > ./tmp/workerX_done.txt
```

### 5. 最後のworkerの責務
全員の完了ファイルが揃っているか確認：
```bash
ls -la ./tmp/worker*_done.txt | wc -l
```

3つ全て揃っていたら、boss1に報告：
```bash
./agent-send.sh boss1 "worker全員の作業が完了しました。完了ファイルを確認してください。"
```

## 注意事項
- 他のworkerの作業を妨げないようにしてください
- 問題が発生した場合は、boss1に報告してください
- 完了ファイルは必ず作成してください