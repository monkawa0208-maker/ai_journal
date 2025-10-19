import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggleButton",
    "japaneseSection",
    "englishSection",
    "japaneseText",
    "englishText",
    "translateButton",
    "status",
    "aiTranslateField",
    "translationResult",
    "translationText",
    "applyButton"
  ]

  connect() {
    this.isJapaneseMode = false
    this.currentTranslation = ""
    console.log("Translation controller connected")
    this.updateTranslateButtonState()
  }

  // 日本語入力内容が変更されたときにボタンの状態を更新
  checkJapaneseContent() {
    this.updateTranslateButtonState()
  }

  updateTranslateButtonState() {
    const japaneseText = this.japaneseTextTarget?.value.trim() || ""

    if (japaneseText.length > 0) {
      // 内容がある場合：青色で有効
      this.translateButtonTarget.classList.remove("disabled")
    } else {
      // 内容がない場合：グレーで視覚的に無効
      this.translateButtonTarget.classList.add("disabled")
    }
  }

  toggleLanguage() {
    this.isJapaneseMode = !this.isJapaneseMode

    if (this.isJapaneseMode) {
      // 日本語入力フィールドを表示
      this.japaneseSectionTarget.style.display = "block"
      this.toggleButtonTarget.textContent = "✕ 日本語入力を閉じる"
      this.toggleButtonTarget.classList.add("active")
      // 翻訳ボタンの状態を更新
      this.updateTranslateButtonState()
    } else {
      // 日本語入力フィールドを非表示
      this.japaneseSectionTarget.style.display = "none"
      this.toggleButtonTarget.textContent = "📝 日本語で書く"
      this.toggleButtonTarget.classList.remove("active")
    }
  }

  async translate() {
    console.log("Translate function called")
    const japaneseText = this.japaneseTextTarget.value.trim()
    console.log("Japanese text:", japaneseText)

    // 入力チェック
    if (!japaneseText) {
      this.showStatus("日本語の本文を入力してください", "error")
      return
    }

    // ボタンを無効化して翻訳中を表示
    this.translateButtonTarget.disabled = true
    this.translateButtonTarget.textContent = "⏳ 翻訳中..."
    this.showStatus("AI翻訳を実行中...", "loading")

    try {
      console.log("Sending translation request...")
      const response = await fetch("/entries/translate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCsrfToken()
        },
        body: JSON.stringify({ text: japaneseText })
      })

      console.log("Response status:", response.status)
      const data = await response.json()
      console.log("Response data:", data)

      if (response.ok) {
        // 翻訳成功 - 結果を保存して表示エリアに表示
        this.currentTranslation = data.translation
        this.displayFormattedTranslation(data.translation)
        this.translationResultTarget.style.display = "block"
        this.aiTranslateFieldTarget.value = data.translation
        this.showStatus("✅ 翻訳完了！内容を確認してください", "success")
      } else {
        // エラー処理
        console.error("Translation failed:", data)
        this.showStatus(`❌ ${data.error || "翻訳に失敗しました"}`, "error")
      }
    } catch (error) {
      console.error("Translation error:", error)
      console.error("Error details:", error.message, error.stack)
      this.showStatus("❌ ネットワークエラーが発生しました", "error")
    } finally {
      // ボタンを再有効化
      this.translateButtonTarget.disabled = false
      this.translateButtonTarget.textContent = "🌐 英語に翻訳"
    }
  }

  applyTranslation() {
    // 翻訳結果から「翻訳後の文章」部分だけを抽出
    if (this.currentTranslation) {
      const englishText = this.extractEnglishText(this.currentTranslation)
      this.englishTextTarget.value = englishText

      // inputイベントを発火させてフィードバックボタンと保存ボタンの状態を更新
      const event = new Event('input', { bubbles: true })
      this.englishTextTarget.dispatchEvent(event)

      // 日本語入力フィールドを閉じる
      this.isJapaneseMode = false
      this.japaneseSectionTarget.style.display = "none"
      this.toggleButtonTarget.textContent = "📝 日本語で書く"
      this.toggleButtonTarget.classList.remove("active")

      // 成功メッセージ
      alert("✅ 翻訳を英語フィールドに反映しました！\n\n日本語の文章とAI翻訳結果は「日本語で書く」ボタンから確認できます。")
    }
  }

  displayFormattedTranslation(fullResponse) {
    // AIの回答を見やすく整形して表示
    const formatted = fullResponse
      .replace(/# 翻訳後の文章/g, '<strong class="translation-section-title">📝 翻訳後の文章</strong>')
      .replace(/# Key Points/g, '<strong class="translation-section-title">💡 Key Points</strong>')
      .replace(/# Vocabulary/g, '<strong class="translation-section-title">📚 Vocabulary</strong>')
      .replace(/\n/g, '<br>')

    this.translationTextTarget.innerHTML = formatted
  }

  extractEnglishText(fullResponse) {
    // AIの回答から「翻訳後の文章」部分だけを抽出
    // フォーマット: 翻訳後の文章 \n [英文] \n\n Key Points...

    // まず「Key Points」より前の部分を取得
    const keyPointsIndex = fullResponse.indexOf('Key Points')
    const beforeKeyPoints = keyPointsIndex > 0 ? fullResponse.substring(0, keyPointsIndex) : fullResponse

    // 「翻訳後の文章」「# 翻訳後の文章」などのヘッダーを削除
    let englishText = beforeKeyPoints
      .replace(/^#+\s*翻訳後の文章\s*\n*/i, '')
      .replace(/^翻訳後の文章\s*\n*/i, '')
      .trim()

    // もし改行が複数あれば、最初の段落のみを取得（安全のため）
    const doubleNewlineIndex = englishText.indexOf('\n\n')
    if (doubleNewlineIndex > 0) {
      englishText = englishText.substring(0, doubleNewlineIndex).trim()
    }

    return englishText || fullResponse.trim()
  }

  showStatus(message, type) {
    this.statusTarget.textContent = message
    this.statusTarget.className = `translate-status ${type}`

    // 成功/エラーメッセージは5秒後に自動消去
    if (type === "success" || type === "error") {
      setTimeout(() => {
        this.statusTarget.textContent = ""
        this.statusTarget.className = "translate-status"
      }, 5000)
    }
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}

