import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]
  static values = { url: String }

  connect() {
    if (this.hasUrlValue && this.urlValue) {
      this.previewTarget.src = this.urlValue
      this.previewTarget.style.display = "block"
    }
  }

  preview(event) {
    const file = event.target.files[0]

    if (!file) {
      this.previewTarget.style.display = "none"
      return
    }

    if (!file.type.match('image.*')) {
      alert('画像ファイルを選択してください')
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.style.display = "block"
    }
    reader.readAsDataURL(file)
  }
}