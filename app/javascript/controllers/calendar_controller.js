import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "monthButton", "yearButton",
    "monthPicker", "yearPicker",
    "currentPeriod", "entryDisplay"
  ]

  static values = {
    selectedMonth: Number,
    selectedYear: Number
  }

  connect() {
    console.log("Calendar controller connected")
    this.setupEntryListener()
  }

  setupEntryListener() {
    // Listen for new entries created from other pages
    window.addEventListener('entryCreated', (event) => {
      console.log("New entry received:", event.detail)
      this.handleNewEntry(event.detail)
    })
  }

  handleNewEntry(entryData) {
    // Only update if the entry is for the currently displayed month/year
    const entryDate = new Date(entryData.date)
    if (entryDate.getMonth() + 1 === this.selectedMonthValue &&
        entryDate.getFullYear() === this.selectedYearValue) {

      // Update calendar day color
      this.updateCalendarDay(entryData)

      // If this date is currently selected, update the entry display
      if (this.isDateSelected(entryData.date)) {
        this.updateEntryDisplay(entryData)
      }
    }
  }

  updateCalendarDay(entryData) {
    const dateElement = this.element.querySelector(`[data-date="${entryData.date}"]`)
    if (dateElement) {
      // Remove old emotion classes
      dateElement.classList.remove('good', 'okay', 'bad', 'neutral')
      // Add new emotion class
      dateElement.classList.add(entryData.emotion_category)
      console.log(`Updated day ${entryData.date} to ${entryData.emotion_category}`)
    }
  }

  updateEntryDisplay(entryData) {
    const entryDisplay = this.entryDisplayTarget

    let nutshellSection = ''
    if (entryData.ai_nutshell) {
      nutshellSection = `
        <div class="nutshell-section">
          <h3 class="section-label">IN A NUTSHELL</h3>
          <p class="entry-nutshell">${entryData.ai_nutshell}</p>
        </div>
      `
    }

    let summarySection = ''
    if (entryData.ai_summary) {
      summarySection = `
        <div class="summary-section">
          <h3 class="section-label">FULL SUMMARY</h3>
          <p class="entry-summary">${entryData.ai_summary}</p>
        </div>
      `
    }

    entryDisplay.innerHTML = `
      <div class="selected-entry">
        <div class="entry-header">
          <div class="entry-date">${entryData.formatted_date}</div>
        </div>
        <div class="entry-content">
          <h1 class="entry-title">${entryData.title}</h1>
          ${nutshellSection}
          ${summarySection}
        </div>
      </div>
    `
    entryDisplay.style.display = 'block'
    console.log("Updated entry display")
  }

  isDateSelected(date) {
    const selectedElement = this.element.querySelector('.calendar-day.selected')
    return selectedElement && selectedElement.dataset.date === date
  }

  toggleMonthPicker() {
    const isVisible = this.monthPickerTarget.style.display !== 'none'

    // Hide both pickers first
    this.monthPickerTarget.style.display = 'none'
    this.yearPickerTarget.style.display = 'none'

    // Remove active states
    this.monthButtonTarget.classList.remove('active')
    this.yearButtonTarget.classList.remove('active')

    if (!isVisible) {
      this.monthPickerTarget.style.display = 'block'
      this.monthButtonTarget.classList.add('active')
    }
  }

  toggleYearPicker() {
    const isVisible = this.yearPickerTarget.style.display !== 'none'

    // Hide both pickers first
    this.monthPickerTarget.style.display = 'none'
    this.yearPickerTarget.style.display = 'none'

    // Remove active states
    this.monthButtonTarget.classList.remove('active')
    this.yearButtonTarget.classList.remove('active')

    if (!isVisible) {
      this.yearPickerTarget.style.display = 'block'
      this.yearButtonTarget.classList.add('active')
    }
  }

  selectMonth(event) {
    const month = parseInt(event.target.dataset.month)
    this.selectedMonthValue = month
    this.updateCalendar()
    this.hidePickers()
  }

  selectYear(event) {
    const year = parseInt(event.target.dataset.year)
    this.selectedYearValue = year
    this.updateCalendar()
    this.hidePickers()
  }

  selectDate(event) {
    const selectedDate = event.target.dataset.date

    // Remove previous selection
    this.element.querySelectorAll('.calendar-day.selected').forEach(day => {
      day.classList.remove('selected')
    })

    // Add selection to clicked date
    event.target.classList.add('selected')

    // Load entry for selected date
    this.loadEntryForDate(selectedDate)
  }

  hidePickers() {
    this.monthPickerTarget.style.display = 'none'
    this.yearPickerTarget.style.display = 'none'
    this.monthButtonTarget.classList.remove('active')
    this.yearButtonTarget.classList.remove('active')
  }

  updateCalendar() {
    // Navigate to the new month/year using your existing parameter names
    const url = new URL(window.location)
    url.searchParams.set('month', this.selectedMonthValue)
    url.searchParams.set('year', this.selectedYearValue)

    // Use Turbo to navigate (maintains the SPA feel)
    window.Turbo.visit(url.toString())
  }

  loadEntryForDate(date) {
    // Navigate to the same page with selected_date parameter
    const url = new URL(window.location)
    url.searchParams.set('selected_date', date)

    // Use Turbo to navigate
    window.Turbo.visit(url.toString())
  }
}
