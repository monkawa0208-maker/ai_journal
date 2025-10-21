import { Controller } from "@hotwired/stimulus"
import { ControllerUtils } from "controllers/utils"

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
    this.updateTranslateButtonState()
  }

  // 日本語入力内容が変更されたときにボタンの状態を更新
  checkJapaneseContent() {
    this.updateTranslateButtonState()
  }

  updateTranslateButtonState() {
    const japaneseText = this.japaneseTextTarget?.value.trim() || ""

    const isActive = japaneseText.length > 0
    this.translateButtonTarget.classList.toggle("disabled", !isActive)
    this.translateButtonTarget.disabled = !isActive
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

    ControllerUtils.setLoadingState(this.translateButtonTarget, true, "⏳ 翻訳中...")
    ControllerUtils.showStatus(this.statusTarget, "AI翻訳を実行中...", "loading", "translate-status")

    try {
      console.log("Sending translation request...")
      const { success, data, error } = await ControllerUtils.makeRequest("/entries/translate", {
        method: "POST",
        body: JSON.stringify({ text: japaneseText })
      })

      if (success) {
        // 翻訳成功 - 結果を保存して表示エリアに表示
        this.currentTranslation = data.translation
        this.displayFormattedTranslation(data.translation)
        this.translationResultTarget.style.display = "block"
        this.aiTranslateFieldTarget.value = data.translation
        ControllerUtils.showStatus(this.statusTarget, "✅ 翻訳完了！内容を確認してください", "success", "translate-status")
      } else {
        // エラー処理
        ControllerUtils.showStatus(this.statusTarget, `❌ ${error || "翻訳に失敗しました"}`, "error", "translate-status")
      }
    } catch (error) {
      ControllerUtils.showStatus(this.statusTarget, "❌ ネットワークエラーが発生しました", "error", "translate-status")
    } finally {
      ControllerUtils.setLoadingState(this.translateButtonTarget, false, undefined, "🌐 英語に翻訳")
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
    const formatted = ControllerUtils.formatTranslation(fullResponse)

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

  // status表示・CSRF取得はControllerUtilsに統一
}

