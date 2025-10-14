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
    "aiTranslateField"
  ]

  connect() {
    this.isJapaneseMode = false
    console.log("Translation controller connected")
  }

  toggleLanguage() {
    this.isJapaneseMode = !this.isJapaneseMode

    if (this.isJapaneseMode) {
      // 日本語モードに切り替え
      this.japaneseSectionTarget.style.display = "block"
      this.englishSectionTarget.style.display = "none"
      this.toggleButtonTarget.textContent = "🇬🇧 英語で書く"
      this.toggleButtonTarget.classList.add("active")
    } else {
      // 英語モードに切り替え
      this.japaneseSectionTarget.style.display = "none"
      this.englishSectionTarget.style.display = "block"
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
      this.showStatus("翻訳するテキストを入力してください", "error")
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
        // 翻訳成功
        this.englishTextTarget.value = data.translation
        this.aiTranslateFieldTarget.value = data.translation
        this.showStatus("✅ 翻訳完了！", "success")

        // 3秒後に英語セクションに自動切り替え
        setTimeout(() => {
          this.isJapaneseMode = false
          this.japaneseSectionTarget.style.display = "none"
          this.englishSectionTarget.style.display = "block"
          this.toggleButtonTarget.textContent = "📝 日本語で書く"
          this.toggleButtonTarget.classList.remove("active")
        }, 2000)
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

