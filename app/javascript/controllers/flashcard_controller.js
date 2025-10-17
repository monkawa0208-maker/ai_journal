import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "card",
    "frontText",
    "backText",
    "currentIndex",
    "totalCount",
    "masteredBtn",
    "masteredText",
    "prevBtn",
    "nextBtn",
    "modeBtn"
  ]
  static values = { vocabularies: Array }

  connect() {
    this.currentIndex = 0
    this.mode = 'en-ja' // 英→日モード
    this.isFlipped = false

    if (this.vocabulariesValue.length > 0) {
      this.updateCard()
      this.updateButtons()
    }
  }

  switchMode(event) {
    const button = event.currentTarget
    const newMode = button.dataset.mode

    // モードボタンのアクティブ状態を更新
    this.modeBtnTargets.forEach(btn => btn.classList.remove('active'))
    button.classList.add('active')

    this.mode = newMode
    this.isFlipped = false
    this.cardTarget.classList.remove('flipped')
    this.updateCard()
  }

  flipCard() {
    this.isFlipped = !this.isFlipped
    if (this.isFlipped) {
      this.cardTarget.classList.add('flipped')
    } else {
      this.cardTarget.classList.remove('flipped')
    }
  }

  nextCard() {
    if (this.currentIndex < this.vocabulariesValue.length - 1) {
      this.currentIndex++
      this.isFlipped = false
      this.cardTarget.classList.remove('flipped')
      this.updateCard()
      this.updateButtons()
    }
  }

  prevCard() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.isFlipped = false
      this.cardTarget.classList.remove('flipped')
      this.updateCard()
      this.updateButtons()
    }
  }

  updateCard() {
    const vocabulary = this.vocabulariesValue[this.currentIndex]

    if (this.mode === 'en-ja') {
      // 英→日モード
      this.frontTextTarget.textContent = vocabulary.word
      this.backTextTarget.textContent = vocabulary.meaning
    } else {
      // 日→英モード
      this.frontTextTarget.textContent = vocabulary.meaning
      this.backTextTarget.textContent = vocabulary.word
    }

    // 進捗表示を更新
    this.currentIndexTarget.textContent = this.currentIndex + 1
    this.totalCountTarget.textContent = this.vocabulariesValue.length

    // 習得済みボタンの表示を更新
    this.updateMasteredButton(vocabulary.mastered)
  }

  updateButtons() {
    // 前へボタンの状態
    if (this.currentIndex === 0) {
      this.prevBtnTarget.disabled = true
    } else {
      this.prevBtnTarget.disabled = false
    }

    // 次へボタンの状態
    if (this.currentIndex === this.vocabulariesValue.length - 1) {
      this.nextBtnTarget.disabled = true
    } else {
      this.nextBtnTarget.disabled = false
    }
  }

  updateMasteredButton(isMastered) {
    if (isMastered) {
      this.masteredBtnTarget.classList.add('mastered')
      this.masteredTextTarget.textContent = '習得済み ✓'
    } else {
      this.masteredBtnTarget.classList.remove('mastered')
      this.masteredTextTarget.textContent = '習得済みにする'
    }
  }

  async toggleMastered() {
    const vocabulary = this.vocabulariesValue[this.currentIndex]
    const vocabularyId = vocabulary.id

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content

      const response = await fetch(`/vocabularies/${vocabularyId}/toggle_mastered`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // ローカルのデータを更新
        this.vocabulariesValue[this.currentIndex].mastered = data.mastered

        // ボタンの表示を更新
        this.updateMasteredButton(data.mastered)
      } else {
        console.error('習得済みフラグの更新に失敗しました:', data.error)
        alert('更新に失敗しました')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('通信エラーが発生しました')
    }
  }

  // キーボードショートカット
  handleKeyPress(event) {
    if (event.key === 'ArrowLeft') {
      this.prevCard()
    } else if (event.key === 'ArrowRight') {
      this.nextCard()
    } else if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault()
      this.flipCard()
    }
  }

  // キーボードイベントの登録
  initialize() {
    this.boundHandleKeyPress = this.handleKeyPress.bind(this)
    document.addEventListener('keydown', this.boundHandleKeyPress)
  }

  // クリーンアップ
  disconnect() {
    if (this.boundHandleKeyPress) {
      document.removeEventListener('keydown', this.boundHandleKeyPress)
    }
  }
}

