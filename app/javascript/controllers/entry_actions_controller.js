import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dotsBtn", "actionButtons", "deleteModal"]
  static values = { entryId: Number }

  connect() {
    // Bind click outside handler
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  showActions(event) {
    event.stopPropagation()

    // Hide three dots, show action buttons
    this.dotsBtnTarget.style.display = "none"
    this.actionButtonsTarget.style.display = "flex"

    // Add click outside listener
    setTimeout(() => {
      document.addEventListener("click", this.boundClickOutside)
    }, 100)
  }

  hideActions() {
    // Show three dots, hide action buttons
    this.dotsBtnTarget.style.display = "block"
    this.actionButtonsTarget.style.display = "none"

    // Remove click outside listener
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideActions()
    }
  }

  editEntry(event) {
    event.stopPropagation()

    // Send request to get entry data and switch to edit mode
    fetch(`/journal_entries/${this.entryIdValue}/edit`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Trigger dashboard to switch to edit mode
        const dashboardController = this.application.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller*="dashboard"]'),
          "dashboard"
        )

        if (dashboardController) {
          dashboardController.switchToEditMode(data.entry)
        }
      }
    })
    .catch(error => {
      console.error('Error loading entry for edit:', error)
    })
  }

  confirmDelete(event) {
    event.stopPropagation()
    this.deleteModalTarget.style.display = "block"
  }

  cancelDelete(event) {
    event.stopPropagation()
    this.deleteModalTarget.style.display = "none"
  }

  deleteEntry(event) {
    event.stopPropagation()

    fetch(`/journal_entries/${this.entryIdValue}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Hide modal
        this.deleteModalTarget.style.display = "none"

        // Trigger dashboard to switch to recording interface
        const dashboardController = this.application.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller*="dashboard"]'),
          "dashboard"
        )

        if (dashboardController) {
          dashboardController.switchToRecordingInterface()
        }
      }
    })
    .catch(error => {
      console.error('Error deleting entry:', error)
    })
  }
}
