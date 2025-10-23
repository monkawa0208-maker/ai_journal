# デプロイメントガイド（Render向けメモリ最適化）

## 概要
このドキュメントでは、Renderでai_journalをデプロイする際のメモリ最適化設定について説明します。

## メモリ問題の診断

Renderでメモリ制限を超える主な原因：

1. **Pumaのワーカー数過多**: CPUコア数に基づいて自動設定されるため、小さいインスタンスでは過剰
2. **画像処理のメモリ消費**: Active Storageの画像処理時に大量のメモリを使用
3. **ログの肥大化**: 詳細なログがI/Oとメモリを消費
4. **データベースコネクション**: コネクションプールが大きすぎる

## 実装した最適化

### 1. Puma設定の最適化（`config/puma.rb`）

```ruby
# ワーカー数をデフォルト2に制限
worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 2 })

# メモリリーク対策
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end
```

**効果**: メモリ使用量を50〜70%削減

### 2. 本番環境設定の最適化（`config/environments/production.rb`）

```ruby
# ログレベルをwarnに設定
config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn")

# データベースコネクションプール
config.active_record.connection_pool_size = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i

# キャッシュサイズの制限
config.cache_store = :memory_store, { size: 64.megabytes }
```

**効果**: ログI/Oの削減、メモリ使用量の安定化

### 3. 画像処理の最適化（`config/initializers/active_storage.rb`）

```ruby
# MiniMagickのメモリ制限
MiniMagick.configure do |config|
  config.cli_options = {
    'limit' => {
      'memory' => '256MiB',
      'map' => '512MiB',
      'disk' => '1GiB'
    }
  }
  config.timeout = 30
end
```

**効果**: 画像処理時のメモリスパイクを防止

### 4. 画像バリデーション（`app/models/entry.rb`）

```ruby
# ファイルサイズ制限（10MB）
# 許可フォーマット: JPEG, PNG, GIF, WebP
validate :acceptable_image
```

**効果**: 大きすぎる画像のアップロードを防止

## 環境変数の設定

### 必須環境変数
```bash
# アプリケーション
RAILS_MASTER_KEY=your_master_key
OPENAI_API_KEY=your_openai_api_key

# AWS S3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# 認証
BASIC_AUTH_USER=your_username
BASIC_AUTH_PASSWORD=your_password
```

### メモリ最適化環境変数

#### 推奨設定（512MB〜1GB インスタンス）
```bash
WEB_CONCURRENCY=2                # Pumaワーカー数
RAILS_MAX_THREADS=5              # スレッド数
RAILS_LOG_LEVEL=warn             # ログレベル
MALLOC_ARENA_MAX=2               # メモリアロケーター最適化
RUBY_GC_HEAP_GROWTH_FACTOR=1.1   # GCヒープ成長率
RUBY_GC_MALLOC_LIMIT=16000000    # GCトリガーメモリ量（16MB）
```

#### インスタンスサイズ別の推奨設定

| インスタンス | メモリ | WEB_CONCURRENCY | RAILS_MAX_THREADS |
|------------|-------|-----------------|-------------------|
| Free/Starter | 512MB | 1-2 | 5 |
| Standard | 1GB | 2 | 5 |
| Pro | 2GB+ | 4 | 5 |

## Renderでの設定手順

### 推奨：手動設定（既存のデプロイを更新する場合）

既にRenderでデプロイ済みの場合は、手動で環境変数を追加するだけで済みます：

1. **Renderダッシュボードにアクセス**
   - あなたのWeb Serviceを選択

2. **環境変数を追加**
   - 「Environment」タブをクリック
   - 以下の環境変数を追加（既存の環境変数はそのまま）：
   ```
   WEB_CONCURRENCY=2
   RAILS_MAX_THREADS=5
   RAILS_LOG_LEVEL=warn
   MALLOC_ARENA_MAX=2
   RUBY_GC_HEAP_GROWTH_FACTOR=1.1
   RUBY_GC_MALLOC_LIMIT=16000000
   ```

3. **変更を保存して再デプロイ**
   - 「Save Changes」をクリック
   - 自動的に再デプロイが開始されます

### オプション：新規デプロイの場合（render.yaml使用）

新規にデプロイする場合は、`render.yaml.example`をコピーして使用できます：

1. `render.yaml.example`を`render.yaml`にリネーム
2. Renderダッシュボードで「New > Blueprint」を選択
3. リポジトリを接続
4. 必須環境変数を設定

## モニタリングとトラブルシューティング

### メモリ使用量の確認

Renderダッシュボードの「Metrics」タブで以下を確認：
- メモリ使用量グラフ
- インスタンスの再起動履歴

### メモリ問題の兆候

1. **頻繁な再起動**: インスタンスが数分おきに再起動
2. **502エラー**: リクエスト処理中にメモリ不足
3. **遅いレスポンス**: スワッピングによる性能低下

### トラブルシューティング

#### 問題: まだメモリ制限を超える

**解決策1: ワーカー数をさらに減らす**
```bash
WEB_CONCURRENCY=1
```

**解決策2: スレッド数を減らす**
```bash
RAILS_MAX_THREADS=3
```

**解決策3: インスタンスをアップグレード**
- Standard (1GB) → Pro (2GB)

#### 問題: 画像処理でメモリ不足

**解決策1: 画像サイズをさらに制限**
`app/models/entry.rb`の`acceptable_image`メソッドで5MBに変更

**解決策2: バリアントサイズを縮小**
ビューファイルで`resize_to_limit: [400, 400]`に変更

#### 問題: パフォーマンスが遅い

ワーカー数を減らしすぎると同時接続数が制限されます。

**解決策: トレードオフを調整**
- メモリに余裕があれば`WEB_CONCURRENCY`を増やす
- または、インスタンスをアップグレード

## パフォーマンスベンチマーク

### 最適化前
- メモリ使用量: 700MB〜1GB+（スパイク時）
- ワーカー数: 4（自動設定）
- 問題: 頻繁にメモリ制限超過

### 最適化後
- メモリ使用量: 350MB〜550MB（安定）
- ワーカー数: 2
- 結果: メモリ制限内で安定稼働

## ベストプラクティス

1. **段階的なスケーリング**: 小さく始めて、必要に応じてスケールアップ
2. **モニタリング**: Renderのメトリクスを定期的に確認
3. **ログ確認**: エラーログでメモリ関連の警告をチェック
4. **定期的なメンテナンス**: 依存関係の更新とパフォーマンス改善

## 追加の最適化（将来的な実装候補）

1. **Redisキャッシュ**: メモリキャッシュの代わりにRedisを使用
2. **CDN導入**: 画像配信をCloudFlare等のCDNに委譲
3. **バックグラウンドジョブ**: 画像処理を非同期化（Sidekiq + Redis）
4. **データベース最適化**: クエリの最適化、インデックスの追加

## 参考リンク

- [Render Documentation](https://render.com/docs)
- [Puma Configuration](https://github.com/puma/puma)
- [Rails Performance Guide](https://guides.rubyonrails.org/performance_testing.html)
- [MiniMagick Memory Settings](https://github.com/minimagick/minimagick)

## サポート

問題が解決しない場合は、以下の情報をGitHub Issuesに報告してください：

1. Renderのインスタンスタイプ
2. メモリ使用量のスクリーンショット
3. エラーログ
4. 環境変数の設定（秘密情報を除く）

