import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "grid"]

  connect() {
    // 初期化時に何もしない（検索はサーバーサイドで実装）
  }

  search() {
    const searchTerm = this.searchInputTarget.value.toLowerCase().trim()
    const cards = this.gridTarget.querySelectorAll('.vocabulary-card')

    cards.forEach(card => {
      const word = card.dataset.word?.toLowerCase() || ''

      if (word.includes(searchTerm)) {
        card.style.display = 'block'
      } else {
        card.style.display = 'none'
      }
    })

    // 検索結果が0件の場合のメッセージ表示（オプション）
    const visibleCards = Array.from(cards).filter(card => card.style.display !== 'none')
    this.updateEmptyState(visibleCards.length === 0)
  }

  updateEmptyState(isEmpty) {
    let emptyMessage = this.element.querySelector('.vocabulary-empty-search')

    if (isEmpty) {
      if (!emptyMessage) {
        emptyMessage = document.createElement('div')
        emptyMessage.className = 'vocabulary-empty vocabulary-empty-search'
        emptyMessage.innerHTML = '<p>検索結果が見つかりませんでした。</p>'
        this.gridTarget.after(emptyMessage)
      }
      this.gridTarget.style.display = 'none'
    } else {
      if (emptyMessage) {
        emptyMessage.remove()
      }
      this.gridTarget.style.display = 'grid'
    }
  }

  // フィルターはサーバーサイド（リンククリック）で実装されているため、
  // クライアントサイドでの追加フィルタリングは不要
  // 必要に応じて、将来的にクライアントサイドフィルタリングを追加可能
}

