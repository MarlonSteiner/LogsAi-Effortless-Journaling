// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordingInterface", "entryDisplay", "textEntryForm", "dateInput", "calendarSection", "calendarContainer", "dateCard"]
  static values = {
    currentDate: String,
    createUrl: String,
    showUrl: String
  }

  connect() {
    this.loadEntryForDate()
    this.setupScrollDetection() // Add this line

    setTimeout(() => {
      this.centerOnDate(this.currentDateValue)
      this.selectDateCard(this.currentDateValue)
    }, 100)
  }

  centerOnDate(dateString) {
    const targetCard = this.dateCardTargets.find(card =>
      card.dataset.date === dateString
    )

    if (targetCard && this.hasCalendarContainerTarget) {
      const container = this.calendarContainerTarget
      const cardOffsetLeft = targetCard.offsetLeft
      const cardWidth = targetCard.offsetWidth
      const containerWidth = container.offsetWidth

      const scrollPosition = cardOffsetLeft - (containerWidth / 2) + (cardWidth / 2)

      // Changed to smooth animation
      container.scrollTo({
        left: Math.max(0, scrollPosition),
        behavior: 'smooth'
      })
    }
  }

  setupScrollDetection() {
    if (this.hasCalendarContainerTarget) {
      let scrollTimeout
      this.calendarContainerTarget.addEventListener('scroll', () => {
        clearTimeout(scrollTimeout)
        scrollTimeout = setTimeout(() => {
          this.updateSelectionFromScroll()
        }, 50) // Very fast response
      })
    }
  }

  // NEW method
  selectDateCard(dateString) {
    const targetCard = this.dateCardTargets.find(card =>
      card.dataset.date === dateString
    )
    if (targetCard) {
      this.updateSelectedDate(targetCard)
    }
  }

  setupScrollDetection() {
    if (this.hasCalendarContainerTarget) {
      let scrollTimeout
      this.calendarContainerTarget.addEventListener('scroll', () => {
        clearTimeout(scrollTimeout)
        scrollTimeout = setTimeout(() => {
          this.updateSelectionFromScroll()
        }, 50) // Fast response
      })
    }
  }

  updateSelectionFromScroll() {
    if (!this.hasCalendarContainerTarget) return

    const container = this.calendarContainerTarget
    const containerCenter = container.scrollLeft + (container.offsetWidth / 2)

    let bestCard = null
    let bestScore = 0

    this.dateCardTargets.forEach(card => {
      const cardLeft = card.offsetLeft
      const cardRight = cardLeft + card.offsetWidth
      const cardCenter = cardLeft + (card.offsetWidth / 2)

      // How much of the card is in the center area
      const centerAreaLeft = containerCenter - (card.offsetWidth * 0.4)
      const centerAreaRight = containerCenter + (card.offsetWidth * 0.4)

      const overlapLeft = Math.max(cardLeft, centerAreaLeft)
      const overlapRight = Math.min(cardRight, centerAreaRight)
      const overlap = Math.max(0, overlapRight - overlapLeft)
      const overlapScore = overlap / card.offsetWidth

      if (overlapScore > bestScore && overlapScore > 0.6) {
        bestScore = overlapScore
        bestCard = card
      }
    })

    if (bestCard && bestCard.dataset.date !== this.currentDateValue) {
      this.currentDateValue = bestCard.dataset.date
      this.updateSelectedDate(bestCard)
      this.loadEntryForDate()
      this.updateFormDate(bestCard.dataset.date)
      this.updateControllerDates(bestCard.dataset.date)
    }
  }

  updateControllerDates(date) {
  // Update the audio controller's entry date
    const audioController = this.application.getControllerForElementAndIdentifier(this.element, 'audio')
    if (audioController) {
      audioController.entryDateValue = date
    }

    // Update the camera controller's entry date
    const cameraElement = document.querySelector('[data-controller*="camera"]')
    const cameraController = cameraElement ? this.application.getControllerForElementAndIdentifier(cameraElement, 'camera') : null
    if (cameraController) {
      cameraController.entryDateValue = date
    }
  }

  // NEW METHOD - Handle clicking on calendar dates
  loadDateContent(event) {
    const date = event.currentTarget.dataset.date

    // Update selected date styling
    this.updateSelectedDate(event.currentTarget)

    // Update the current date and load content
    this.currentDateValue = date
    this.loadEntryForDate()

    // Update the form date field
    this.updateFormDate(date)

    // Update the audio controller's entry date
    const audioController = this.application.getControllerForElementAndIdentifier(this.element, 'audio')
    if (audioController) {
      audioController.entryDateValue = date
    }

    // Update the camera controller's entry date (fixed search)
    const cameraElement = document.querySelector('[data-controller*="camera"]')
    const cameraController = cameraElement ? this.application.getControllerForElementAndIdentifier(cameraElement, 'camera') : null
    if (cameraController) {
      cameraController.entryDateValue = date
    }

    // Center the clicked date
    this.centerOnDate(date)
  }

  // NEW METHOD - Visual feedback for selected date
  updateSelectedDate(clickedElement) {
    const allDateCards = this.element.querySelectorAll('.date-card')
    allDateCards.forEach(card => {
      card.classList.remove('bg-primary', 'text-white')
    })
    clickedElement.classList.add('bg-primary', 'text-white')
  }

  // NEW METHOD - Update form date when date changes
  updateFormDate(date) {
    const dateInput = this.textEntryFormTarget.querySelector('input[name="journal_entry[entry_date]"]')
    if (dateInput) {
      dateInput.value = date
    }
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
    console.log('Entry data:', entry);
    
    const titleElement = this.entryDisplayTarget.querySelector('.entry-title')
    const nutshellElement = this.entryDisplayTarget.querySelector('.entry-nutshell')
    const summaryElement = this.entryDisplayTarget.querySelector('.entry-summary')
    const mediaElement = this.entryDisplayTarget.querySelector('.entry-media')
    const moodElement = this.entryDisplayTarget.querySelector('.entry-mood')

    if (titleElement) titleElement.textContent = entry.title || 'Untitled Entry'
    if (nutshellElement) nutshellElement.textContent = entry.ai_nutshell || ''
    if (summaryElement) summaryElement.textContent = entry.ai_summary || ''

    // Banner display here:
    const bannerElement = this.entryDisplayTarget.querySelector('.entry-banner')
    if (bannerElement && entry.ai_banner_image_url) {
      bannerElement.innerHTML = `<img src="${entry.ai_banner_image_url}" alt="Mood banner" class="banner-image">`
      bannerElement.style.display = 'block'
    } else if (bannerElement) {
      bannerElement.innerHTML = '<button class="regenerate-banner-btn">Generate Banner</button>'
      bannerElement.style.display = 'block'
    }

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
    // Just update the main dashboard - don't dispatch another event!
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
