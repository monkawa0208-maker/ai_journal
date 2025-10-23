import { Controller } from "@hotwired/stimulus"
import { ControllerUtils } from "controllers/utils"

// Connects to data-controller="ai-feedback"
export default class extends Controller {
  static targets = ["button", "output", "hint"]

  generate(event) {
    event.preventDefault()
    const button = this.buttonTarget
    if (button.dataset.loading === 'true') return
    button.dataset.loading = 'true'
    const url = button.dataset.url

    button.disabled = true
    const originalText = button.textContent
    button.textContent = "生成中"

    ControllerUtils.makeRequest(url, { method: 'POST', headers: { 'Accept': 'application/json' } })
      .then(({ success, data, error }) => {
        if (!success) throw new Error(error || '生成に失敗しました')
        if (this.hasHintTarget) this.hintTarget.remove()
        // フィードバックを装飾して表示
        const formattedResponse = ControllerUtils.formatFeedback(data.response || '')
        this.outputTarget.innerHTML = formattedResponse
        this.outputTarget.className = 'ai-feedback-content'
        // ボタンを除去
        button.remove()

        // word_selector_controllerに通知して単語選択機能を更新
        this.notifyWordSelector()
      })
      .catch((err) => {
        alert(err.message)
        button.disabled = false
        button.textContent = originalText
        button.dataset.loading = 'false'
      })
  }

  notifyWordSelector() {
    // 親要素からword-selectorコントローラーを探す
    const wordSelectorElement = this.element.closest('[data-controller*="word-selector"]')
    if (wordSelectorElement) {
      // Stimulusのアプリケーションインスタンスを取得
      const application = this.application
      if (application) {
        const wordSelectorController = application.getControllerForElementAndIdentifier(wordSelectorElement, 'word-selector')
        if (wordSelectorController && wordSelectorController.refreshWordHighlight) {
          // 少し遅延させてDOMの更新を確実にする
          setTimeout(() => {
            wordSelectorController.refreshWordHighlight()
          }, 100)
        }
      }
    }
  }
}


