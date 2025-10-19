# MyDictionary データベース設計書

## 1. テーブル構成

### 1.1 vocabularies テーブル

ユーザーが登録した英単語を管理するテーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_vocabularies.rb
class CreateVocabularies < ActiveRecord::Migration[7.0]
  def change
    create_table :vocabularies do |t|
      t.string :word, null: false, comment: '英単語'
      t.text :meaning, null: false, comment: '日本語の意味'
      t.boolean :mastered, default: false, null: false, comment: '習得済みフラグ'
      t.boolean :favorited, default: false, null: false, comment: 'お気に入りフラグ'
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'

      t.timestamps
    end

    add_index :vocabularies, [:user_id, :word], unique: true, name: 'index_vocabularies_on_user_id_and_word'
  end
end
```

**カラム詳細:**

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | integer | NO | AUTO_INCREMENT | 主キー |
| word | string(255) | NO | - | 英単語 |
| meaning | text | NO | - | 日本語の意味（ユーザー入力） |
| mastered | boolean | NO | false | 習得済みフラグ |
| favorited | boolean | NO | false | お気に入りフラグ |
| user_id | integer | NO | - | 外部キー（users.id） |
| created_at | datetime | NO | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | datetime | NO | CURRENT_TIMESTAMP | 更新日時 |

**インデックス:**
- PRIMARY KEY (id)
- INDEX (user_id)
- UNIQUE INDEX (user_id, word) - 同一ユーザーが同じ単語を重複登録できないようにする

**バリデーション:**
```ruby
validates :word, presence: true, 
                 length: { maximum: 255 },
                 uniqueness: { scope: :user_id, message: 'は既に登録されています' }
validates :meaning, presence: true
validates :mastered, inclusion: { in: [true, false] }
validates :favorited, inclusion: { in: [true, false] }
```

---

### 1.2 entry_vocabularies テーブル（中間テーブル）

日記と単語の多対多の関係を管理する中間テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_entry_vocabularies.rb
class CreateEntryVocabularies < ActiveRecord::Migration[7.0]
  def change
    create_table :entry_vocabularies do |t|
      t.references :entry, null: false, foreign_key: true, comment: '日記ID'
      t.references :vocabulary, null: false, foreign_key: true, comment: '単語ID'

      t.timestamps
    end

    add_index :entry_vocabularies, [:entry_id, :vocabulary_id], unique: true, name: 'index_entry_vocabularies_on_entry_and_vocabulary'
  end
end
```

**カラム詳細:**

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | integer | NO | AUTO_INCREMENT | 主キー |
| entry_id | integer | NO | - | 外部キー（entries.id） |
| vocabulary_id | integer | NO | - | 外部キー（vocabularies.id） |
| created_at | datetime | NO | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | datetime | NO | CURRENT_TIMESTAMP | 更新日時 |

**インデックス:**
- PRIMARY KEY (id)
- INDEX (entry_id)
- INDEX (vocabulary_id)
- UNIQUE INDEX (entry_id, vocabulary_id) - 同じ日記に同じ単語を重複登録できないようにする

---

## 2. モデル関連付け

### 2.1 Vocabularyモデル

```ruby
# app/models/vocabulary.rb
class Vocabulary < ApplicationRecord
  belongs_to :user
  has_many :entry_vocabularies, dependent: :destroy
  has_many :entries, through: :entry_vocabularies

  validates :word, presence: true, 
                   length: { maximum: 255 },
                   uniqueness: { scope: :user_id, message: 'は既に登録されています' }
  validates :meaning, presence: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:word) }
  scope :mastered, -> { where(mastered: true) }
  scope :unmastered, -> { where(mastered: false) }
  scope :favorited, -> { where(favorited: true) }
  scope :search_by_word, ->(keyword) { where('word LIKE ?', "%#{keyword}%") if keyword.present? }

  # メソッド
  def toggle_mastered!
    update!(mastered: !mastered)
  end

  def toggle_favorited!
    update!(favorited: !favorited)
  end
end
```

### 2.2 EntryVocabularyモデル

```ruby
# app/models/entry_vocabulary.rb
class EntryVocabulary < ApplicationRecord
  belongs_to :entry
  belongs_to :vocabulary

  validates :entry_id, uniqueness: { scope: :vocabulary_id }
end
```

### 2.3 Userモデル（既存モデルに追加）

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # 既存のコード...
  has_many :entries, dependent: :destroy
  has_many :vocabularies, dependent: :destroy  # 追加

  # ...
end
```

### 2.4 Entryモデル（既存モデルに追加）

```ruby
# app/models/entry.rb
class Entry < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many :entry_vocabularies, dependent: :destroy  # 追加
  has_many :vocabularies, through: :entry_vocabularies  # 追加

  # 既存のバリデーション...
end
```

---

## 3. ER図

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│    users    │         │entry_vocabularies│         │ vocabularies│
├─────────────┤         ├──────────────────┤         ├─────────────┤
│ id (PK)     │─┐       │ id (PK)          │    ┌───│ id (PK)     │
│ email       │ │       │ entry_id (FK)    │    │   │ word        │
│ nickname    │ │       │ vocabulary_id (FK)│───┘   │ meaning     │
│ ...         │ │       │ created_at       │        │ mastered    │
└─────────────┘ │       │ updated_at       │        │ favorited   │
                │       └──────────────────┘        │ user_id (FK)│─┐
                │                │                  │ created_at  │ │
                │                │                  │ updated_at  │ │
                │                │                  └─────────────┘ │
                │       ┌────────┘                                  │
                │       │                                           │
                │  ┌────────────┐                                   │
                └─>│  entries   │                                   │
                   ├────────────┤                                   │
                   │ id (PK)    │<──────────────────────────────────┘
                   │ title      │
                   │ content    │
                   │ user_id(FK)│
                   │ ...        │
                   └────────────┘
```

**リレーション:**
- User → Vocabularies: 1対多
- User → Entries: 1対多
- Entry ⇔ Vocabulary: 多対多（entry_vocabularies経由）

---

## 4. データ投入例（Seed/Factory）

### 4.1 FactoryBot定義

```ruby
# spec/factories/vocabularies.rb
FactoryBot.define do
  factory :vocabulary do
    word { Faker::Lorem.word }
    meaning { "#{word}の意味" }
    mastered { false }
    favorited { false }
    association :user

    trait :mastered do
      mastered { true }
    end

    trait :favorited do
      favorited { true }
    end
  end
end

# spec/factories/entry_vocabularies.rb
FactoryBot.define do
  factory :entry_vocabulary do
    association :entry
    association :vocabulary
  end
end
```

### 4.2 Seed例

```ruby
# db/seeds.rb に追加
if Rails.env.development?
  user = User.first || User.create!(
    email: 'test@example.com',
    password: 'password',
    nickname: 'テストユーザー'
  )

  # サンプル単語を作成
  words = [
    { word: 'grateful', meaning: '感謝している、ありがたい' },
    { word: 'accomplish', meaning: '達成する、成し遂げる' },
    { word: 'challenging', meaning: '挑戦的な、やりがいのある' },
    { word: 'improve', meaning: '改善する、向上する' },
    { word: 'productive', meaning: '生産的な、有益な' }
  ]

  words.each do |word_data|
    Vocabulary.find_or_create_by!(
      user: user,
      word: word_data[:word]
    ) do |vocab|
      vocab.meaning = word_data[:meaning]
    end
  end

  puts "Created #{Vocabulary.count} vocabularies"
end
```

---

## 5. マイグレーション実行手順

```bash
# マイグレーションファイル作成
rails generate model Vocabulary word:string meaning:text mastered:boolean favorited:boolean user:references
rails generate model EntryVocabulary entry:references vocabulary:references

# マイグレーションファイルを編集（上記の定義を参考に）
# - null制約追加
# - デフォルト値設定
# - インデックス追加
# - コメント追加

# マイグレーション実行
rails db:migrate

# テスト環境にも反映
RAILS_ENV=test rails db:migrate
```

---

## 6. クエリ例

### 6.1 よく使うクエリ

```ruby
# ユーザーの全単語を取得（最新順）
user.vocabularies.recent

# 未習得の単語のみ取得
user.vocabularies.unmastered

# お気に入りの単語のみ取得
user.vocabularies.favorited

# 単語で検索
user.vocabularies.search_by_word('grat')

# 特定の日記で使用されている単語
entry.vocabularies

# 特定の単語を使用している日記一覧
vocabulary.entries

# 単語数をカウント
user.vocabularies.count
user.vocabularies.mastered.count
user.vocabularies.unmastered.count

# 単語と関連する日記を同時に取得（N+1対策）
user.vocabularies.includes(:entries).recent
```

### 6.2 複雑なクエリ例

```ruby
# 過去7日間に追加された単語
user.vocabularies.where('created_at >= ?', 7.days.ago)

# 単語と日記数を一緒に取得
user.vocabularies.left_joins(:entry_vocabularies)
    .select('vocabularies.*, COUNT(entry_vocabularies.id) as entries_count')
    .group('vocabularies.id')

# 習得率を計算
total = user.vocabularies.count
mastered = user.vocabularies.mastered.count
mastery_rate = (mastered.to_f / total * 100).round(1)
```

---

## 7. パフォーマンス最適化

### 7.1 推奨インデックス

すでに定義済み：
- `vocabularies(user_id, word)` - ユーザーごとの単語検索
- `entry_vocabularies(entry_id, vocabulary_id)` - 中間テーブルの検索

### 7.2 N+1問題対策

```ruby
# 一覧表示時は必ずincludesを使用
@vocabularies = current_user.vocabularies.includes(:entries).recent

# 日記詳細ページで単語を表示する場合
@entry = Entry.includes(:vocabularies).find(params[:id])
```

### 7.3 ページネーション

```ruby
# Gemfile に追加
gem 'kaminari'

# コントローラーで使用
@vocabularies = current_user.vocabularies.recent.page(params[:page]).per(20)
```

---

## 8. データ整合性

### 8.1 外部キー制約

- `vocabularies.user_id` → `users.id`（CASCADE DELETE）
- `entry_vocabularies.entry_id` → `entries.id`（CASCADE DELETE）
- `entry_vocabularies.vocabulary_id` → `vocabularies.id`（CASCADE DELETE）

### 8.2 一意性制約

- `vocabularies(user_id, word)` - 同一ユーザーが同じ単語を重複登録不可
- `entry_vocabularies(entry_id, vocabulary_id)` - 同じ日記に同じ単語を重複登録不可

### 8.3 削除時の挙動

- ユーザー削除 → 関連する単語も全て削除（dependent: :destroy）
- 日記削除 → entry_vocabulariesのみ削除、vocabulary本体は残る
- 単語削除 → entry_vocabulariesも全て削除（dependent: :destroy）

