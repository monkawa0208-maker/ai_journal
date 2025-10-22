import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "wordInput", "meaningInput", "form", "submitButton"]
  static values = { entryId: Number }

  connect() {
    // テキスト選択イベントを設定（マウス + タッチ）
    this.boundHandleTextSelection = this.handleTextSelection.bind(this)
    document.addEventListener('mouseup', this.boundHandleTextSelection)
    document.addEventListener('touchend', this.boundHandleTextSelection)

    // タッチ位置の追跡用
    this.touchStartX = null
    this.touchStartY = null
    this.touchStartTime = null
    this.touchedElement = null

    // 単語選択可能エリアを取得してマウスオーバーイベントを追加
    this.setupWordHighlight()
  }

  disconnect() {
    if (this.boundHandleTextSelection) {
      document.removeEventListener('mouseup', this.boundHandleTextSelection)
      document.removeEventListener('touchend', this.boundHandleTextSelection)
    }
    if (this.selectableAreas) {
      this.selectableAreas.forEach(area => {
        area.removeEventListener('mouseover', this.boundHandleMouseOver)
        area.removeEventListener('mouseout', this.boundHandleMouseOut)
        area.removeEventListener('touchstart', this.boundHandleTouchStart)
        area.removeEventListener('touchend', this.boundHandleTouchEnd)
        area.removeEventListener('touchcancel', this.boundHandleTouchCancel)
      })
    }
  }

  setupWordHighlight() {
    // ハイライト対象のエリアをすべて取得
    this.selectableAreas = this.element.querySelectorAll('.word-selectable, .ai-feedback-content, .ai-translation-content')
    if (!this.selectableAreas || this.selectableAreas.length === 0) return

    // マウスイベントをバインド
    this.boundHandleMouseOver = this.handleMouseOver.bind(this)
    this.boundHandleMouseOut = this.handleMouseOut.bind(this)

    // タッチイベントをバインド
    this.boundHandleTouchStart = this.handleTouchStart.bind(this)
    this.boundHandleTouchEnd = this.handleTouchEnd.bind(this)
    this.boundHandleTouchCancel = this.handleTouchCancel.bind(this)

    // 各エリアに対して処理
    this.selectableAreas.forEach(area => {
      // テキストコンテンツを単語ごとにspanでラップ
      this.wrapWordsInSpans(area)

      // イベントリスナーを追加（マウス）
      area.addEventListener('mouseover', this.boundHandleMouseOver)
      area.addEventListener('mouseout', this.boundHandleMouseOut)

      // イベントリスナーを追加（タッチ）
      area.addEventListener('touchstart', this.boundHandleTouchStart, { passive: true })
      area.addEventListener('touchend', this.boundHandleTouchEnd)
      area.addEventListener('touchcancel', this.boundHandleTouchCancel)
    })
  }

  wrapWordsInSpans(container) {
    // 既にラップされている場合はスキップ
    if (container.querySelector('.word-wrapper')) return

    // すべてのテキストを含む要素を処理
    const walkNode = (node) => {
      if (node.nodeType === Node.TEXT_NODE) {
        const text = node.textContent
        if (text.trim() && /[a-zA-Z]/.test(text)) {
          // 英単語を含むテキストノードを安全に分割してDOMを再構築
          const fragment = document.createDocumentFragment()
          const parts = text.split(/([a-zA-Z'-]+)/)
          parts.forEach(part => {
            if (!part) return
            if (/^[a-zA-Z'-]+$/.test(part)) {
              const wordSpan = document.createElement('span')
              wordSpan.className = 'word-wrapper'
              wordSpan.textContent = part
              fragment.appendChild(wordSpan)
            } else {
              fragment.appendChild(document.createTextNode(part))
            }
          })
          node.parentNode.replaceChild(fragment, node)
        }
      } else if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'SCRIPT' && node.tagName !== 'STYLE') {
        // 子ノードを処理（strong, brタグなども対応）
        const children = Array.from(node.childNodes)
        children.forEach(child => walkNode(child))
      }
    }

    walkNode(container)
  }

  handleMouseOver(event) {
    const target = event.target

    // word-wrapperクラスを持つspan要素の場合のみハイライト
    if (target.classList && target.classList.contains('word-wrapper')) {
      target.classList.add('word-hover')
    }
  }

  handleMouseOut(event) {
    const target = event.target

    // word-wrapperクラスを持つspan要素からホバーを解除
    if (target.classList && target.classList.contains('word-wrapper')) {
      target.classList.remove('word-hover')
    }
  }

  handleTouchStart(event) {
    // タッチ開始位置と時刻を記録
    const touch = event.touches[0]
    this.touchStartX = touch.clientX
    this.touchStartY = touch.clientY
    this.touchStartTime = Date.now()

    // タッチされた要素を記録
    const target = event.target
    if (target.classList && target.classList.contains('word-wrapper')) {
      this.touchedElement = target
      // タッチ時のハイライト表示
      target.classList.add('word-hover')
    }
  }

  handleTouchEnd(event) {
    // タッチ終了位置を取得
    const touch = event.changedTouches[0]
    const touchEndX = touch.clientX
    const touchEndY = touch.clientY
    const touchEndTime = Date.now()

    // 移動距離を計算（スクロールと区別するため）
    const moveDistance = Math.sqrt(
      Math.pow(touchEndX - this.touchStartX, 2) +
      Math.pow(touchEndY - this.touchStartY, 2)
    )

    // タッチ時間を計算
    const touchDuration = touchEndTime - this.touchStartTime

    // ハイライトを解除
    if (this.touchedElement) {
      this.touchedElement.classList.remove('word-hover')
    }

    // 移動距離が小さい（10px以下）かつ短時間（500ms以下）のタップの場合のみ処理
    // = スクロールや長押しではない通常のタップ
    if (moveDistance < 10 && touchDuration < 500 && this.touchedElement) {
      // word-wrapperをタップした場合、モーダルを開く
      const word = this.touchedElement.textContent.trim()
      if (word) {
        // デフォルトのテキスト選択動作を防ぐ
        event.preventDefault()
        this.openModal(word)
      }
    }

    // リセット
    this.touchedElement = null
    this.touchStartX = null
    this.touchStartY = null
    this.touchStartTime = null
  }

  handleTouchCancel(event) {
    // タッチがキャンセルされた場合、ハイライトを解除
    if (this.touchedElement) {
      this.touchedElement.classList.remove('word-hover')
      this.touchedElement = null
    }
    this.touchStartX = null
    this.touchStartY = null
    this.touchStartTime = null
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

      // show画面のヘッダー内に挿入
      const header = this.element.querySelector('.entry-detail__header')
      if (header) {
        header.appendChild(vocabulariesDiv)
      }
    }

    const tagsContainer = vocabulariesDiv.querySelector('.vocabulary-tags')

    // 「まだ単語が登録されていません」メッセージを削除
    const emptyMessage = tagsContainer.querySelector('p')
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
      tagLink.href = `/vocabularies/${vocabulary.id}/edit`
      tagLink.className = 'vocabulary-tag'
      tagLink.textContent = `${vocabulary.word} ： ${vocabulary.meaning}`
      tagsContainer.appendChild(tagLink)
    }
  }
}

