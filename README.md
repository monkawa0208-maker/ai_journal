# AI Journal

## アプリケーション概要
英語学習法のひとつに、その日の出来事や感情・考えを英語で書き出す “ジャーナリング” があります。
語彙力や文法力の向上、アウトプット習慣の定着に効果的で、継続することでスピーキング時にも自然と英語が出てくるようになります。

AI Journalは、このジャーナリングをAIの力でサポートする英語学習アプリです。
日々の出来事を英語で投稿すると、AIが文法の誤りや不自然な表現を指摘し、より自然で伝わる英文を提案してくれます。

「いきなり英語で書くのは難しい」というユーザーのために、日本語で下書きし、AIが英文を提案する機能も搭載しています。
また、学習した単語や表現を登録できるMy Dictionary機能では、日記と単語が自動的に紐づくため、自分の文章がそのまま例文になります。
単語ごとに「修得済み」「お気に入り」を設定して管理でき、フラッシュカード形式で効率的に復習することも可能です。

「せっかく学んだ英語を使う機会がない」
「英文の添削を受ける機会がない」
「書きたい内容を英語で表現できない」
「覚えた単語が定着しない」
——そんな悩みを解決するために、AI Journalを開発しました。


## URL
https://ai-journal-k7ua.onrender.com

## テスト用アカウント
### Basic認証
- **ID**: admin
- **パスワード**: 2222

### ログイン情報
- **メールアドレス**: test@example.com
- **パスワード**: password

※ログインせずにトップページから新規登録も可能です。

## 利用方法
1. トップページの「新規登録」ボタンからアカウントを作成する（またはテスト用アカウントでログイン）
2. 「新規日記作成」ボタンをクリックし、英語で日記を書く
   - 日本語で書いて「翻訳」ボタンをクリックすると英語に自動翻訳される
   - 「AIプレビュー」ボタンで投稿前にAIのフィードバックを確認できる
3. 日記を投稿すると、AIが英文の誤りを指摘し、より良い表現を提案してくれる
4. 日記の中で覚えたい単語をダブルクリックして単語帳に登録する
5. 「My Dictionary」ページで単語を管理し、フラッシュカードで学習する
6. カレンダービューで過去の投稿履歴を視覚的に確認できる

## アプリケーションを作成した背景
英語学習において、特にライティングスキルの向上には「書く → 添削を受ける → 改善する」というサイクルが重要です。しかし、個人で学習している場合、以下のような課題がありました：

- **フィードバックを得る機会が少ない**: 独学では自分の英文が正しいのか判断できず、間違いに気づきにくい
- **継続が難しい**: 学習の習慣化が難しく、三日坊主になりがち
- **語彙力の定着が不十分**: 新しい単語を学んでも、復習する仕組みがないため忘れてしまう
- **翻訳の手間**: 英語で考えることのハードルが高く、日本語で考えた内容を英語にするのに時間がかかる

このような課題を抱える英語学習者に対して、AIの力を活用することで、即座に質の高いフィードバックを提供し、継続的な学習をサポートし、体系的な語彙学習を実現するアプリケーションを開発しました。

## 実装した機能についての画像やGIFおよびその説明
※別途記載予定

## 実装予定の機能
- **タグ機能**: 日記をカテゴリー別に分類・管理できる機能
- **日記の公開機能**: 他のユーザーと日記を共有し、いいねやコメントをもらえる機能
- **詳細な統計・分析機能**: 学習の進捗をグラフで可視化し、弱点を分析する機能
- **音声入力機能**: マイクから英語を吹き込んで日記を作成できる機能
- **単語テスト機能**: 習得度を測定するための小テスト機能

## データベース設計
[![ER図](er.dio)](er.dio)

### 主要テーブル

#### users（ユーザー）
| Column             | Type   | Options     |
| ------------------ | ------ | ----------- |
| nickname           | string | null: false |
| email              | string | null: false, unique: true |
| encrypted_password | string | null: false |

**Association**
- has_many :entries
- has_many :vocabularies

#### entries（日記）
| Column       | Type       | Options     |
| ------------ | ---------- | ----------- |
| user_id      | references | null: false, foreign_key: true |
| title        | string     | null: false |
| content      | text       | null: false |
| content_ja   | text       |             |
| ai_translate | text       |             |
| response     | text       |             |
| posted_on    | date       | null: false |

**Association**
- belongs_to :user
- has_many :entry_vocabularies
- has_many :vocabularies, through: :entry_vocabularies
- has_one_attached :image

**Unique Index**: [user_id, posted_on]（1日1件制約）

#### vocabularies（単語）
| Column    | Type       | Options     |
| --------- | ---------- | ----------- |
| user_id   | references | null: false, foreign_key: true |
| word      | string     | null: false |
| meaning   | text       | null: false |
| mastered  | boolean    | default: false, null: false |
| favorited | boolean    | default: false, null: false |

**Association**
- belongs_to :user
- has_many :entry_vocabularies
- has_many :entries, through: :entry_vocabularies

**Unique Index**: [user_id, word]（ユーザーごとに単語は一意）

#### entry_vocabularies（日記と単語の中間テーブル）
| Column        | Type       | Options     |
| ------------- | ---------- | ----------- |
| entry_id      | references | null: false, foreign_key: true |
| vocabulary_id | references | null: false, foreign_key: true |

**Association**
- belongs_to :entry
- belongs_to :vocabulary

## 画面遷移図
※別途記載予定

## 開発環境
- **言語**: Ruby 3.2.0
- **フレームワーク**: Ruby on Rails 7.1.0
- **フロントエンド**: Hotwire (Turbo + Stimulus), JavaScript, HTML/CSS
- **データベース**: MySQL 8.0（開発環境）, PostgreSQL（本番環境）
- **認証**: Devise
- **外部API**: OpenAI API (GPT-4o-mini)
- **テスト**: RSpec, FactoryBot, Capybara, Selenium WebDriver
- **その他**: FullCalendar, Kaminari, Active Storage, ImageProcessing, MiniMagick
- **インフラ**: Render
- **バージョン管理**: Git / GitHub

## ローカルでの動作方法
```bash
# リポジトリをクローン
git clone https://github.com/yourusername/ai_journal.git
cd ai_journal

# 依存関係をインストール
bundle install

# データベースの作成とマイグレーション
rails db:create
rails db:migrate

# 環境変数の設定
# `OPENAI_API_KEY`: OpenAI APIキー（必須）
# `BASIC_AUTH_USER`: Basic認証のユーザー名（本番環境用）
# `BASIC_AUTH_PASSWORD`: Basic認証のパスワード（本番環境用）

# サーバーの起動
rails server

# ブラウザで http://localhost:3000 にアクセス
```

## 工夫したポイント

### 1. AI機能の実用性と信頼性
- **プレビュー機能**: 投稿前にAIのフィードバックを確認できる機能を実装し、ユーザーが安心して投稿できるようにしました
- **エラーハンドリング**: OpenAI APIの障害時にも適切なエラーメッセージを表示し、ユーザー体験を損なわないようにしました
- **プロンプトの最適化**: 学習者に寄り添った励ましのフィードバックを生成するようプロンプトを工夫しました

### 2. 学習継続を促す仕組み
- **1日1件ルール**: データベースに一意制約を設け、1日1件の日記投稿を促すことで学習習慣の定着を支援
- **ストリーク機能**: 連続投稿日数を可視化し、ゲーミフィケーション要素を取り入れました
- **達成度表示**: 投稿数に応じた学習レベルと励ましメッセージで、モチベーションを維持できるようにしました

### 3. 語彙学習の最適化
- **日記から直接登録**: ダブルクリックで単語を登録できる機能により、文脈と共に単語を学習できます
- **フラッシュカード**: インタラクティブなフラッシュカードで効果的な復習を実現
- **柔軟な管理**: 習得状態とお気に入り機能で、自分に合った学習ができます

### 4. コード品質と保守性
- **サービスレイヤーパターン**: ビジネスロジックをサービスクラスに分離し、コントローラーをシンプルに保ちました
- **包括的なテスト**: 266個のテストを記述し、テストカバレッジを高めました（モデル57個、サービス114個、リクエスト82個、システム11個）
- **DRY原則**: 共通処理をモジュール化し、保守しやすいコードを心がけました

### 5. ユーザビリティとアクセシビリティ
- **Hotwire（Turbo + Stimulus）**: ページ遷移なしでスムーズなユーザー体験を実現

- **直感的なUI**: ユーザーが迷わず操作できるシンプルで分かりやすいインターフェース


## 改善点
### より改善するとしたら
1. **パフォーマンス最適化**
   - N+1問題の解消（includes/joinsの活用）
   - データベースクエリのさらなる最適化
   - キャッシング機構の導入（Redis等）

2. **AI機能の拡張**
   - レスポンスのストリーミング表示（リアルタイムで生成される様子を表示）
   - ユーザーの学習レベルに応じたフィードバックの難易度調整
   - 固定化されたプロンプトではなく、ユーザーが任意のプロンプトで質問できる機能を実装

3. **ソーシャル機能の実装**
   - 他のユーザーとの交流機能（フォロー、コメント、いいね）
   - 学習グループやコミュニティ機能

4. **分析機能の強化**
   - 日記投稿頻度の可視化（グラフ、チャート）
   - よく使う表現や文法の分析
   - ユーザーのよくする英文ミスパターンの分析

5. **モバイルアプリ化**
   - React Nativeやフラッターを使用したネイティブアプリ開発
   - プッシュ通知による学習リマインダー
   - オフライン対応

## 制作時間
約180時間（約3週間）

### 内訳
- 要件定義・設計: 20時間
- データベース設計: 10時間
- 基本機能実装（日記CRUD、認証）: 35時間
- AI機能実装（翻訳、フィードバック）: 35時間
- My Dictionary機能実装: 30時間
- テスト作成: 15時間
- デプロイ・調整: 15時間
- その他（必要技術のキャッチアップ、README作成 等）: 20時間