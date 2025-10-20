import { Controller } from "@hotwired/stimulus"
import { ControllerUtils } from "./utils"

export default class extends Controller {
  static targets = ["masteredButton", "masteredIcon", "favoritedButton", "favoritedIcon"]
  static values = {
    id: Number,
    mastered: Boolean,
    favorited: Boolean
  }

  connect() {
    console.log("Vocabulary card controller connected", this.idValue)
    this.updateButtonStyles()
  }

  async toggleMastered() {
    try {
      const { success, data, error } = await ControllerUtils.makeRequest(`/vocabularies/${this.idValue}/toggle_mastered`, { method: 'PATCH' })
      if (success) {
        this.masteredValue = data.mastered
        this.masteredIconTarget.textContent = data.mastered ? '✅' : '○'
        this.updateButtonStyles()
      } else {
        alert('エラーが発生しました: ' + (error || ''))
      }
    } catch (_) {
      alert('エラーが発生しました')
    }
  }

  async toggleFavorited() {
    try {
      const { success, data, error } = await ControllerUtils.makeRequest(`/vocabularies/${this.idValue}/toggle_favorited`, { method: 'PATCH' })
      if (success) {
        this.favoritedValue = data.favorited
        this.favoritedIconTarget.textContent = data.favorited ? '⭐' : '☆'
        this.updateButtonStyles()
      } else {
        alert('エラーが発生しました: ' + (error || ''))
      }
    } catch (_) {
      alert('エラーが発生しました')
    }
  }

  updateButtonStyles() {
    // 習得済みボタンのスタイル更新
    if (this.masteredValue) {
      this.masteredButtonTarget.classList.add('active')
    } else {
      this.masteredButtonTarget.classList.remove('active')
    }

    // お気に入りボタンのスタイル更新
    if (this.favoritedValue) {
      this.favoritedButtonTarget.classList.add('active')
    } else {
      this.favoritedButtonTarget.classList.remove('active')
    }
  }

  // CSRF取得はControllerUtilsに統一
}

