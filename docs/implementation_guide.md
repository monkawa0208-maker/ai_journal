# MyDictionary機能 実装ガイド

## 📚 ドキュメント構成

実装を進める際は、以下のドキュメントを適宜参照してください。

### 必読ドキュメント

1. **requirement_mydictionary.md**
   - 機能の全体像と要件定義
   - 最初に読んで機能の目的を理解する

2. **implementation_checklist.md**
   - 実装手順のチェックリスト
   - Phase 1〜8の順番に従って実装
   - 各ステップ完了後にチェックマークを入れる

3. **task_list.md**
   - 実装タスクの一覧
   - 実装中はこのファイルでタスク管理
   - 完了したタスクにチェックを入れる

### 実装時の参照ドキュメント

4. **database_design_mydictionary.md**
   - データベース設計の詳細
   - マイグレーション作成時に参照
   - モデルの関連付けとバリデーション
   - クエリ例

5. **api_design_mydictionary.md**
   - コントローラーとルーティング設計
   - 各エンドポイントの詳細仕様
   - リクエスト/レスポンスの形式
   - コントローラーのコード例

6. **ui_design_mydictionary.md**
   - ビューとUI/UX設計
   - 各ページのHTMLテンプレート
   - CSS設計とスタイル定義
   - JavaScript/Stimulusコントローラーの設計

---

## 🚀 実装の進め方

### Step 1: 準備
1. `docs/requirement_mydictionary.md` を読んで機能を理解
2. `docs/task_list.md` を開いてタスク管理を開始

### Step 2: データベース（Phase 1）
1. `docs/database_design_mydictionary.md` を参照
2. マイグレーションファイル作成
3. モデル作成と関連付け
4. 完了したら `task_list.md` にチェック

### Step 3: ルーティング・コントローラー（Phase 2）
1. `docs/api_design_mydictionary.md` を参照
2. ルーティング追加
3. コントローラー作成
4. 完了したら `task_list.md` にチェック

### Step 4: ビュー（Phase 3）
1. `docs/ui_design_mydictionary.md` を参照
2. レイアウト更新
3. 各ビューファイル作成
4. 完了したら `task_list.md` にチェック

### Step 5: CSS（Phase 4）
1. `docs/ui_design_mydictionary.md` を参照
2. vocabularies.css 作成
3. レスポンシブ対応
4. 完了したら `task_list.md` にチェック

### Step 6: JavaScript/Stimulus（Phase 5）
1. `docs/ui_design_mydictionary.md` と `docs/api_design_mydictionary.md` を参照
2. 各Stimulusコントローラー作成
3. 完了したら `task_list.md` にチェック

### Step 7: テスト（Phase 6）
1. `docs/database_design_mydictionary.md` でFactoryBot参照
2. `docs/api_design_mydictionary.md` でエンドポイント参照
3. テスト作成
4. 完了したら `task_list.md` にチェック

### Step 8: 統合・確認（Phase 7-8）
1. `docs/implementation_checklist.md` の動作確認項目を実施
2. すべて完了したら `task_list.md` の最終チェック

---

## 📋 タスク管理の方法

### task_list.md の使い方

```markdown
- [ ] 未完了のタスク
- [x] 完了したタスク
```

実装を進める際は：
1. 現在のタスクを確認
2. 関連ドキュメントを参照して実装
3. 完了したら `[ ]` を `[x]` に変更
4. 次のタスクへ

---

## 🔍 ドキュメント参照のタイミング

### マイグレーション作成時
→ `database_design_mydictionary.md` の「1. テーブル構成」

### モデル作成時
→ `database_design_mydictionary.md` の「2. モデル関連付け」

### コントローラー作成時
→ `api_design_mydictionary.md` の「2. コントローラー設計」

### ルーティング追加時
→ `api_design_mydictionary.md` の「1. ルーティング」

### ビュー作成時
→ `ui_design_mydictionary.md` の各ページセクション

### CSS作成時
→ `ui_design_mydictionary.md` の CSS設計セクション

### JavaScript作成時
→ `ui_design_mydictionary.md` と `api_design_mydictionary.md` の JavaScript連携

### テスト作成時
→ `database_design_mydictionary.md` の「4. データ投入例」
→ `api_design_mydictionary.md` の各エンドポイント仕様

---

## 💡 Tips

### コピペ可能なコード
各ドキュメントにはコピペ可能なコード例が記載されています：
- マイグレーションファイルの全コード
- モデルの全コード
- コントローラーの全コード
- ビューの全HTMLテンプレート
- CSSの全スタイル定義

### エラーが出たら
1. `implementation_checklist.md` の「トラブルシューティング」セクションを確認
2. 関連ドキュメントの該当箇所を再確認
3. コンソールやログでエラー内容を確認

### 進捗管理
- `task_list.md` で進捗を可視化
- 各Phase完了ごとに一度レビュー
- 動作確認を忘れずに実施

---

## 📝 ドキュメントの更新

実装中に仕様変更や改善点が見つかった場合：
1. 該当するドキュメントを更新
2. `task_list.md` に影響するタスクがあれば更新
3. 変更内容を記録

---

## ✅ 完了の定義

すべてのタスクが完了したと判断する基準：
- [ ] `task_list.md` の全タスクにチェックが入っている
- [ ] `implementation_checklist.md` の動作確認項目がすべてパスしている
- [ ] テストが全て通っている（`bundle exec rspec`）
- [ ] レスポンシブ対応が確認できている
- [ ] README.md が更新されている

---

## 🎯 実装の目標

1. **機能完全性**: requirement_mydictionary.md の全要件を満たす
2. **コード品質**: DRY原則、可読性、保守性を重視
3. **テスト**: 主要機能に対するテストを実装
4. **UX**: 直感的で使いやすいインターフェース
5. **パフォーマンス**: N+1問題などの最適化

頑張ってください！🚀


