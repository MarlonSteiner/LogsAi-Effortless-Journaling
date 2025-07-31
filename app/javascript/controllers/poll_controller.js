// app/javascript/controllers/poll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, interval: Number }

  connect() {
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => {
      fetch(this.urlValue, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })
        .then(response => response.text())
        .then(html => Turbo.renderStreamMessage(html))
    }, this.intervalValue || 2000) // default: poll every 2 seconds
  }

  stopPolling() {
    clearInterval(this.timer)
  }
}
