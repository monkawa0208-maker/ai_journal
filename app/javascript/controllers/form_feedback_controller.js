import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "button",
    "status",
    "resultArea",
    "feedbackText",
    "responseField",
    "contentField",
    "submitButton"
  ]

  connect() {
    console.log("Form feedback controller connected")
    this.updateButtonState()
    this.updateSubmitButtonState()
  }

  // 入力内容が変更されたときにボタンの状態を更新
  checkContent() {
    this.updateButtonState()
    this.updateSubmitButtonState()
  }

  // タイトルが変更されたときに保存ボタンの状態を更新
  checkTitle() {
    this.updateSubmitButtonState()
  }


  updateButtonState() {
    const contentField = this.element.querySelector('[name="entry[content]"]')
    const content = contentField?.value.trim() || ""

    if (content.length > 0) {
      // 内容がある場合：青色で有効
      this.buttonTarget.classList.remove("disabled")
    } else {
      // 内容がない場合：グレーで視覚的に無効
      this.buttonTarget.classList.add("disabled")
    }
  }

  // 保存ボタンの状態を更新（タイトルと本文の両方が必要）
  updateSubmitButtonState() {
    const titleField = this.element.querySelector('[name="entry[title]"]')
    const contentField = this.element.querySelector('[name="entry[content]"]')

    const title = titleField?.value.trim() || ""
    const content = contentField?.value.trim() || ""

    if (this.hasSubmitButtonTarget) {
      if (title.length > 0 && content.length > 0) {
        // タイトルと本文の両方がある場合：青色で有効
        this.submitButtonTarget.classList.remove("disabled")
      } else {
        // どちらかが空の場合：グレーで視覚的に無効
        this.submitButtonTarget.classList.add("disabled")
      }
    }
  }

  async getFeedback() {
    console.log("Get feedback function called")

    // フォームから本文を取得
    const form = this.element
    const titleField = form.querySelector('[name="entry[title]"]')
    const contentField = form.querySelector('[name="entry[content]"]')

    const title = titleField?.value.trim() || ""
    const content = contentField?.value.trim()

    // 入力チェック（本文のみ必須）
    if (!content) {
      this.showStatus("本文（英語）を入力してください", "error")
      return
    }

    // ボタンを無効化してローディング表示
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "⏳ AI分析中..."
    this.showStatus("AIがフィードバックを生成中...", "loading")

    try {
      console.log("Sending feedback request...")
      const response = await fetch("/entries/preview_feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCsrfToken()
        },
        body: JSON.stringify({
          title: title,
          content: content
        })
      })

      console.log("Response status:", response.status)
      const data = await response.json()
      console.log("Response data:", data)

      if (response.ok) {
        // フィードバック取得成功 - 装飾して表示
        this.displayFormattedFeedback(data.response)
        this.responseFieldTarget.value = data.response
        this.resultAreaTarget.style.display = "block"
        this.showStatus("✅ フィードバック取得完了！", "success")
      } else {
        // エラー処理
        console.error("Feedback generation failed:", data)
        this.showStatus(`❌ ${data.error || "フィードバック生成に失敗しました"}`, "error")
      }
    } catch (error) {
      console.error("Feedback error:", error)
      console.error("Error details:", error.message, error.stack)
      this.showStatus("❌ ネットワークエラーが発生しました", "error")
    } finally {
      // ボタンを再有効化
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "🤖 AIフィードバックをもらう"
    }
  }

  displayFormattedFeedback(feedbackText) {
    // AIフィードバックを見やすく整形して表示
    const formatted = feedbackText
      .replace(/# 英文アドバイス/g, '<strong class="feedback-section-title">✏️ 英文アドバイス</strong>')
      .replace(/# 修正後の文章/g, '<strong class="feedback-section-title">✨ 修正後の文章</strong>')
      .replace(/# より良い表現/g, '<strong class="feedback-section-title">🌟 より良い表現</strong>')
      .replace(/# コメント/g, '<strong class="feedback-section-title">💬 コメント</strong>')
      .replace(/\n/g, '<br>')

    this.feedbackTextTarget.innerHTML = formatted
  }

  showStatus(message, type) {
    this.statusTarget.textContent = message
    this.statusTarget.className = `feedback-preview-status ${type}`

    // 成功/エラーメッセージは5秒後に自動消去
    if (type === "success" || type === "error") {
      setTimeout(() => {
        this.statusTarget.textContent = ""
        this.statusTarget.className = "feedback-preview-status"
      }, 5000)
    }
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}

