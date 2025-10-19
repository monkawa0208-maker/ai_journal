import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "wordInput", "meaningInput", "form", "submitButton"]
  static values = { entryId: Number }

  connect() {
    // テキスト選択イベントを設定
    this.boundHandleTextSelection = this.handleTextSelection.bind(this)
    document.addEventListener('mouseup', this.boundHandleTextSelection)
  }

  disconnect() {
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

    // 単語が選択されている場合（1-50文字の英単語）
    if (selectedText && selectedText.length > 0 && selectedText.length < 50) {
      // 英単語のみ（スペースや特殊文字が少ない）
      const wordPattern = /^[a-zA-Z\s'-]+$/
      if (wordPattern.test(selectedText)) {
        this.openModal(selectedText)
      }
    }
  }

  async openModal(word) {
    if (!this.hasModalTarget) {
      return
    }

    // 単語を設定（編集可能）
    this.wordInputTarget.value = word.toLowerCase()
    this.meaningInputTarget.value = ''

    // 既存の単語かチェックして、あれば意味を自動入力
    await this.checkExistingWord(word.toLowerCase())

    this.modalTarget.classList.add('active')

    // 意味が既に入力されている場合は意味フィールドにフォーカス
    if (this.meaningInputTarget.value) {
      this.meaningInputTarget.focus()
    } else {
      this.wordInputTarget.focus()
    }
  }

  async checkExistingWord(word) {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content

      const response = await fetch(`/vocabularies?search=${encodeURIComponent(word)}`, {
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        const data = await response.json()
        // 完全一致する単語があるか確認
        const existingVocab = data.vocabularies?.find(v => v.word === word)

        if (existingVocab) {
          // 既存の単語の場合、意味を自動入力
          this.meaningInputTarget.value = existingVocab.meaning
          this.updateModalTitle('単語を編集')
          return
        }
      }
    } catch (error) {
      // エラーは無視して新規登録モードにする
    }

    this.updateModalTitle('単語を登録')
  }

  updateModalTitle(title) {
    const modalTitle = this.modalTarget.querySelector('h2')
    if (modalTitle) {
      modalTitle.textContent = title
    }
  }

  closeModal(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.remove('active')
    this.meaningInputTarget.value = ''
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

    // 成功通知を表示（新規登録か更新かを区別）
    this.showSuccessNotification(data.vocabulary.word, data.is_new)
  }

  showSuccessNotification(word, isNew = true) {
    // 簡易的な成功通知を画面上部に表示
    const notification = document.createElement('div')
    notification.className = 'word-registered-notification'
    const message = isNew ? `✅ 「${word}」を登録しました` : `✅ 「${word}」を更新しました`
    notification.innerHTML = message
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

      // ヘッダー内に挿入（スティッキーヘッダーの中）
      const header = this.element.querySelector('.entry-detail__header')
      if (header) {
        // 詳細ページの場合、ヘッダー内に挿入
        header.appendChild(vocabulariesDiv)
      } else {
        // 編集ページの場合、フォームの後に挿入
        const formContainer = this.element.querySelector('.form-container')
        if (formContainer) {
          formContainer.appendChild(vocabulariesDiv)
        }
      }
    }

    const tagsContainer = vocabulariesDiv.querySelector('.vocabulary-tags')

    // 「まだ単語が登録されていません」メッセージを削除
    const emptyMessage = vocabulariesDiv.querySelector('p')
    if (emptyMessage) {
      emptyMessage.remove()
    }

    // 既に同じ単語のタグがあるかチェック（単語部分のみで比較）
    const existingTag = Array.from(tagsContainer.querySelectorAll('.vocabulary-tag')).find(
      tag => {
        const text = tag.textContent.trim()
        // 「単語 ： 意味」の形式から単語部分を抽出
        const word = text.split('：')[0].trim()
        return word === vocabulary.word
      }
    )

    if (existingTag) {
      // 既存のタグを更新（意味が変更された可能性があるため）
      existingTag.textContent = `${vocabulary.word} ： ${vocabulary.meaning}`
    } else {
      // なければ新規追加
      const tagLink = document.createElement('a')
      tagLink.href = `/vocabularies#vocab-${vocabulary.id}`
      tagLink.className = 'vocabulary-tag'
      tagLink.textContent = `${vocabulary.word} ： ${vocabulary.meaning}`
      tagsContainer.appendChild(tagLink)
    }
  }
}

