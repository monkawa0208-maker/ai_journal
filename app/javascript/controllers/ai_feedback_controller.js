import { Controller } from "@hotwired/stimulus"

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
    // アニメーション開始（1〜3個の点が循環）
    let dots = 0
    const baseLabel = "生成中"
    const tick = () => {
      dots = (dots + 1) % 4
      const suffix = dots === 0 ? "" : ".".repeat(dots)
      button.textContent = `${baseLabel}${suffix}`
    }
    tick()
    this.loadingTimer && clearInterval(this.loadingTimer)
    this.loadingTimer = setInterval(tick, 400)

    fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
      },
      credentials: 'same-origin'
    })
      .then(async (res) => {
        const data = await res.json()
        if (!res.ok) throw new Error(data.error || '生成に失敗しました')
        if (this.hasHintTarget) this.hintTarget.remove()
        // フィードバックを装飾して表示
        const formattedResponse = this.formatFeedback(data.response || '')
        this.outputTarget.innerHTML = formattedResponse
        this.outputTarget.className = 'ai-feedback-content'
        // アニメーション停止してボタンを除去
        if (this.loadingTimer) {
          clearInterval(this.loadingTimer)
          this.loadingTimer = null
        }
        button.remove()
      })
      .catch((err) => {
        alert(err.message)
        button.disabled = false
        // アニメーション停止・文言復元
        if (this.loadingTimer) {
          clearInterval(this.loadingTimer)
          this.loadingTimer = null
        }
        button.textContent = originalText
        button.dataset.loading = 'false'
      })
  }

  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta && meta.getAttribute('content')
  }

  formatFeedback(feedbackText) {
    // AIフィードバックを見やすく整形して表示
    const formatted = feedbackText
      .replace(/# 英文アドバイス/g, '<strong class="feedback-section-title">✏️ 英文アドバイス</strong>')
      .replace(/# 修正後の文章/g, '<strong class="feedback-section-title">✨ 修正後の文章</strong>')
      .replace(/# より良い表現/g, '<strong class="feedback-section-title">🌟 より良い表現</strong>')
      .replace(/# コメント/g, '<strong class="feedback-section-title">💬 コメント</strong>')
      .replace(/\n/g, '<br>')

    return formatted
  }

  formatTextWithLineBreaks(text) {
    // 改行文字を<br>タグに変換し、HTMLエスケープも行う
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
      .replace(/\n/g, '<br>')
  }
}


