import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "tabContent"]

  connect() {
    console.log("Entry tabs controller connected")
  }

  switchTab(event) {
    const clickedButton = event.currentTarget
    const targetTab = clickedButton.dataset.tab

    // すべてのタブボタンからactiveクラスを削除
    this.tabButtonTargets.forEach(button => {
      button.classList.remove("active")
    })

    // クリックされたタブボタンにactiveクラスを追加
    clickedButton.classList.add("active")

    // すべてのタブコンテンツを非表示にする
    this.tabContentTargets.forEach(content => {
      content.classList.add("hidden")
    })

    // 対応するタブコンテンツを表示
    const targetContent = this.tabContentTargets.find(
      content => content.dataset.tab === targetTab
    )

    if (targetContent) {
      targetContent.classList.remove("hidden")

      // カレンダータブが表示された場合、カレンダーをリサイズ
      if (targetTab === "calendar") {
        // 少し遅延させてからリサイズイベントを発火
        setTimeout(() => {
          const calendarElement = targetContent.querySelector("#fullcalendar")
          if (calendarElement) {
            // カスタムイベントを発火してカレンダーにリサイズを通知
            const event = new CustomEvent("calendar:resize")
            calendarElement.dispatchEvent(event)
          }
        }, 100)
      }
    }
  }
}

