// 共通ユーティリティ関数
export class ControllerUtils {
  // CSRFトークンを取得
  static getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta?.getAttribute('content') || ''
  }

  // APIリクエストの共通処理
  static async makeRequest(url, options = {}) {
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken(),
        ...options.headers
      },
      credentials: 'same-origin',
      ...options
    }

    try {
      const response = await fetch(url, defaultOptions)
      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || `HTTP error! status: ${response.status}`)
      }

      return { success: true, data }
    } catch (error) {
      console.error('API request failed:', error)
      return { success: false, error: error.message }
    }
  }

  // ステータスメッセージを表示
  static showStatus(element, message, type = 'info', baseClass = 'status-message') {
    if (!element) return

    element.textContent = message
    element.className = `${baseClass} ${type}`

    // 成功/エラーメッセージは5秒後に自動消去
    if (type === 'success' || type === 'error') {
      setTimeout(() => {
        element.textContent = ''
        element.className = baseClass
      }, 5000)
    }
  }

  // ローディング状態を管理
  static setLoadingState(button, isLoading, loadingText = '処理中...', originalText = '') {
    if (!button) return

    if (isLoading) {
      if (!button.dataset.originalText) {
        button.dataset.originalText = button.textContent || ''
      }
      button.disabled = true
      button.dataset.loading = 'true'
      button.textContent = loadingText
    } else {
      button.disabled = false
      button.dataset.loading = 'false'
      button.textContent = originalText || button.dataset.originalText || '送信'
    }
  }

  // テキストをHTMLエスケープ
  static escapeHtml(text) {
    if (!text) return ''
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }

  // 改行を<br>タグに変換
  static formatTextWithLineBreaks(text) {
    if (!text) return ''
    return this.escapeHtml(text).replace(/\n/g, '<br>')
  }

  // AIフィードバックをフォーマット
  static formatFeedback(feedbackText) {
    if (!feedbackText) return ''

    return feedbackText
      .replace(/# 英文アドバイス/g, '<strong class="feedback-section-title">✏️ 英文アドバイス</strong>')
      .replace(/# 修正後の文章/g, '<strong class="feedback-section-title">✨ 修正後の文章</strong>')
      .replace(/# より良い表現/g, '<strong class="feedback-section-title">🌟 より良い表現</strong>')
      .replace(/# コメント/g, '<strong class="feedback-section-title">💬 コメント</strong>')
      .replace(/\n/g, '<br>')
  }

  // 翻訳結果をフォーマット
  static formatTranslation(translationText) {
    if (!translationText) return ''

    return translationText
      .replace(/# 翻訳後の文章/g, '<strong class="translation-section-title">📝 翻訳後の文章</strong>')
      .replace(/# Key Points/g, '<strong class="translation-section-title">💡 Key Points</strong>')
      .replace(/# Vocabulary/g, '<strong class="translation-section-title">📚 Vocabulary</strong>')
      .replace(/\n/g, '<br>')
  }

  // フォームバリデーション
  static validateForm(formData, requiredFields = []) {
    const errors = []

    requiredFields.forEach(field => {
      const value = formData[field]
      if (!value || value.trim() === '') {
        errors.push(`${field}は必須です`)
      }
    })

    return {
      isValid: errors.length === 0,
      errors
    }
  }

  // 成功通知を表示
  static showNotification(message, type = 'success', duration = 3000) {
    const notification = document.createElement('div')
    notification.className = `notification ${type}`
    notification.textContent = message

    notification.style.cssText = `
      position: fixed;
      top: 80px;
      right: 20px;
      background: ${type === 'success' ? '#4CAF50' : '#f44336'};
      color: white;
      padding: 1rem 1.5rem;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 2000;
      animation: slideInRight 0.3s ease-out;
    `

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.style.animation = 'slideOutRight 0.3s ease-in'
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, duration)
  }

  // デバウンス関数
  static debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  // イベントリスナーのクリーンアップ
  static cleanupEventListeners(element, events = []) {
    events.forEach(({ event, handler }) => {
      element.removeEventListener(event, handler)
    })
  }
}
