# Active Storage の設定
Rails.application.config.after_initialize do
  # 画像処理時のメモリ使用量を制限
  if defined?(MiniMagick)
    # MiniMagickのメモリ制限とディスク制限を設定
    MiniMagick.configure do |config|
      # メモリの使用量を256MBに制限
      config.cli_options = {
        'limit' => {
          'memory' => '256MiB',
          'map' => '512MiB',
          'disk' => '1GiB'
        }
      }
      # タイムアウトを30秒に設定
      config.timeout = 30
    end
  end
  
  # Active Storageのバリデーション（ファイルサイズ制限）
  # Entryモデルにバリデーションを追加
  Rails.application.config.active_storage.content_types_allowed_inline = %w[
    image/png
    image/jpg
    image/jpeg
    image/gif
    image/webp
  ]
  
  # 本番環境では画像処理をバックグラウンドで実行（オプション）
  # Rails.application.config.active_storage.queues.analysis = :default
  # Rails.application.config.active_storage.queues.purge = :default
end

