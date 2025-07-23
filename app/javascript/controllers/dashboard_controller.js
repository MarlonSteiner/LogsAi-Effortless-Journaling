// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordingInterface", "entryDisplay", "entryTitle", "entryNutshell", "entryFullText", "entryMedia", "loadingState"]

  connect() {
    this.selectedDate = new Date().toISOString().split('T')[0]
    this.currentEntry = null
    // Note: Calendar generation will be handled by your teammate's navbar
    this.loadEntryForSelectedDate()
  }

  // Make selectedDate accessible to other controllers
  get selectedDate() {
    return this._selectedDate || new Date().toISOString().split('T')[0]
  }

  set selectedDate(date) {
    this._selectedDate = date
  }

  // Method for your teammate's navbar to call when date changes
  setSelectedDate(date) {
    this.selectedDate = date
    this.loadEntryForSelectedDate()
  }

  async loadEntryForSelectedDate() {
    try {
      const response = await fetch(`/journal_entries/for_date/${this.selectedDate}`)
      const data = await response.json()

      if (data.success && data.entry) {
        this.showEntryDisplay(data.entry)
      } else {
        this.showRecordingInterface()
      }
    } catch (error) {
      console.error('Error loading entry:', error)
      this.showRecordingInterface()
    }
  }

  showRecordingInterface() {
    this.recordingInterfaceTarget.style.display = 'block'
    this.entryDisplayTarget.style.display = 'none'
    this.currentEntry = null
  }

  showEntryDisplay(entry) {
    this.recordingInterfaceTarget.style.display = 'none'
    this.entryDisplayTarget.style.display = 'block'

    // Populate entry data with null checks
    this.entryTitleTarget.textContent = entry.title || 'Untitled Entry'
    this.entryNutshellTarget.textContent = entry.ai_nutshell || entry.ai_summary || (entry.content ? entry.content.substring(0, 100) + '...' : 'No content available')
    this.entryFullTextTarget.textContent = entry.ai_summary || entry.content || 'No content available'

    // Show media if exists
    if (entry.has_media && entry.media_url) {
      this.entryMediaTarget.style.display = 'block'

      if (entry.media_type === 'image') {
        this.entryMediaTarget.innerHTML = `<img src="${entry.media_url}" style="max-width: 100%; border-radius: 8px;">`
      } else if (entry.media_type === 'video') {
        this.entryMediaTarget.innerHTML = `<video controls style="max-width: 100%; border-radius: 8px;"><source src="${entry.media_url}"></video>`
      }
    } else {
      this.entryMediaTarget.style.display = 'none'
    }

    this.currentEntry = entry
  }

  // Refresh content after camera upload
  refreshContent() {
    this.loadEntryForSelectedDate()
  }

  // Action methods
  startRecording() {
    alert('Recording functionality will be implemented by your teammate')
  }

  openTextEntry() {
    window.location.href = '/journal_entries/new'
  }

  toggleEntryOptions() {
    alert('Entry options menu to be implemented')
  }

  toggleNutshellOptions() {
    alert('Nutshell options menu to be implemented')
  }
}
