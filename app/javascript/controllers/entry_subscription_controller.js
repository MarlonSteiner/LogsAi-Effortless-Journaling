import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    entryId: Number
  }

  connect() {
    if (this.entryIdValue === 0) return // No entry yet

    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => this.checkStatus(), 3000) // Every 3 seconds
  }

  stopPolling() {
    clearInterval(this.timer)
  }

  checkStatus() {
    fetch(`/journal_entries/${this.entryIdValue}/status`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
      .then(response => {
        if (response.ok) return response.text()
        throw new Error("Polling failed")
      })
      .then(html => Turbo.renderStreamMessage(html))
      .catch(error => {
        console.error(error)
        this.stopPolling()
      })
  }
}
