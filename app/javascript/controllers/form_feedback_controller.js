import { Controller } from "@hotwired/stimulus"
import { ControllerUtils } from "controllers/utils"

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

    const isActive = content.length > 0
    this.buttonTarget.classList.toggle("disabled", !isActive)
    this.buttonTarget.disabled = !isActive
  }

  // 保存ボタンの状態を更新（本文のみ必要、タイトルはAI自動生成）
  updateSubmitButtonState() {
    const contentField = this.element.querySelector('[name="entry[content]"]')

    const content = contentField?.value.trim() || ""

    if (this.hasSubmitButtonTarget) {
      const canSubmit = content.length > 0
      this.submitButtonTarget.classList.toggle("disabled", !canSubmit)
      this.submitButtonTarget.disabled = !canSubmit
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

    ControllerUtils.setLoadingState(this.buttonTarget, true, "⏳ AI分析中...")
    ControllerUtils.showStatus(this.statusTarget, "AIがフィードバックを生成中...", "loading", "feedback-preview-status")

    try {
      console.log("Sending feedback request...")
      const { success, data, error } = await ControllerUtils.makeRequest("/entries/preview_feedback", {
        method: "POST",
        body: JSON.stringify({ title, content })
      })

      if (success) {
        // フィードバック取得成功 - 装飾して表示
        this.displayFormattedFeedback(data.response)
        this.responseFieldTarget.value = data.response
        this.resultAreaTarget.style.display = "block"
        ControllerUtils.showStatus(this.statusTarget, "✅ フィードバック取得完了！", "success", "feedback-preview-status")
      } else {
        // エラー処理
        ControllerUtils.showStatus(this.statusTarget, `❌ ${error || "フィードバック生成に失敗しました"}`, "error", "feedback-preview-status")
      }
    } catch (error) {
      ControllerUtils.showStatus(this.statusTarget, "❌ ネットワークエラーが発生しました", "error", "feedback-preview-status")
    } finally {
      ControllerUtils.setLoadingState(this.buttonTarget, false, undefined, "AIからフィードバックをもらう")
    }
  }

  displayFormattedFeedback(feedbackText) {
    // AIフィードバックを見やすく整形して表示
    const formatted = ControllerUtils.formatFeedback(feedbackText)

    this.feedbackTextTarget.innerHTML = formatted
  }

  // status表示・CSRF取得はControllerUtilsに統一
}

