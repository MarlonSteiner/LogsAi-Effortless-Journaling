// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordingInterface", "entryDisplay", "textEntryForm", "dateInput", "calendarSection"]
  static values = {
    currentDate: String,
    createUrl: String,
    showUrl: String
  }

  connect() {
    this.loadEntryForDate()
  }

  // Handle date changes
  dateChanged() {
    const newDate = this.dateInputTarget.value
    this.currentDateValue = newDate
    this.loadEntryForDate()
  }

  // Load entry for current date
  async loadEntryForDate() {
    try {
      const url = this.showUrlValue.replace('DATE_PLACEHOLDER', this.currentDateValue)
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()

      if (result.entry) {
        this.showEntryDisplay(result.entry)
      } else {
        this.showRecordingInterface()
      }
    } catch (error) {
      console.error('Error loading entry:', error)
      this.showRecordingInterface() // Default to recording interface on error
    }
  }

  // Show recording interface (no entry exists)
  showRecordingInterface() {
    this.recordingInterfaceTarget.style.display = 'block'
    this.entryDisplayTarget.style.display = 'none'
    this.textEntryFormTarget.style.display = 'none'
    this.calendarSectionTarget.style.display = 'block' // Show calendar
  }

  // Show entry display (entry exists)
  showEntryDisplay(entry) {
    this.recordingInterfaceTarget.style.display = 'none'
    this.textEntryFormTarget.style.display = 'none'
    this.entryDisplayTarget.style.display = 'block'
    this.calendarSectionTarget.style.display = 'block' // Show calendar

    this.updateEntryContent(entry)
  }

  // Update entry content in the display
  updateEntryContent(entry) {
    const titleElement = this.entryDisplayTarget.querySelector('.entry-title')
    const nutshellElement = this.entryDisplayTarget.querySelector('.entry-nutshell')
    const summaryElement = this.entryDisplayTarget.querySelector('.entry-summary')
    const mediaElement = this.entryDisplayTarget.querySelector('.entry-media')
    const moodElement = this.entryDisplayTarget.querySelector('.entry-mood')

    if (titleElement) titleElement.textContent = entry.title || 'Untitled Entry'
    if (nutshellElement) nutshellElement.textContent = entry.ai_nutshell || ''
    if (summaryElement) summaryElement.textContent = entry.ai_summary || ''

    // Handle mood display
    if (moodElement && entry.ai_mood_label) {
      moodElement.textContent = entry.ai_mood_label
      moodElement.className = `entry-mood mood-${entry.ai_mood_label.toLowerCase().replace(/\s+/g, '-')}`
    }

    // Handle media display
    if (mediaElement && entry.media_url) {
      this.displayMedia(mediaElement, entry)
    }
  }

  // Display media based on input type
  displayMedia(container, entry) {
    container.innerHTML = '' // Clear previous content

    if (!entry.media_url) return

    switch (entry.input_type) {
      case 'image':
        const img = document.createElement('img')
        img.src = entry.media_url
        img.alt = 'Journal entry image'
        img.className = 'img-fluid rounded'
        container.appendChild(img)
        break

      case 'video':
        const video = document.createElement('video')
        video.src = entry.media_url
        video.controls = true
        video.className = 'w-100 rounded'
        video.setAttribute('playsinline', '')
        container.appendChild(video)
        break

      case 'audio':
        // Don't show anything for audio - just transcribed text
        break

      case 'text':
        // Text entries don't have media files
        const textIndicator = document.createElement('div')
        textIndicator.className = 'text-entry-indicator'
        textIndicator.innerHTML = '<i class="fas fa-pen"></i> Text Entry'
        container.appendChild(textIndicator)
        break
    }
  }

  // Show text entry form
  showTextForm() {
    this.recordingInterfaceTarget.style.display = 'none'
    this.entryDisplayTarget.style.display = 'none'
    this.textEntryFormTarget.style.display = 'block'
    this.calendarSectionTarget.style.display = 'none' // Hide calendar in text form
  }

  // Submit text entry (UPDATED for Ajax calendar integration)
  async submitTextEntry(event) {
    event.preventDefault()

    const formData = new FormData(event.target)

    try {
      const response = await fetch(this.createUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) throw new Error('Failed to create entry')

      const result = await response.json()

      if (result.success) {
        // Trigger custom event for calendar to listen
        window.dispatchEvent(new CustomEvent('entryCreated', {
          detail: result.entry
        }))

        // Update the main dashboard
        this.showEntryDisplay(result.entry)

        // Reset form
        event.target.reset()
      } else {
        console.error('Text entry creation failed:', result.errors)
        alert('Failed to create entry')
      }
    } catch (error) {
      console.error('Error creating text entry:', error)
      alert('Failed to create entry')
    }
  }

  // Handle entry creation from audio controller (UPDATED for Ajax calendar integration)
  entryCreated(event) {
    const entry = event.detail

    // Trigger custom event for calendar to listen
    window.dispatchEvent(new CustomEvent('entryCreated', {
      detail: entry
    }))

    // Update the main dashboard
    this.showEntryDisplay(entry)
  }

  // Navigate to text entry form
  goToTextEntry() {
    window.location.href = `/journal_entries/new?date=${this.currentDateValue}`
  }

  // Handle edit entry
  editEntry() {
    // You can implement edit functionality here
    console.log('Edit entry clicked')
  }

  // Handle delete entry
  async deleteEntry() {
    if (!confirm('Are you sure you want to delete this entry?')) {
      return
    }

    try {
      const response = await fetch(`/journal_entries/${this.currentEntryId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        this.showRecordingInterface()
      } else {
        alert('Failed to delete entry. Please try again.')
      }
    } catch (error) {
      console.error('Error deleting entry:', error)
      alert('An error occurred. Please try again.')
    }
  }
}
