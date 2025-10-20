import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static values = {
    entriesUrl: String
  }

  connect() {
    if (!this.hasEntriesUrlValue || !this.entriesUrlValue) {
      console.error('Calendar: entriesUrl is not provided')
      return
    }
    this.initializeCalendar()

    // カスタムイベントリスナーを追加
    this.resizeHandler = this.handleResize.bind(this)
    this.element.addEventListener("calendar:resize", this.resizeHandler)
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy()
    }

    // イベントリスナーをクリーンアップ
    if (this.resizeHandler) {
      this.element.removeEventListener("calendar:resize", this.resizeHandler)
    }
  }

  handleResize() {
    if (this.calendar) {
      this.calendar.updateSize()
    }
  }

  async initializeCalendar() {
    try {
      // エントリーデータを取得
      const response = await fetch(this.entriesUrlValue)

      // レスポンスが成功したかチェック
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const entries = await response.json()

      // エントリーをFullCalendar用のイベントに変換
      const events = entries.map(entry => ({
        id: entry.id,
        title: entry.title || '無題',
        start: entry.posted_on,
        url: `/entries/${entry.id}`,
        backgroundColor: '#667eea',
        borderColor: '#667eea',
        textColor: '#ffffff'
      }))

      // FullCalendarを初期化
      this.calendar = new Calendar(this.element, {
        plugins: [dayGridPlugin, interactionPlugin],
        initialView: 'dayGridMonth',
        locale: 'ja',
        headerToolbar: {
          left: 'prev',
          center: 'title',
          right: 'next'
        },
        buttonText: {
          today: '今月'
        },
        firstDay: 0, // 日曜日始まり
        height: 'auto',
        events: events,
        eventClick: (info) => {
          info.jsEvent.preventDefault()
          if (info.event.url) {
            window.location.href = info.event.url
          }
        },
        // dateClick: (info) => {
        //   // 日付クリック時の処理（新規投稿ページへ遷移）
        //   const date = info.dateStr
        //   window.location.href = `/entries/new?entry[posted_on]=${date}`
        // },
        // カスタムボタンのスタイル
        buttonIcons: {
          prev: 'chevron-left',
          next: 'chevron-right'
        },
        dayCellContent: (arg) => {
          return arg.dayNumberText.replace('日', '')
        }
      })

      this.calendar.render()
    } catch (error) {
      console.error('Calendar initialization failed:', error)
    }
  }
}

