# MyDictionary 実装チェックリスト

## Phase 1: データベース・モデル基盤

### 1.1 マイグレーション
- [ ] `rails g model Vocabulary word:string meaning:text mastered:boolean favorited:boolean user:references` を実行
- [ ] マイグレーションファイルを編集
  - [ ] `word` に `null: false` を追加
  - [ ] `meaning` に `null: false` を追加
  - [ ] `mastered` に `default: false, null: false` を追加
  - [ ] `favorited` に `default: false, null: false` を追加
  - [ ] ユニークインデックス `[:user_id, :word]` を追加
- [ ] `rails g model EntryVocabulary entry:references vocabulary:references` を実行
- [ ] マイグレーションファイルを編集
  - [ ] ユニークインデックス `[:entry_id, :vocabulary_id]` を追加
- [ ] `rails db:migrate` を実行
- [ ] `RAILS_ENV=test rails db:migrate` を実行

### 1.2 Vocabularyモデル
- [ ] `app/models/vocabulary.rb` を編集
  - [ ] `belongs_to :user` を確認
  - [ ] `has_many :entry_vocabularies, dependent: :destroy` を追加
  - [ ] `has_many :entries, through: :entry_vocabularies` を追加
  - [ ] バリデーション追加
    - [ ] `validates :word, presence: true, length: { maximum: 255 }, uniqueness: { scope: :user_id }`
    - [ ] `validates :meaning, presence: true`
  - [ ] スコープ追加
    - [ ] `scope :recent, -> { order(created_at: :desc) }`
    - [ ] `scope :alphabetical, -> { order(:word) }`
    - [ ] `scope :mastered, -> { where(mastered: true) }`
    - [ ] `scope :unmastered, -> { where(mastered: false) }`
    - [ ] `scope :favorited, -> { where(favorited: true) }`
    - [ ] `scope :search_by_word, ->(keyword) { where('word LIKE ?', "%#{keyword}%") if keyword.present? }`
  - [ ] メソッド追加
    - [ ] `toggle_mastered!`
    - [ ] `toggle_favorited!`

### 1.3 EntryVocabularyモデル
- [ ] `app/models/entry_vocabulary.rb` を編集
  - [ ] `belongs_to :entry` を確認
  - [ ] `belongs_to :vocabulary` を確認
  - [ ] バリデーション: `validates :entry_id, uniqueness: { scope: :vocabulary_id }` を追加

### 1.4 既存モデル更新
- [ ] `app/models/user.rb` に追加
  - [ ] `has_many :vocabularies, dependent: :destroy`
- [ ] `app/models/entry.rb` に追加
  - [ ] `has_many :entry_vocabularies, dependent: :destroy`
  - [ ] `has_many :vocabularies, through: :entry_vocabularies`

---

## Phase 2: ルーティング・コントローラー

### 2.1 ルーティング
- [ ] `config/routes.rb` を編集
  - [ ] `resources :vocabularies` を追加
  - [ ] collection ルート追加
    - [ ] `get :flashcard`
    - [ ] `post :add_from_entry`
  - [ ] member ルート追加
    - [ ] `patch :toggle_mastered`
    - [ ] `patch :toggle_favorited`

### 2.2 VocabulariesController作成
- [ ] `rails g controller Vocabularies` を実行
- [ ] `app/controllers/vocabularies_controller.rb` を編集
  - [ ] `before_action :authenticate_user!` を追加
  - [ ] `before_action :set_vocabulary` を追加（show, edit, update, destroy, toggle用）
  - [ ] アクション実装
    - [ ] `index` - 一覧表示（検索・フィルタリング付き）
    - [ ] `flashcard` - フラッシュカード画面
    - [ ] `new` - 新規作成フォーム
    - [ ] `create` - 単語作成
    - [ ] `add_from_entry` - Ajax単語追加（JSON）
    - [ ] `edit` - 編集フォーム
    - [ ] `update` - 単語更新
    - [ ] `destroy` - 単語削除
    - [ ] `toggle_mastered` - 習得済みトグル（JSON）
    - [ ] `toggle_favorited` - お気に入りトグル（JSON）
  - [ ] private メソッド
    - [ ] `set_vocabulary`
    - [ ] `vocabulary_params`

---

## Phase 3: ビュー実装

### 3.1 レイアウト更新
- [ ] `app/views/layouts/application.html.erb` を編集
  - [ ] ヘッダーに `<nav class="header-nav">` を追加
  - [ ] `link_to "📚 MyDictionary", vocabularies_path` を追加

### 3.2 単語一覧ページ
- [ ] `app/views/vocabularies/index.html.erb` を作成
  - [ ] ページタイトル
  - [ ] 検索バー（`data-controller="vocabulary-filter"`）
  - [ ] フィルターボタン（全て/未習得/習得済み/お気に入り）
  - [ ] アクションボタン
    - [ ] 「新しい単語を追加」ボタン（new_vocabulary_path）
    - [ ] フラッシュカードリンク
  - [ ] 単語カードグリッド
    - [ ] 各カードに単語、意味、バッジ、編集/削除ボタン
    - [ ] 日記リンク（日記に紐づいている場合のみ表示）
    - [ ] 「日記に紐づいていません」メッセージ（紐づいていない場合）
  - [ ] ページネーション（Kaminari使用）

### 3.3 フラッシュカードページ
- [ ] `app/views/vocabularies/flashcard.html.erb` を作成
  - [ ] ページタイトル
  - [ ] モード切り替えボタン（英→日 / 日→英）
  - [ ] 進捗表示
  - [ ] フラッシュカード要素（`data-controller="flashcard"`）
  - [ ] コントロールボタン（前へ/習得済み/次へ）
  - [ ] 一覧に戻るリンク

### 3.4 単語編集ページ
- [ ] `app/views/vocabularies/edit.html.erb` を作成
  - [ ] フォーム（`form_with model: @vocabulary`）
  - [ ] 単語フィールド（readonly）
  - [ ] 意味フィールド（textarea）
  - [ ] 習得済みチェックボックス
  - [ ] お気に入りチェックボックス
  - [ ] キャンセル/更新ボタン

### 3.5 単語新規作成ページ
- [ ] `app/views/vocabularies/new.html.erb` を作成
  - [ ] フォーム（`form_with model: @vocabulary`）
  - [ ] 単語フィールド
  - [ ] 意味フィールド
  - [ ] キャンセル/登録ボタン

### 3.6 日記詳細ページ更新
- [ ] `app/views/entries/show.html.erb` を編集
  - [ ] 英語本文セクションに `data-controller="word-selector"` を追加
  - [ ] `data-word-selector-entry-id-value` を設定
  - [ ] 登録済み単語の表示セクションを追加
  - [ ] 単語登録モーダルを追加
    - [ ] フォーム（単語・意味入力）
    - [ ] 成功メッセージ表示エリア（`successMessage` target）
    - [ ] 閉じる/登録ボタン
    - [ ] ヒントメッセージ（連続登録可能であることを説明）

---

## Phase 4: CSS実装

### 4.1 vocabularies.css作成
- [ ] `app/assets/stylesheets/vocabularies.css` を作成
  - [ ] 単語一覧ページのスタイル
    - [ ] `.vocabularies-container`
    - [ ] `.vocabulary-search`
    - [ ] `.vocabulary-filters`
    - [ ] `.vocabulary-grid`
    - [ ] `.vocabulary-card`
    - [ ] `.badge-mastered`, `.badge-favorited`
  - [ ] フラッシュカードのスタイル
    - [ ] `.flashcard-container`
    - [ ] `.flashcard`（3D回転アニメーション）
    - [ ] `.flashcard-controls`
  - [ ] モーダルのスタイル
    - [ ] `.modal`
    - [ ] `.modal-content`
    - [ ] アニメーション（fadeIn, slideIn）
  - [ ] レスポンシブデザイン（@media queries）

### 4.2 header.css更新
- [ ] `app/assets/stylesheets/header.css` を編集
  - [ ] `.header-nav` スタイルを追加
  - [ ] ナビゲーションリンクのスタイル

---

## Phase 5: JavaScript/Stimulus実装

### 5.1 word_selector_controller.js
- [ ] `app/javascript/controllers/word_selector_controller.js` を作成
  - [ ] Stimulus コントローラー定義
  - [ ] values: `{ entryId: Number }`
  - [ ] targets: `["modal", "wordInput", "meaningInput", "form", "successMessage", "submitButton"]`
  - [ ] connect() - 初期化、テキスト選択イベント設定
  - [ ] selectWord() - 単語選択時の処理
  - [ ] openModal() - モーダルを開く
  - [ ] closeModal() - モーダルを閉じる、成功メッセージをクリア
  - [ ] submitWord() - Ajax で単語を登録（entry_idはオプショナル）
  - [ ] handleSuccess() - 登録成功時の処理
    - [ ] 成功メッセージを表示
    - [ ] meaningInputをクリア
    - [ ] モーダルは開いたまま（連続登録可能）
  - [ ] handleError() - エラー時の処理

### 5.2 flashcard_controller.js
- [ ] `app/javascript/controllers/flashcard_controller.js` を作成
  - [ ] Stimulus コントローラー定義
  - [ ] values: `{ vocabularies: Array }`
  - [ ] targets: `["card", "frontText", "backText", "currentIndex", "totalCount", "masteredBtn", "masteredText", "prevBtn", "nextBtn", "modeBtn"]`
  - [ ] connect() - 初期化、最初の単語を表示
  - [ ] switchMode() - モード切り替え（英→日 / 日→英）
  - [ ] flipCard() - カードをフリップ
  - [ ] nextCard() - 次の単語へ
  - [ ] prevCard() - 前の単語へ
  - [ ] updateCard() - カードの表示を更新
  - [ ] toggleMastered() - 習得済みトグル（Ajax）
  - [ ] updateButtons() - ボタンの状態を更新

### 5.3 vocabulary_filter_controller.js
- [ ] `app/javascript/controllers/vocabulary_filter_controller.js` を作成
  - [ ] Stimulus コントローラー定義
  - [ ] targets: `["searchInput", "grid"]`
  - [ ] search() - リアルタイム検索
  - [ ] filter() - フィルタリング（クライアントサイド）
  - [ ] showCard() / hideCard() - カードの表示/非表示

### 5.4 index.jsに登録
- [ ] `app/javascript/controllers/index.js` を編集
  - [ ] `word_selector_controller` をインポート
  - [ ] `flashcard_controller` をインポート
  - [ ] `vocabulary_filter_controller` をインポート

---

## Phase 6: テスト実装

### 6.1 FactoryBot
- [ ] `spec/factories/vocabularies.rb` を作成
  - [ ] 基本ファクトリ
  - [ ] trait `:mastered`
  - [ ] trait `:favorited`
- [ ] `spec/factories/entry_vocabularies.rb` を作成

### 6.2 モデルテスト
- [ ] `spec/models/vocabulary_spec.rb` を作成
  - [ ] 関連付けのテスト
  - [ ] バリデーションのテスト
  - [ ] スコープのテスト
  - [ ] メソッドのテスト（toggle_mastered!, toggle_favorited!）
- [ ] `spec/models/entry_vocabulary_spec.rb` を作成
  - [ ] 関連付けのテスト
  - [ ] バリデーションのテスト

### 6.3 リクエストテスト
- [ ] `spec/requests/vocabularies_spec.rb` を作成
  - [ ] `GET /vocabularies` - 一覧表示
  - [ ] `GET /vocabularies/:id` - 詳細表示
  - [ ] `GET /vocabularies/new` - 新規作成フォーム
  - [ ] `POST /vocabularies` - 作成
  - [ ] `POST /vocabularies/add_from_entry` - Ajax追加
  - [ ] `GET /vocabularies/:id/edit` - 編集フォーム
  - [ ] `PATCH /vocabularies/:id` - 更新
  - [ ] `DELETE /vocabularies/:id` - 削除
  - [ ] `PATCH /vocabularies/:id/toggle_mastered` - 習得済みトグル
  - [ ] `PATCH /vocabularies/:id/toggle_favorited` - お気に入りトグル
  - [ ] `GET /vocabularies/flashcard` - フラッシュカード
  - [ ] 認証のテスト
  - [ ] 認可のテスト（他ユーザーの単語へのアクセス）

---

## Phase 7: 統合・テスト・調整

### 7.1 動作確認
- [ ] ローカル環境でサーバー起動（`rails s`）
- [ ] 単語一覧ページにアクセスできる
- [ ] 「新しい単語を追加」ボタンから単語を追加できる（日記に紐づかない）
- [ ] 日記ページで単語を選択してモーダルが開く
- [ ] 日記ページから単語を登録できる（日記に自動的に関連付けられる）
- [ ] 日記ページで複数の単語を連続して登録できる（モーダルが開いたまま）
- [ ] 成功メッセージが表示される
- [ ] 検索機能が動作する
- [ ] フィルター機能が動作する
- [ ] 単語を編集できる（単語・意味とも編集可能）
- [ ] 単語を削除できる
- [ ] 日記に紐づいていない単語が「日記に紐づいていません」と表示される
- [ ] 日記に紐づいている単語には日記リンク（「単語 ： 意味」形式）が表示される
- [ ] 日記のヘッダーがスティッキー表示され、スクロールしても見える
- [ ] 既存単語を選択すると「単語を編集」モードになり、意味が自動入力される
- [ ] モーダル登録後、自動的に閉じてトースト通知が表示される
- [ ] フラッシュカードページにアクセスできる
- [ ] カードがフリップする（クリック、キーボード操作）
- [ ] 英→日/日→英モードが切り替わる
- [ ] 習得済みマークが切り替わる
- [ ] お気に入りマークが切り替わる
- [ ] 前の単語へ/次の単語へボタンが動作する

### 7.2 レスポンシブ対応確認
- [ ] スマートフォン表示
- [ ] タブレット表示
- [ ] PC表示

### 7.3 パフォーマンス確認
- [ ] N+1問題がないか確認（bullet gem使用）
- [ ] 大量データでの動作確認（100件以上の単語）

### 7.4 テスト実行
- [ ] `bundle exec rspec` で全テストをパス
- [ ] カバレッジ確認（simplecov）

---

## Phase 8: 最終調整・ドキュメント

### 8.1 コードレビュー
- [ ] コードの可読性チェック
- [ ] 重複コードの削除
- [ ] コメントの追加（複雑な処理）

### 8.2 README更新
- [ ] MyDictionary機能の説明を追加
- [ ] 使い方のスクリーンショット追加

### 8.3 マイグレーションのバックアップ
- [ ] マイグレーションファイルを確認
- [ ] rollback が正常に動作するか確認

---

## オプション機能（将来的な拡張）

- [ ] 単語のエクスポート機能（CSV）
- [ ] 学習統計ページ
- [ ] 定期的な復習リマインダー
- [ ] 音声読み上げ機能
- [ ] AIによる単語の自動抽出・提案
- [ ] 単語帳の共有機能
- [ ] スペースド・リピティション（間隔反復）アルゴリズム

---

## トラブルシューティング

### よくある問題と解決方法

1. **マイグレーションエラー**
   - `rails db:rollback` で巻き戻し
   - マイグレーションファイルを修正
   - 再度 `rails db:migrate`

2. **Ajax通信が動作しない**
   - CSRFトークンが送信されているか確認
   - ブラウザのコンソールでエラー確認
   - サーバーログでエラー確認

3. **Stimulusコントローラーが動作しない**
   - `data-controller` 属性が正しいか確認
   - `index.js` にコントローラーが登録されているか確認
   - ブラウザのコンソールでエラー確認

4. **スタイルが適用されない**
   - CSSファイルが `application.css` にインポートされているか確認
   - ブラウザのキャッシュをクリア
   - `rails assets:precompile` を実行（本番環境）

5. **テストが失敗する**
   - `RAILS_ENV=test rails db:migrate` を実行
   - `rails db:test:prepare` を実行
   - FactoryBotの定義を確認

