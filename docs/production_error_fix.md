# 本番環境エラー解決方針

## 発生したエラー

```
/assets/controllers/utils:1  Failed to load resource: the server responded with a status of 404 ()
stimulus-loading.js:26 Failed to register controller: form-feedback (controllers/form_feedback_controller)
stimulus-loading.js:26 Failed to register controller: vocabulary-card (controllers/vocabulary_card_controller)
stimulus-loading.js:26 Failed to register controller: translation (controllers/translation_controller)
```

## エラーの原因

### 1. インポートパスの問題
- 3つのStimulusコントローラー（`translation_controller.js`, `form_feedback_controller.js`, `vocabulary_card_controller.js`）が`utils.js`から`ControllerUtils`をインポートしている
- 現在のインポート方法：`import { ControllerUtils } from "./utils"`
- 相対パス（`./utils`）は開発環境では動作するが、本番環境のアセットプリコンパイル時に正しく解決されない

### 2. Importmapの設定
- `config/importmap.rb`で`pin_all_from "app/javascript/controllers", under: "controllers"`が設定されている
- これにより、すべてのコントローラーファイルは`controllers/`プレフィックス付きでピン留めされる
- 相対インポート（`./utils`）ではなく、完全なパス（`controllers/utils`）を使用する必要がある

## 解決方法

### 方法1: インポートパスを変更（推奨）
以下の3つのファイルで、インポートパスを相対パスから完全なパスに変更する：

1. `app/javascript/controllers/translation_controller.js`
2. `app/javascript/controllers/form_feedback_controller.js`
3. `app/javascript/controllers/vocabulary_card_controller.js`

**変更前：**
```javascript
import { ControllerUtils } from "./utils"
```

**変更後：**
```javascript
import { ControllerUtils } from "controllers/utils"
```

### 方法2: utils.jsを明示的にピン留め（代替案）
`config/importmap.rb`に以下を追加：
```ruby
pin "controllers/utils", to: "controllers/utils.js"
```

ただし、`pin_all_from`が既に設定されているため、方法1の方が推奨される。

## 実施手順

1. ✅ エラー原因の特定（完了）
2. ✅ 4つのコントローラーファイルのインポートパスを修正（完了）
   - `app/javascript/controllers/translation_controller.js`
   - `app/javascript/controllers/form_feedback_controller.js`
   - `app/javascript/controllers/vocabulary_card_controller.js`
   - `app/javascript/controllers/ai_feedback_controller.js`
3. ⏳ 修正をコミット
4. ⏳ 本番環境にデプロイして動作確認

## 期待される結果

- `utils.js`が正しく読み込まれる
- すべてのStimulusコントローラーが正常に登録される
- 404エラーが解消される

## 追加の注意事項

- 本番環境では必ずアセットプリコンパイルが実行されることを確認
- Rails 7のimportmap方式では、相対インポートではなく完全なモジュール名を使用することがベストプラクティス
- 他のコントローラーファイルでも同様の問題がないか確認する

