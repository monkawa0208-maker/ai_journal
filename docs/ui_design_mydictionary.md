# MyDictionary UI/UX設計書

## 1. 画面遷移図

```
┌─────────────┐
│  ヘッダー    │ (MyDictionaryリンク追加)
└─────────────┘
      │
      ├─→ 日記一覧ページ (/entries)
      │         │
      │         ├─→ 日記詳細ページ (/entries/:id)
      │         │         │
      │         │         └─→ 単語をクリック
      │         │                   │
      │         │                   └─→ [モーダル] 単語登録
      │         │                             │
      │         │                             └─→ Ajax POST → 単語一覧へ
      │
      └─→ 単語一覧ページ (/vocabularies) ★メインページ
                │
                ├─→ 単語編集ページ (/vocabularies/:id/edit)
                │         │
                │         └─→ 更新 → 単語一覧へ戻る
                │
                └─→ フラッシュカードページ (/vocabularies/flashcard)
                          │
                          └─→ 単語一覧へ戻る
```

---

## 2. ヘッダー更新

### 2.1 現在のヘッダー構成

```html
<header class="app-header">
  <div class="header-container">
    <div class="header-logo">
      <h1><a href="/">AI Journal</a></h1>
    </div>
    <div class="header-user">
      <span>ようこそ [nickname] さん</span>
      <a href="/users/edit">登録情報の編集</a>
      <a href="/users/sign_out">ログアウト</a>
      <a href="/entries/new" class="button new-post">NEW POST</a>
    </div>
  </div>
</header>
```

### 2.2 更新後のヘッダー構成

```html
<header class="app-header">
  <div class="header-container">
    <div class="header-logo">
      <h1><a href="/">AI Journal</a></h1>
    </div>
    <nav class="header-nav">
      <a href="/entries" class="nav-link">日記一覧</a>
      <a href="/vocabularies" class="nav-link">📚 MyDictionary</a> <!-- 追加 -->
    </nav>
    <div class="header-user">
      <span>ようこそ [nickname] さん</span>
      <a href="/users/edit">登録情報の編集</a>
      <a href="/users/sign_out">ログアウト</a>
      <a href="/entries/new" class="button new-post">NEW POST</a>
    </div>
  </div>
</header>
```

---

## 3. 単語一覧ページ (/vocabularies)

### 3.1 ワイヤーフレーム

```
┌──────────────────────────────────────────────────────────┐
│ Header: AI Journal | 日記一覧 | 📚 MyDictionary | ...    │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  📚 My Dictionary                                         │
│                                                            │
│  [検索: ____________] 🔍                                  │
│                                                            │
│  [全て] [未習得] [習得済み] [お気に入り]                  │
│                                                            │
│  [🎴 フラッシュカードで復習]                              │
│                                                            │
│  ┌────────────────┐ ┌────────────────┐ ┌──────────────┐│
│  │ grateful       │ │ accomplish     │ │ challenging  ││
│  │                │ │                │ │              ││
│  │ 感謝している、 │ │ 達成する、     │ │ 挑戦的な、   ││
│  │ ありがたい     │ │ 成し遂げる     │ │ やりがいの... ││
│  │                │ │                │ │              ││
│  │ ✅ 習得済み    │ │ ⭐ お気に入り │ │              ││
│  │                │ │                │ │              ││
│  │ 📝 使用した日記:│ │ 📝 使用した日記:│ │ 📝 使用した..││
│  │ • 10/15 Today  │ │ • 10/17 Work   │ │ • 10/16 ...  ││
│  │ • 10/10 ...    │ │                │ │              ││
│  │                │ │                │ │              ││
│  │ [編集] [削除]  │ │ [編集] [削除]  │ │ [編集] [削除]││
│  └────────────────┘ └────────────────┘ └──────────────┘│
│                                                            │
│  [< 前へ] [次へ >]                                        │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

### 3.2 HTMLテンプレート構成

```erb
<!-- app/views/vocabularies/index.html.erb -->
<div class="vocabularies-container" data-controller="vocabulary-filter">
  <header class="vocabularies-header">
    <h1>📚 My Dictionary</h1>
    <p class="vocabulary-count">登録単語数: <%= @vocabularies.total_count %></p>
  </header>

  <!-- 検索バー -->
  <div class="vocabulary-search">
    <input type="text" 
           placeholder="単語を検索..." 
           data-vocabulary-filter-target="searchInput"
           data-action="input->vocabulary-filter#search">
    <span class="search-icon">🔍</span>
  </div>

  <!-- フィルターボタン -->
  <div class="vocabulary-filters">
    <button class="filter-btn active" data-filter="all">全て</button>
    <button class="filter-btn" data-filter="unmastered">未習得</button>
    <button class="filter-btn" data-filter="mastered">習得済み</button>
    <button class="filter-btn" data-filter="favorited">⭐ お気に入り</button>
  </div>

  <!-- アクションボタン -->
  <div class="vocabulary-actions">
    <%= link_to new_vocabulary_path, class: "button secondary" do %>
      ➕ 新しい単語を追加
    <% end %>
    <%= link_to flashcard_vocabularies_path, class: "button primary" do %>
      🎴 フラッシュカードで復習
    <% end %>
  </div>

  <!-- 単語カードグリッド -->
  <div class="vocabulary-grid" data-vocabulary-filter-target="grid">
    <% @vocabularies.each do |vocabulary| %>
      <div class="vocabulary-card" 
           data-vocabulary-id="<%= vocabulary.id %>"
           data-mastered="<%= vocabulary.mastered %>"
           data-favorited="<%= vocabulary.favorited %>">
        
        <!-- 単語と意味 -->
        <div class="card-header">
          <h3 class="word"><%= vocabulary.word %></h3>
          <div class="card-badges">
            <% if vocabulary.mastered %>
              <span class="badge badge-mastered">✅ 習得済み</span>
            <% end %>
            <% if vocabulary.favorited %>
              <span class="badge badge-favorited">⭐ お気に入り</span>
            <% end %>
          </div>
        </div>

        <p class="meaning"><%= vocabulary.meaning %></p>

        <!-- 使用した日記リンク -->
        <% if vocabulary.entries.any? %>
          <div class="card-entries">
            <p class="entries-label">📝 使用した日記:</p>
            <ul class="entries-list">
              <% vocabulary.entries.limit(3).each do |entry| %>
                <li>
                  <%= link_to entry_path(entry) do %>
                    <%= entry.posted_on.strftime('%m/%d') %> <%= truncate(entry.title, length: 20) %>
                  <% end %>
                </li>
              <% end %>
              <% if vocabulary.entries.count > 3 %>
                <li>他 <%= vocabulary.entries.count - 3 %> 件</li>
              <% end %>
            </ul>
          </div>
        <% else %>
          <div class="card-entries">
            <p class="entries-label no-entries">📝 日記に紐づいていません</p>
          </div>
        <% end %>

        <!-- アクションボタン -->
        <div class="card-actions">
          <%= link_to "編集", edit_vocabulary_path(vocabulary), class: "btn-edit" %>
          <%= link_to "削除", vocabulary_path(vocabulary), 
                      data: { turbo_method: :delete, turbo_confirm: "本当に削除しますか？" },
                      class: "btn-delete" %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- ページネーション -->
  <%= paginate @vocabularies %>
</div>
```

### 3.3 CSS設計

```css
/* app/assets/stylesheets/vocabularies.css */

/* コンテナ */
.vocabularies-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.vocabularies-header {
  text-align: center;
  margin-bottom: 2rem;
}

.vocabularies-header h1 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.vocabulary-count {
  color: #666;
  font-size: 0.9rem;
}

/* 検索バー */
.vocabulary-search {
  position: relative;
  max-width: 500px;
  margin: 0 auto 2rem;
}

.vocabulary-search input {
  width: 100%;
  padding: 0.75rem 2.5rem 0.75rem 1rem;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.vocabulary-search input:focus {
  outline: none;
  border-color: #4CAF50;
}

.search-icon {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
}

/* フィルターボタン */
.vocabulary-filters {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 0.5rem 1.5rem;
  border: 2px solid #ddd;
  background: white;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
}

.filter-btn:hover {
  background: #f5f5f5;
}

.filter-btn.active {
  background: #4CAF50;
  color: white;
  border-color: #4CAF50;
}

/* アクションボタン */
.vocabulary-actions {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.vocabulary-actions .button {
  padding: 0.75rem 2rem;
  font-size: 1.1rem;
}

/* 単語カードグリッド */
.vocabulary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.vocabulary-card {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  padding: 1.5rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.vocabulary-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.card-header {
  margin-bottom: 1rem;
}

.word {
  font-size: 1.5rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 0.5rem;
}

.card-badges {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.badge-mastered {
  background: #e8f5e9;
  color: #2e7d32;
}

.badge-favorited {
  background: #fff3e0;
  color: #f57c00;
}

.meaning {
  color: #555;
  line-height: 1.6;
  margin-bottom: 1rem;
  min-height: 3rem;
}

/* 日記リンク */
.card-entries {
  margin-bottom: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #f0f0f0;
}

.entries-label {
  font-size: 0.85rem;
  color: #777;
  margin-bottom: 0.5rem;
}

.entries-label.no-entries {
  color: #999;
  font-style: italic;
}

.entries-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.entries-list li {
  font-size: 0.85rem;
  margin-bottom: 0.25rem;
}

.entries-list a {
  color: #1976d2;
  text-decoration: none;
}

.entries-list a:hover {
  text-decoration: underline;
}

/* アクションボタン */
.card-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}

.btn-edit, .btn-delete {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #ddd;
  background: white;
  border-radius: 6px;
  text-align: center;
  text-decoration: none;
  color: #333;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.btn-edit:hover {
  background: #2196F3;
  color: white;
  border-color: #2196F3;
}

.btn-delete:hover {
  background: #f44336;
  color: white;
  border-color: #f44336;
}

/* レスポンシブ */
@media (max-width: 768px) {
  .vocabulary-grid {
    grid-template-columns: 1fr;
  }

  .vocabulary-filters {
    flex-direction: column;
    align-items: stretch;
  }

  .filter-btn {
    width: 100%;
  }
}
```

---

## 4. 日記詳細ページ更新 (/entries/:id)

### 4.1 単語選択機能の追加

```erb
<!-- app/views/entries/show.html.erb -->
<section class="entry-detail__section" 
         data-controller="word-selector"
         data-word-selector-entry-id-value="<%= @entry.id %>">
  <h2>本文（英語）</h2>
  <div class="entry-detail__body word-selectable">
    <%= simple_format(h(@entry.content)) %>
  </div>
  
  <!-- 既に登録済みの単語を表示 -->
  <% if @entry.vocabularies.any? %>
    <div class="entry-vocabularies">
      <h3>この日記で登録した単語:</h3>
      <div class="vocabulary-tags">
        <% @entry.vocabularies.each do |vocab| %>
          <%= link_to vocabularies_path(anchor: "vocab-#{vocab.id}"), class: "vocabulary-tag" do %>
            <%= vocab.word %>
          <% end %>
        <% end %>
      </div>
    </div>
  <% end %>
</section>

<!-- 単語登録モーダル -->
<div class="modal" data-word-selector-target="modal">
  <div class="modal-content">
    <span class="modal-close" data-action="click->word-selector#closeModal">&times;</span>
    <h2>単語を登録</h2>
    
    <!-- 成功メッセージ -->
    <div class="modal-success-message" data-word-selector-target="successMessage" style="display: none;">
      ✅ 単語を登録しました！続けて別の単語を選択できます。
    </div>
    
    <form data-word-selector-target="form" data-action="submit->word-selector#submitWord">
      <div class="form-group">
        <label>英単語</label>
        <input type="text" 
               data-word-selector-target="wordInput" 
               readonly 
               class="form-control">
      </div>
      <div class="form-group">
        <label>日本語の意味</label>
        <textarea data-word-selector-target="meaningInput" 
                  class="form-control" 
                  rows="3" 
                  placeholder="単語の意味を入力してください..."
                  required></textarea>
      </div>
      <div class="form-actions">
        <button type="button" 
                class="button secondary" 
                data-action="click->word-selector#closeModal">
          閉じる
        </button>
        <button type="submit" 
                class="button primary"
                data-word-selector-target="submitButton">
          登録
        </button>
      </div>
    </form>
    
    <p class="modal-hint">💡 ヒント: 登録後、このウィンドウを開いたまま別の単語を選択できます</p>
  </div>
</div>
```

### 4.2 単語選択のCSS

```css
/* 単語選択可能エリア */
.word-selectable {
  cursor: text;
  user-select: text;
}

.word-selectable::selection {
  background: #ffeb3b;
}

/* 登録済み単語タグ */
.entry-vocabularies {
  margin-top: 1.5rem;
  padding: 1rem;
  background: #f5f5f5;
  border-radius: 8px;
}

.entry-vocabularies h3 {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.5rem;
}

.vocabulary-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.vocabulary-tag {
  padding: 0.25rem 0.75rem;
  background: #2196F3;
  color: white;
  border-radius: 12px;
  text-decoration: none;
  font-size: 0.85rem;
  transition: background 0.2s;
}

.vocabulary-tag:hover {
  background: #1976D2;
}

/* モーダル */
.modal {
  display: none;
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.5);
  animation: fadeIn 0.3s;
}

.modal.active {
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-content {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  max-width: 500px;
  width: 90%;
  position: relative;
  animation: slideIn 0.3s;
}

.modal-close {
  position: absolute;
  right: 1rem;
  top: 1rem;
  font-size: 1.5rem;
  cursor: pointer;
  color: #999;
}

.modal-close:hover {
  color: #333;
}

.modal-success-message {
  background: #e8f5e9;
  color: #2e7d32;
  padding: 0.75rem;
  border-radius: 6px;
  margin-bottom: 1rem;
  font-size: 0.9rem;
  text-align: center;
}

.modal-hint {
  font-size: 0.85rem;
  color: #999;
  text-align: center;
  margin-top: 1rem;
  margin-bottom: 0;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideIn {
  from { transform: translateY(-50px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

---

## 5. フラッシュカードページ (/vocabularies/flashcard)

### 5.1 ワイヤーフレーム

```
┌──────────────────────────────────────────────────────────┐
│ Header                                                     │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  🎴 フラッシュカード復習                                  │
│                                                            │
│  モード: [英→日] [日→英]                                 │
│                                                            │
│  進捗: 5 / 20                                             │
│                                                            │
│  ┌────────────────────────────────────────────┐        │
│  │                                              │        │
│  │                                              │        │
│  │             grateful                         │        │
│  │                                              │        │
│  │       [カードをクリックして答えを表示]      │        │
│  │                                              │        │
│  │                                              │        │
│  └────────────────────────────────────────────┘        │
│                                                            │
│  [⬅ 前の単語へ]  [次の単語へ ➡]                        │
│                                                            │
│  [習得済みにする]  [お気に入りにする]                    │
│                                                            │
│  [単語一覧に戻る]                                         │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

### 5.2 HTMLテンプレート

```erb
<!-- app/views/vocabularies/flashcard.html.erb -->
<div class="flashcard-container" 
     data-controller="flashcard"
     data-flashcard-vocabularies-value="<%= @vocabularies.to_json(only: [:id, :word, :meaning, :mastered]) %>">
  
  <header class="flashcard-header">
    <h1>🎴 フラッシュカード復習</h1>
    
    <!-- モード切り替え -->
    <div class="flashcard-mode">
      <button class="mode-btn active" 
              data-flashcard-target="modeBtn"
              data-mode="en-ja"
              data-action="click->flashcard#switchMode">
        英→日
      </button>
      <button class="mode-btn" 
              data-flashcard-target="modeBtn"
              data-mode="ja-en"
              data-action="click->flashcard#switchMode">
        日→英
      </button>
    </div>

    <!-- 進捗表示 -->
    <p class="flashcard-progress">
      <span data-flashcard-target="currentIndex">1</span> / 
      <span data-flashcard-target="totalCount"><%= @vocabularies.count %></span>
    </p>
  </header>

  <!-- フラッシュカード -->
  <div class="flashcard-stage">
    <div class="flashcard" 
         data-flashcard-target="card"
         data-action="click->flashcard#flipCard">
      <div class="flashcard-inner">
        <div class="flashcard-front">
          <p data-flashcard-target="frontText"></p>
          <span class="flip-hint">クリックして答えを表示</span>
        </div>
        <div class="flashcard-back">
          <p data-flashcard-target="backText"></p>
        </div>
      </div>
    </div>
  </div>

  <!-- ナビゲーションボタン -->
  <div class="flashcard-controls">
    <button class="btn-control btn-prev" 
            data-action="click->flashcard#prevCard"
            data-flashcard-target="prevBtn">
      ⬅ 前の単語へ
    </button>

    <button class="btn-control btn-next" 
            data-action="click->flashcard#nextCard"
            data-flashcard-target="nextBtn">
      次の単語へ ➡
    </button>
  </div>

  <!-- 状態切り替えボタン -->
  <div class="flashcard-status-controls">
    <button class="btn-control btn-mastered" 
            data-action="click->flashcard#toggleMastered"
            data-flashcard-target="masteredBtn">
      <span data-flashcard-target="masteredText">習得済みにする</span>
    </button>

    <button class="btn-control btn-favorited" 
            data-action="click->flashcard#toggleFavorited"
            data-flashcard-target="favoritedBtn">
      <span data-flashcard-target="favoritedText">お気に入りにする</span>
    </button>
  </div>

  <div class="flashcard-footer">
    <%= link_to "単語一覧に戻る", vocabularies_path, class: "button ghost" %>
  </div>
</div>
```

### 5.3 フラッシュカードCSS

```css
/* app/assets/stylesheets/vocabularies.css に追加 */

/* フラッシュカードコンテナ */
.flashcard-container {
  max-width: 500px;
  margin: 0 auto;
  padding: 2rem;
  text-align: center;
}

.flashcard-header h1 {
  margin-bottom: 1.5rem;
}

/* モード切り替え */
.flashcard-mode {
  display: inline-flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.mode-btn {
  padding: 0.5rem 1.5rem;
  border: 2px solid #ddd;
  background: white;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
}

.mode-btn.active {
  background: #2196F3;
  color: white;
  border-color: #2196F3;
}

/* 進捗表示 */
.flashcard-progress {
  font-size: 1.2rem;
  color: #666;
  margin-bottom: 2rem;
}

/* フラッシュカードステージ */
.flashcard-stage {
  perspective: 1000px;
  margin-bottom: 2rem;
  display: flex;
  justify-content: center;
  align-items: center;
}

.flashcard {
  width: 100%;
  max-width: 450px;
  height: 250px;
  cursor: pointer;
}

.flashcard-inner {
  position: relative;
  width: 100%;
  height: 100%;
  transition: transform 0.6s;
  transform-style: preserve-3d;
}

.flashcard.flipped .flashcard-inner {
  transform: rotateY(180deg);
}

.flashcard-front, .flashcard-back {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  padding: 2rem;
  box-sizing: border-box;
}

.flashcard-front p, .flashcard-back p {
  font-size: 1.75rem;
  font-weight: bold;
  color: #333;
  margin: 0;
  padding: 1rem;
  word-wrap: break-word;
}

.flashcard-back {
  transform: rotateY(180deg);
  background: #f5f5f5;
}

.flip-hint {
  position: absolute;
  bottom: 1.5rem;
  font-size: 0.9rem;
  color: #999;
}

/* コントロールボタン */
.flashcard-controls {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.flashcard-status-controls {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.btn-control {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
}

.btn-prev, .btn-next {
  background: #2196F3;
  color: white;
}

.btn-prev:hover, .btn-next:hover {
  background: #1976D2;
}

.btn-prev:disabled, .btn-next:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-mastered {
  background: white;
  border: 2px solid #4CAF50;
  color: #4CAF50;
}

.btn-mastered:hover {
  background: #4CAF50;
  color: white;
}

.btn-mastered.mastered {
  background: #4CAF50;
  color: white;
}

.btn-favorited {
  background: white;
  border: 2px solid #FF9800;
  color: #FF9800;
}

.btn-favorited:hover {
  background: #FF9800;
  color: white;
}

.btn-favorited.favorited {
  background: #FF9800;
  color: white;
}

/* フッター */
.flashcard-footer {
  margin-top: 2rem;
}

/* レスポンシブ */
@media (max-width: 768px) {
  .flashcard {
    height: 200px;
    max-width: 100%;
  }

  .flashcard-front p, .flashcard-back p {
    font-size: 1.4rem;
    padding: 0.75rem;
  }

  .flashcard-controls,
  .flashcard-status-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .btn-control {
    width: 100%;
  }
}
```

---

## 6. 単語編集ページ (/vocabularies/:id/edit)

### 6.1 HTMLテンプレート

```erb
<!-- app/views/vocabularies/edit.html.erb -->
<div class="vocabulary-form-container">
  <h1>単語を編集</h1>

  <%= form_with model: @vocabulary, local: true, class: "vocabulary-form" do |f| %>
    <div class="form-group">
      <%= f.label :word, "英単語" %>
      <%= f.text_field :word, class: "form-control", placeholder: "例: grateful", required: true %>
    </div>

    <div class="form-group">
      <%= f.label :meaning, "日本語の意味" %>
      <%= f.text_area :meaning, class: "form-control", rows: 4, required: true %>
    </div>

    <div class="form-group-checkboxes">
      <div class="checkbox-wrapper">
        <%= f.check_box :mastered, class: "form-checkbox" %>
        <%= f.label :mastered, "✅ 習得済み" %>
      </div>

      <div class="checkbox-wrapper">
        <%= f.check_box :favorited, class: "form-checkbox" %>
        <%= f.label :favorited, "⭐ お気に入り" %>
      </div>
    </div>

    <div class="form-actions">
      <%= link_to "キャンセル", vocabularies_path, class: "button secondary" %>
      <%= f.submit "更新", class: "button primary" %>
    </div>
  <% end %>
</div>
```

---

## 7. コンポーネント設計

### 7.1 再利用可能なコンポーネント

1. **VocabularyCard** - 単語カード
2. **SearchBar** - 検索バー
3. **FilterButtons** - フィルターボタン群
4. **Modal** - モーダルウィンドウ
5. **Flashcard** - フラッシュカード

### 7.2 カラーパレット

```css
:root {
  --primary-color: #2196F3;      /* メインカラー */
  --success-color: #4CAF50;      /* 習得済み */
  --warning-color: #FF9800;      /* お気に入り */
  --danger-color: #f44336;       /* 削除 */
  --text-primary: #333;
  --text-secondary: #666;
  --text-hint: #999;
  --border-color: #e0e0e0;
  --bg-light: #f5f5f5;
  --shadow: 0 2px 8px rgba(0,0,0,0.1);
}
```

---

## 8. アクセシビリティ

- キーボード操作対応（Tab, Enter, Esc）
- ARIA属性の適切な使用
- 十分なコントラスト比
- フォーカスインジケーター
- スクリーンリーダー対応

