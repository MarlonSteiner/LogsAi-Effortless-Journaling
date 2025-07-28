// app/javascript/controllers/camera_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "takeInput", "uploadInput"]
  static values = { entryDate: String }

  connect() {
    // Close popup when clicking outside
    document.addEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnOutsideClick.bind(this))
  }

  showOptions(event) {
    event.stopPropagation()
    this.popupTarget.style.display = 'block'
  }

  hideOptions() {
    this.popupTarget.style.display = 'none'
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideOptions()
    }
  }

  takePhoto(event) {
    event.stopPropagation()
    this.hideOptions()
    this.takeInputTarget.click()
  }

  uploadFile(event) {
    event.stopPropagation()
    this.hideOptions()
    this.uploadInputTarget.click()
  }

  async handleFile(event) {
    const file = event.target.files[0]
    if (!file) return

    const formData = new FormData()
    formData.append('journal_entry[media_file]', file)
    formData.append('journal_entry[input_type]', file.type.startsWith('video/') ? 'video' : 'image')

    // Get selected date from dashboard controller
    formData.append('journal_entry[entry_date]', this.entryDateValue)

    try {
      // Show loading
      this.showLoading()

      const response = await fetch('/journal_entries', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (data.success) {
        // Dispatch entryCreated event like audio and text do
        window.dispatchEvent(new CustomEvent('entryCreated', {
          detail: data.entry
        }))
      } else {
        alert('Error: ' + data.errors.join(', '))
      }
    } catch (error) {
      alert('Upload failed')
      console.error(error)
    } finally {
      this.hideLoading()
      // Reset file inputs
      event.target.value = ''
    }
  }

  showLoading() {
    const loading = document.createElement('div')
    loading.id = 'camera-loading'
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

  hideLoading() {
    const loading = document.getElementById('camera-loading')
    if (loading) {
      loading.remove()
    }
  }
}
