// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordingInterface", "entryDisplay", "textEntryForm", "dateInput", "calendarSection", "calendarContainer", "dateCard"]
  static values = {
    currentDate: String,
    createUrl: String,
    showUrl: String,
    editingEntryId: Number
  }

  connect() {
    this.loadEntryForDate()
    this.setupScrollDetection() // Add this line

    setTimeout(() => {
      this.centerOnDate(this.currentDateValue)
      this.selectDateCard(this.currentDateValue)
    }, 50)
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

      // Smooth scroll animation
      container.scrollTo({
        left: Math.max(0, scrollPosition),
        behavior: 'smooth'
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

      // SNAPPY: Use your original overlap logic but with better threshold
      const centerAreaLeft = containerCenter - (card.offsetWidth * 0.4) // Reduced for more responsive
      const centerAreaRight = containerCenter + (card.offsetWidth * 0.4) // Reduced for more responsive

      const overlapLeft = Math.max(cardLeft, centerAreaLeft)
      const overlapRight = Math.min(cardRight, centerAreaRight)
      const overlap = Math.max(0, overlapRight - overlapLeft)
      const overlapScore = overlap / card.offsetWidth

      if (overlapScore > bestScore && overlapScore > 0.2) { // Reduced from 0.3 to 0.2 for snappier selection
        bestScore = overlapScore
        bestCard = card
      }
    })

    if (bestCard && bestCard.dataset.date !== this.currentDateValue) {
      this.currentDateValue = bestCard.dataset.date
      this.updateSelectedDate(bestCard)

      // THE FIX: Don't call loadEntryForDate during scroll - it triggers centering
      // Instead, load content without the centering side effect
      this.loadEntryForDateQuiet()
      this.updateFormDate(bestCard.dataset.date)
      this.updateControllerDates(bestCard.dataset.date)
    }
  }

  async loadEntryForDateQuiet() {
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
      this.showRecordingInterface()
    }
  }

  // ADD this new method to load content without centering:
  // async loadEntryForDateWithoutCentering() {
  //   try {
  //     const url = this.showUrlValue.replace('DATE_PLACEHOLDER', this.currentDateValue)
  //     const response = await fetch(url, {
  //       headers: {
  //         'Accept': 'application/json',
  //         'X-Requested-With': 'XMLHttpRequest'
  //       }
  //     })

  //     if (!response.ok) {
  //       throw new Error(`HTTP error! status: ${response.status}`)
  //     }

  //     const result = await response.json()

  //     if (result.entry) {
  //       this.showEntryDisplay(result.entry)
  //     } else {
  //       this.showRecordingInterface()
  //     }
  //   } catch (error) {
  //     console.error('Error loading entry:', error)
  //     this.showRecordingInterface()
  //   }
  // }

  setupScrollDetection() {
    if (this.hasCalendarContainerTarget) {
      let scrollTimeout
      this.calendarContainerTarget.addEventListener('scroll', () => {
        clearTimeout(scrollTimeout)
        scrollTimeout = setTimeout(() => {
          this.updateSelectionFromScroll()
        }, 10) // Very fast - 10ms for snappy selection
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

      // STRICTER: Only select if card center is very close to container center
      const centerDistance = Math.abs(cardCenter - containerCenter)
      const maxDistance = card.offsetWidth * 0.3 // Allow 30% of card width deviation

      if (centerDistance < maxDistance) {
        const score = 1 - (centerDistance / maxDistance) // Higher score for closer to center
        if (score > bestScore) {
          bestScore = score
          bestCard = card
        }
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

  // ADD these methods to your dashboard_controller.js:
  showTextLoading() {
    const loading = document.createElement('div')
    loading.id = 'text-loading'
    loading.innerHTML = `
      <div style="
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: #1a1a1a;
        color: white;
        padding: 20px 30px;
        border-radius: 12px;
        z-index: 1001;
        text-align: center;
      ">
        <div class="spinner" style="
          width: 40px;
          height: 40px;
          border: 4px solid #333;
          border-top: 4px solid #7c3aed;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto 20px;
        "></div>
        <div>Processing with AI...</div>
      </div>
    `
    document.body.appendChild(loading)
  }

  hideTextLoading() {
    const loading = document.getElementById('text-loading')
    if (loading) {
      loading.remove()
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

  updateEntryContent(entry) {
    const titleElement = this.entryDisplayTarget.querySelector('.entry-title')
    const nutshellElement = this.entryDisplayTarget.querySelector('.entry-nutshell')
    const summaryElement = this.entryDisplayTarget.querySelector('.entry-summary')
    const mediaElement = this.entryDisplayTarget.querySelector('.entry-media')
    const moodElement = this.entryDisplayTarget.querySelector('.entry-mood')

    if (titleElement) titleElement.textContent = entry.title || 'Untitled Entry'
    if (nutshellElement) nutshellElement.textContent = entry.ai_nutshell || ''
    if (summaryElement) summaryElement.textContent = entry.ai_summary || ''

    // CREATE AND SHOW ENTRY ACTIONS MENU WITH DELETE MODAL
    const actionsContainer = this.entryDisplayTarget.querySelector('#entry-actions-container')
    if (actionsContainer) {
      actionsContainer.innerHTML = `
        <div class="entry-actions-menu" data-controller="entry-actions" data-entry-actions-entry-id-value="${entry.id}">
          <!-- Three dots button (initial state) -->
          <button class="three-dots-btn" data-action="click->entry-actions#showActions" data-entry-actions-target="dotsBtn">
            <i class="fas fa-ellipsis-h"></i>
          </button>

          <!-- Action buttons (hidden initially) -->
          <div class="action-buttons" data-entry-actions-target="actionButtons" style="display: none;">
            <button class="edit-btn" data-action="click->entry-actions#editEntry" title="Edit">
              <i class="fas fa-edit"></i>
            </button>
            <button class="delete-btn" data-action="click->entry-actions#confirmDelete" title="Delete">
              <i class="fas fa-trash"></i>
            </button>
          </div>

          <!-- Delete confirmation modal - MUST BE INSIDE THE CONTROLLER SCOPE -->
          <div class="delete-modal" data-entry-actions-target="deleteModal" style="display: none;">
            <div class="modal-overlay" data-action="click->entry-actions#cancelDelete"></div>
            <div class="modal-content">
              <h3>Delete Entry?</h3>
              <p>This action cannot be undone.</p>
              <div class="modal-actions">
                <button class="cancel-btn" data-action="click->entry-actions#cancelDelete">Cancel</button>
                <button class="confirm-delete-btn" data-action="click->entry-actions#deleteEntry">Delete</button>
              </div>
            </div>
          </div>
        </div>
      `
      actionsContainer.style.display = 'block'
    }

    // Rest of your existing code...
    const bannerElement = this.entryDisplayTarget.querySelector('.entry-banner')
    if (bannerElement && entry.ai_banner_image_url) {
      bannerElement.innerHTML = `<img src="${entry.ai_banner_image_url}" alt="Mood banner" class="banner-image">`
      bannerElement.style.display = 'block'
    } else if (bannerElement) {
      bannerElement.innerHTML = '<button class="regenerate-banner-btn">Generate Banner</button>'
      bannerElement.style.display = 'block'
    }

    if (moodElement && entry.ai_mood_label) {
      moodElement.textContent = entry.ai_mood_label
      moodElement.className = `entry-mood mood-${entry.ai_mood_label.toLowerCase().replace(/\s+/g, '-')}`
    }

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

  // submitTextEntry method with this clean version:
  async submitTextEntry(event) {
    event.preventDefault()

    const formData = new FormData(event.target)

    // Check for update vs create
    const isUpdate = this.editingEntryIdValue &&
                    !isNaN(this.editingEntryIdValue) &&
                    this.editingEntryIdValue > 0

    const url = isUpdate ? `/journal_entries/${this.editingEntryIdValue}` : this.createUrlValue
    const method = isUpdate ? 'PATCH' : 'POST'

    try {
      // Show spinner for new entries only (not for edits)
      if (!isUpdate) {
        this.showTextLoading()
      }

      const response = await fetch(url, {
        method: method,
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) throw new Error('Failed to save entry')

      const result = await response.json()

      if (result.success) {
        // Reset editing state
        this.editingEntryIdValue = null

        // Reset form
        const form = event.target
        form.action = this.createUrlValue
        const methodField = form.querySelector('input[name="_method"]')
        if (methodField) methodField.remove()

        const submitBtn = form.querySelector('button[type="submit"]')
        if (submitBtn) {
          submitBtn.textContent = 'Create Entry'
        }

        event.target.reset()
        this.showEntryDisplay(result.entry)

        if (!isUpdate) {
          window.dispatchEvent(new CustomEvent('entryCreated', {
            detail: result.entry
          }))
        }
      } else {
        console.error('Entry save failed:', result.errors)
        alert('Failed to save entry')
      }
    } catch (error) {
      console.error('Error saving entry:', error)
      alert('Failed to save entry')
    } finally {
      if (!isUpdate) {
        this.hideTextLoading()
      }
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

  // Method for switching to edit mode from entry actions
  switchToEditMode(entryData) {
    // Store entry ID for updating
    this.editingEntryIdValue = entryData.id

    // Pre-fill form with entry data
    const titleInput = this.textEntryFormTarget.querySelector('input[name="journal_entry[title]"]')
    const contentInput = this.textEntryFormTarget.querySelector('textarea[name="journal_entry[content]"]')
    const form = this.textEntryFormTarget.querySelector('form')

    if (titleInput) titleInput.value = entryData.title || ''
    if (contentInput) contentInput.value = entryData.content || ''

    // Update form action for PATCH request
    if (form) {
      form.action = `/journal_entries/${entryData.id}`

      // Add hidden method field for PATCH
      let methodField = form.querySelector('input[name="_method"]')
      if (!methodField) {
        methodField = document.createElement('input')
        methodField.type = 'hidden'
        methodField.name = '_method'
        form.appendChild(methodField)
      }
      methodField.value = 'PATCH'
    }

    // Switch to text form state
    this.showTextForm()

    // Update submit button text
    const submitBtn = this.textEntryFormTarget.querySelector('button[type="submit"]')
    if (submitBtn) {
      submitBtn.textContent = 'Update Entry'
    }
  }

  // Method for switching back to recording after delete
  switchToRecordingInterface() {
    // Reset any editing state
    this.editingEntryIdValue = null

    // Reset form action and method
    const form = this.textEntryFormTarget.querySelector('form')
    if (form) {
      form.action = this.createUrlValue

      // Remove method field
      const methodField = form.querySelector('input[name="_method"]')
      if (methodField) methodField.remove()
    }

    // Reset submit button text
    const submitBtn = this.textEntryFormTarget.querySelector('button[type="submit"]')
    if (submitBtn) {
      submitBtn.textContent = 'Create Entry'
    }

    // Clear form fields
    const titleInput = this.textEntryFormTarget.querySelector('input[name="journal_entry[title]"]')
    const contentInput = this.textEntryFormTarget.querySelector('textarea[name="journal_entry[content]"]')
    if (titleInput) titleInput.value = ''
    if (contentInput) contentInput.value = ''

    // Switch to recording interface state
    this.showRecordingInterface()
  }

  // Helper method to get selected date (used by entry actions)
  getSelectedDate() {
    return this.currentDateValue
  }
}
