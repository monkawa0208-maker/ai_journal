import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "wordInput", "meaningInput", "form", "submitButton"]
  static values = { entryId: Number }

  connect() {
    console.log('WordSelectorController connected')
    console.log('Entry ID:', this.entryIdValue)
    console.log('Modal target:', this.modalTarget)

    // テキスト選択イベントを設定
    this.boundHandleTextSelection = this.handleTextSelection.bind(this)
    document.addEventListener('mouseup', this.boundHandleTextSelection)
  }

  disconnect() {
    console.log('WordSelectorController disconnected')
    if (this.boundHandleTextSelection) {
      document.removeEventListener('mouseup', this.boundHandleTextSelection)
    }
  }

  handleTextSelection(event) {
    // モーダル外でのテキスト選択のみ処理
    if (this.hasModalTarget && this.modalTarget.classList.contains('active')) {
      return
    }

    const selection = window.getSelection()
    const selectedText = selection.toString().trim()

    console.log('Text selected:', selectedText)

    // 単語が選択されている場合（1-50文字の英単語）
    if (selectedText && selectedText.length > 0 && selectedText.length < 50) {
      // 英単語のみ（スペースや特殊文字が少ない）
      const wordPattern = /^[a-zA-Z\s'-]+$/
      if (wordPattern.test(selectedText)) {
        console.log('Opening modal for word:', selectedText)
        this.openModal(selectedText)
      }
    }
  }

  openModal(word) {
    console.log('openModal called with word:', word)

    if (!this.hasModalTarget) {
      console.error('Modal target not found!')
      return
    }

    this.wordInputTarget.value = word.toLowerCase()
    this.meaningInputTarget.value = ''
    this.modalTarget.classList.add('active')
    console.log('Modal classes:', this.modalTarget.classList)
    this.meaningInputTarget.focus()
  }

  closeModal(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.remove('active')
    this.meaningInputTarget.value = ''
  }

  // テスト用：手動でモーダルを開く
  testModal(event) {
    event.preventDefault()
    console.log('Test modal button clicked')
    this.openModal('test')
  }

  async submitWord(event) {
    event.preventDefault()

    const word = this.wordInputTarget.value.trim()
    const meaning = this.meaningInputTarget.value.trim()

    if (!word || !meaning) {
      alert('単語と意味を入力してください')
      return
    }

    // ボタンを無効化
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = '登録中...'

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content

      const response = await fetch('/vocabularies/add_from_entry', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          word: word,
          meaning: meaning,
          entry_id: this.entryIdValue
        })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.handleSuccess(data)
      } else {
        this.handleError(data.error || '単語の登録に失敗しました')
      }
    } catch (error) {
      console.error('Error:', error)
      this.handleError('通信エラーが発生しました')
    } finally {
      // ボタンを有効化
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = '登録'
    }
  }

  handleSuccess(data) {
    // 登録済み単語タグを更新（ページをリロードせずに）
    this.updateVocabularyTags(data.vocabulary)

    // モーダルを閉じる
    this.closeModal()

    // 成功通知を表示（アラートまたは通知）
    this.showSuccessNotification(data.vocabulary.word)
  }

  showSuccessNotification(word) {
    // 簡易的な成功通知を画面上部に表示
    const notification = document.createElement('div')
    notification.className = 'word-registered-notification'
    notification.innerHTML = `✅ 「${word}」を登録しました`
    notification.style.cssText = `
      position: fixed;
      top: 80px;
      right: 20px;
      background: #4CAF50;
      color: white;
      padding: 1rem 1.5rem;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 2000;
      animation: slideInRight 0.3s ease-out;
    `

    document.body.appendChild(notification)

    // 3秒後に自動で消す
    setTimeout(() => {
      notification.style.animation = 'slideOutRight 0.3s ease-in'
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, 3000)
  }

  handleError(errorMessage) {
    alert(errorMessage)
  }

  updateVocabularyTags(vocabulary) {
    // 既存の単語タグセクションを探す
    let vocabulariesDiv = this.element.querySelector('.entry-vocabularies')

    // 初めて単語を登録する場合、セクションを作成
    if (!vocabulariesDiv) {
      vocabulariesDiv = document.createElement('div')
      vocabulariesDiv.className = 'entry-vocabularies'
      vocabulariesDiv.innerHTML = `
        <h3>この日記で登録した単語:</h3>
        <div class="vocabulary-tags"></div>
      `

      // word-selectableの後に挿入
      const wordSelectable = this.element.querySelector('.word-selectable')
      if (wordSelectable) {
        // 詳細ページの場合
        wordSelectable.after(vocabulariesDiv)
      } else {
        // 編集ページの場合、フォームの後に挿入
        const formContainer = this.element.querySelector('.form-container')
        if (formContainer) {
          formContainer.appendChild(vocabulariesDiv)
        }
      }
    }

    const tagsContainer = vocabulariesDiv.querySelector('.vocabulary-tags')

    // 既に同じ単語のタグがあるかチェック
    const existingTag = Array.from(tagsContainer.querySelectorAll('.vocabulary-tag')).find(
      tag => tag.textContent.trim() === vocabulary.word
    )

    // なければ追加
    if (!existingTag) {
      const tagLink = document.createElement('a')
      tagLink.href = `/vocabularies#vocab-${vocabulary.id}`
      tagLink.className = 'vocabulary-tag'
      tagLink.textContent = vocabulary.word
      tagsContainer.appendChild(tagLink)
    }
  }
}

