# MyDictionary API設計書

## 1. ルーティング

### 1.1 routes.rb

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  root "entries#index"
  
  resources :entries do
    post :generate_feedback, on: :member
    post :translate, on: :collection
    post :preview_feedback, on: :collection
  end

  # MyDictionary機能
  resources :vocabularies do
    collection do
      get :flashcard              # フラッシュカード復習ページ
      post :add_from_entry        # 日記から単語を追加（Ajax）
    end
    member do
      patch :toggle_mastered      # 習得済みトグル（Ajax）
      patch :toggle_favorited     # お気に入りトグル（Ajax）
    end
  end
end
```

### 1.2 ルート一覧

```
GET    /vocabularies                    vocabularies#index
POST   /vocabularies                    vocabularies#create
GET    /vocabularies/new                vocabularies#new
GET    /vocabularies/flashcard          vocabularies#flashcard
POST   /vocabularies/add_from_entry     vocabularies#add_from_entry
GET    /vocabularies/:id/edit           vocabularies#edit
GET    /vocabularies/:id                vocabularies#show
PATCH  /vocabularies/:id                vocabularies#update
DELETE /vocabularies/:id                vocabularies#destroy
PATCH  /vocabularies/:id/toggle_mastered    vocabularies#toggle_mastered
PATCH  /vocabularies/:id/toggle_favorited   vocabularies#toggle_favorited
```

---

## 2. コントローラー設計

### 2.1 VocabulariesController

```ruby
# app/controllers/vocabularies_controller.rb
class VocabulariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vocabulary, only: [:show, :edit, :update, :destroy, :toggle_mastered, :toggle_favorited]

  # GET /vocabularies
  # 単語一覧ページ
  def index
    @vocabularies = current_user.vocabularies
                                 .includes(:entries)
                                 .recent

    # 検索パラメータがある場合
    if params[:search].present?
      @vocabularies = @vocabularies.search_by_word(params[:search])
    end

    # フィルタリング
    case params[:filter]
    when 'mastered'
      @vocabularies = @vocabularies.mastered
    when 'unmastered'
      @vocabularies = @vocabularies.unmastered
    when 'favorited'
      @vocabularies = @vocabularies.favorited
    end

    respond_to do |format|
      format.html do
        @vocabularies = @vocabularies.page(params[:page]).per(20)
      end
      format.json do
        # JSON形式の場合はページネーションなしで全件返す（検索用）
        render json: { vocabularies: @vocabularies.as_json(only: [:id, :word, :meaning, :mastered, :favorited]) }
      end
    end
  end

  # GET /vocabularies/flashcard
  # フラッシュカード復習ページ
  def flashcard
    @vocabularies = current_user.vocabularies.recent
    
    # フィルタリング（未習得のみなど）
    if params[:filter] == 'unmastered'
      @vocabularies = @vocabularies.unmastered
    end

    redirect_to vocabularies_path, alert: '復習する単語がありません' if @vocabularies.empty?
  end

  # GET /vocabularies/:id
  # 単語詳細ページ（必要に応じて実装）
  def show
  end

  # GET /vocabularies/new
  # 単語追加フォーム
  def new
    @vocabulary = current_user.vocabularies.build
    @entry_id = params[:entry_id]
  end

  # POST /vocabularies
  # 単語登録（通常フォーム）
  def create
    @vocabulary = current_user.vocabularies.build(vocabulary_params)

    if @vocabulary.save
      # 日記との関連付け
      if params[:entry_id].present?
        entry = current_user.entries.find(params[:entry_id])
        @vocabulary.entries << entry unless @vocabulary.entries.include?(entry)
      end

      redirect_to vocabularies_path, notice: '単語を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # POST /vocabularies/add_from_entry (Ajax)
  # 日記ページから単語を追加
  def add_from_entry
    word = params[:word]&.strip&.downcase
    meaning = params[:meaning]&.strip
    entry_id = params[:entry_id]

    unless word.present? && meaning.present?
      render json: { error: '単語と意味が必要です' }, status: :unprocessable_entity
      return
    end

    # 既存の単語を検索、なければ新規作成
    @vocabulary = current_user.vocabularies.find_or_initialize_by(word: word)
    
    if @vocabulary.new_record?
      @vocabulary.meaning = meaning
      unless @vocabulary.save
        render json: { error: @vocabulary.errors.full_messages.join(', ') }, status: :unprocessable_entity
        return
      end
    else
      # 既存の単語の場合は意味を更新しない（ユーザーが既に登録済み）
    end

    # 日記との関連付け（entry_idがある場合のみ）
    if entry_id.present?
      entry = current_user.entries.find(entry_id)
      unless @vocabulary.entries.include?(entry)
        @vocabulary.entries << entry
      end
    end

    render json: { 
      success: true, 
      vocabulary: @vocabulary.as_json(include: :entries),
      message: '単語を登録しました'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: '日記が見つかりません' }, status: :not_found
  end

  # GET /vocabularies/:id/edit
  # 単語編集フォーム
  def edit
  end

  # PATCH /vocabularies/:id
  # 単語更新
  def update
    if @vocabulary.update(vocabulary_params)
      redirect_to vocabularies_path, notice: '単語を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /vocabularies/:id
  # 単語削除
  def destroy
    @vocabulary.destroy
    redirect_to vocabularies_path, notice: '単語を削除しました'
  end

  # PATCH /vocabularies/:id/toggle_mastered (Ajax)
  # 習得済みフラグをトグル
  def toggle_mastered
    @vocabulary.toggle_mastered!
    render json: { success: true, mastered: @vocabulary.mastered }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH /vocabularies/:id/toggle_favorited (Ajax)
  # お気に入りフラグをトグル
  def toggle_favorited
    @vocabulary.toggle_favorited!
    render json: { success: true, favorited: @vocabulary.favorited }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_vocabulary
    @vocabulary = current_user.vocabularies.find(params[:id])
  end

  def vocabulary_params
    params.require(:vocabulary).permit(:word, :meaning, :mastered, :favorited)
  end
end
```

---

## 3. APIエンドポイント詳細

### 3.1 GET /vocabularies (一覧取得)

**リクエスト:**
```
GET /vocabularies?search=grat&filter=unmastered&page=1
```

**パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| search | string | No | 単語検索キーワード |
| filter | string | No | フィルター（mastered/unmastered/favorited） |
| page | integer | No | ページ番号 |

**レスポンス（HTML）:**
通常のビューをレンダリング

---

### 3.2 POST /vocabularies/add_from_entry (Ajax単語追加)

**リクエスト:**
```javascript
POST /vocabularies/add_from_entry
Content-Type: application/json

{
  "word": "grateful",
  "meaning": "感謝している、ありがたい",
  "entry_id": 123
}
```

**パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| word | string | Yes | 英単語 |
| meaning | text | Yes | 日本語の意味 |
| entry_id | integer | No | 日記ID（指定すると日記と関連付け） |

**レスポンス（成功時）:**
```json
{
  "success": true,
  "vocabulary": {
    "id": 45,
    "word": "grateful",
    "meaning": "感謝している、ありがたい",
    "mastered": false,
    "favorited": false,
    "user_id": 1,
    "entries": [
      {
        "id": 123,
        "title": "Today's Diary",
        "posted_on": "2025-10-17"
      }
    ]
  },
  "message": "単語を登録しました"
}
```

**レスポンス（エラー時）:**
```json
{
  "error": "単語と意味が必要です"
}
```

または

```json
{
  "error": "日記が見つかりません"
}
```

**ステータスコード:**
- 200: 成功
- 404: 日記が見つからない
- 422: バリデーションエラー

---

### 3.3 PATCH /vocabularies/:id/toggle_mastered (習得済みトグル)

**リクエスト:**
```javascript
PATCH /vocabularies/45/toggle_mastered
Content-Type: application/json
```

**レスポンス（成功時）:**
```json
{
  "success": true,
  "mastered": true
}
```

**レスポンス（エラー時）:**
```json
{
  "error": "エラーメッセージ"
}
```

**ステータスコード:**
- 200: 成功
- 404: 単語が見つからない
- 422: 更新エラー

---

### 3.4 PATCH /vocabularies/:id/toggle_favorited (お気に入りトグル)

**リクエスト:**
```javascript
PATCH /vocabularies/45/toggle_favorited
Content-Type: application/json
```

**レスポンス（成功時）:**
```json
{
  "success": true,
  "favorited": true
}
```

**レスポンス（エラー時）:**
```json
{
  "error": "エラーメッセージ"
}
```

**ステータスコード:**
- 200: 成功
- 404: 単語が見つからない
- 422: 更新エラー

---

### 3.5 POST /vocabularies (通常の単語作成)

**リクエスト:**
```
POST /vocabularies
Content-Type: application/x-www-form-urlencoded

vocabulary[word]=grateful&vocabulary[meaning]=感謝している&entry_id=123
```

**パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| vocabulary[word] | string | Yes | 英単語 |
| vocabulary[meaning] | text | Yes | 日本語の意味 |
| vocabulary[mastered] | boolean | No | 習得済みフラグ |
| vocabulary[favorited] | boolean | No | お気に入りフラグ |
| entry_id | integer | No | 関連付ける日記ID |

**レスポンス:**
成功時: vocabularies_pathへリダイレクト + フラッシュメッセージ
失敗時: newテンプレートを再表示（422）

---

### 3.6 PATCH /vocabularies/:id (単語更新)

**リクエスト:**
```
PATCH /vocabularies/45
Content-Type: application/x-www-form-urlencoded

vocabulary[meaning]=感謝している、ありがたい&vocabulary[mastered]=true
```

**パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| vocabulary[word] | string | Yes | 英単語 |
| vocabulary[meaning] | text | Yes | 日本語の意味 |
| vocabulary[mastered] | boolean | No | 習得済みフラグ |
| vocabulary[favorited] | boolean | No | お気に入りフラグ |

**レスポンス:**
成功時: vocabularies_pathへリダイレクト + フラッシュメッセージ
失敗時: editテンプレートを再表示（422）

---

### 3.7 DELETE /vocabularies/:id (単語削除)

**リクエスト:**
```
DELETE /vocabularies/45
```

**レスポンス:**
vocabularies_pathへリダイレクト + フラッシュメッセージ

---

### 3.8 GET /vocabularies/flashcard (フラッシュカード)

**リクエスト:**
```
GET /vocabularies/flashcard?filter=unmastered
```

**パラメータ:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| filter | string | No | unmastered（未習得のみ）など |

**レスポンス:**
フラッシュカードページをレンダリング（単語がない場合は一覧へリダイレクト）

---

## 4. エラーハンドリング

### 4.1 共通エラーレスポンス

```ruby
# app/controllers/vocabularies_controller.rb

rescue_from ActiveRecord::RecordNotFound do |e|
  respond_to do |format|
    format.html { redirect_to vocabularies_path, alert: '単語が見つかりませんでした' }
    format.json { render json: { error: '単語が見つかりませんでした' }, status: :not_found }
  end
end

rescue_from ActiveRecord::RecordInvalid do |e|
  respond_to do |format|
    format.html { render :new, status: :unprocessable_entity }
    format.json { render json: { error: e.message }, status: :unprocessable_entity }
  end
end
```

### 4.2 バリデーションエラー

```json
{
  "error": "Validation failed: Word can't be blank, Meaning can't be blank"
}
```

---

## 5. セキュリティ

### 5.1 認証

- 全アクション: `before_action :authenticate_user!`（Devise）

### 5.2 認可

- `set_vocabulary`: `current_user.vocabularies.find(params[:id])`
  - 他ユーザーの単語にはアクセス不可（RecordNotFoundが発生）

### 5.3 Strong Parameters

```ruby
def vocabulary_params
  params.require(:vocabulary).permit(:word, :meaning, :mastered, :favorited)
end
```

### 5.4 CSRF対策

- Railsのデフォルト機能を使用
- Ajaxリクエストでも`csrf_meta_tags`を自動送信

---

## 6. JavaScript連携

### 6.1 Ajax単語追加の呼び出し例

```javascript
// word_selector_controller.js
async addWord(word, meaning, entryId) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  
  const response = await fetch('/vocabularies/add_from_entry', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      word: word,
      meaning: meaning,
      entry_id: entryId
    })
  });

  const data = await response.json();
  
  if (data.success) {
    // 成功処理
    console.log('単語を登録しました:', data.vocabulary);
  } else {
    // エラー処理
    console.error('エラー:', data.error);
  }
}
```

### 6.2 習得済みトグルの呼び出し例

```javascript
// flashcard_controller.js
async toggleMastered(vocabularyId) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  
  const response = await fetch(`/vocabularies/${vocabularyId}/toggle_mastered`, {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': csrfToken
    }
  });

  const data = await response.json();
  
  if (data.success) {
    console.log('習得済み:', data.mastered);
  }
}
```

---

## 7. テスト用curlコマンド

```bash
# 単語一覧取得
curl -X GET http://localhost:3000/vocabularies

# 単語追加（Ajax）
curl -X POST http://localhost:3000/vocabularies/add_from_entry \
  -H "Content-Type: application/json" \
  -d '{"word":"grateful","meaning":"感謝している","entry_id":1}'

# 習得済みトグル
curl -X PATCH http://localhost:3000/vocabularies/1/toggle_mastered

# お気に入りトグル
curl -X PATCH http://localhost:3000/vocabularies/1/toggle_favorited

# 単語削除
curl -X DELETE http://localhost:3000/vocabularies/1
```

