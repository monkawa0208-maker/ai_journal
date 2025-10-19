import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Form confirmation controller connected")

    // フォームの変更を追跡
    this.isSubmitting = false
    this.userConfirmedNavigation = false
    this.initialFormData = new FormData(this.element)

    // beforeunloadイベントをバインド（ブラウザのタブを閉じる、リロード等）
    this.beforeUnloadHandler = (event) => {
      if (!this.isSubmitting && !this.userConfirmedNavigation && this.isFormChanged()) {
        event.preventDefault()
        event.returnValue = ''
        return ''
      }
    }
    window.addEventListener('beforeunload', this.beforeUnloadHandler)

    // フォーム送信時のイベントをバインド
    this.element.addEventListener('submit', () => {
      this.isSubmitting = true
    })

    // ページ内のすべてのaタグにクリックイベントを追加
    this.handleLinkClick = this.handleLinkClick.bind(this)
    document.addEventListener('click', this.handleLinkClick)
  }

  disconnect() {
    // イベントリスナーをクリーンアップ
    if (this.beforeUnloadHandler) {
      window.removeEventListener('beforeunload', this.beforeUnloadHandler)
    }
    document.removeEventListener('click', this.handleLinkClick)
  }

  isFormChanged() {
    // フォームが変更されたかチェック
    const currentFormData = new FormData(this.element)

    // 初期値と現在値を比較
    for (let [key, value] of this.initialFormData.entries()) {
      const currentValue = currentFormData.get(key) || ''
      const initialValue = value || ''

      if (currentValue !== initialValue) {
        return true
      }
    }

    return false
  }

  handleLinkClick(event) {
    // aタグがクリックされた時の処理
    const link = event.target.closest('a')

    if (!link) return
    if (this.isSubmitting) return
    if (this.userConfirmedNavigation) return
    if (!this.isFormChanged()) return

    // フォームが変更されている場合は確認ダイアログを表示
    const message = '日記の内容が保存されていません。このページを離れますか？'
    if (!confirm(message)) {
      event.preventDefault()
      event.stopPropagation()
    } else {
      // ユーザーがOKを押した場合、beforeunload警告をスキップ
      this.userConfirmedNavigation = true
    }
  }
}

