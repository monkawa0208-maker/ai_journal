import { Controller } from "@hotwired/stimulus"

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
      const response = await fetch(`/vocabularies/${this.idValue}/toggle_mastered`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        }
      })

      const data = await response.json()

      if (response.ok) {
        this.masteredValue = data.mastered
        this.masteredIconTarget.textContent = data.mastered ? '✅' : '○'
        this.updateButtonStyles()
      } else {
        alert('エラーが発生しました: ' + data.error)
      }
    } catch (error) {
      console.error('Error toggling mastered:', error)
      alert('エラーが発生しました')
    }
  }

  async toggleFavorited() {
    try {
      const response = await fetch(`/vocabularies/${this.idValue}/toggle_favorited`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        }
      })

      const data = await response.json()

      if (response.ok) {
        this.favoritedValue = data.favorited
        this.favoritedIconTarget.textContent = data.favorited ? '⭐' : '☆'
        this.updateButtonStyles()
      } else {
        alert('エラーが発生しました: ' + data.error)
      }
    } catch (error) {
      console.error('Error toggling favorited:', error)
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

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}

