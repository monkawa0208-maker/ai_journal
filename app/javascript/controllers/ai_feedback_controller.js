import { Controller } from "@hotwired/stimulus"
import { ControllerUtils } from "./utils"

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
      })
      .catch((err) => {
        alert(err.message)
        button.disabled = false
        button.textContent = originalText
        button.dataset.loading = 'false'
      })
  }
}


