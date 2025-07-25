// app/javascript/controllers/audio_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordButton", "recordingStatus"]
  static values = {
    entryDate: String,
    createUrl: String
  }

  connect() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.isRecording = false
    this.stream = null
    this.audioBlob = null // Add this property

    // Check if browser supports audio recording
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      console.error("Audio recording not supported in this browser")
      this.showError("Audio recording is not supported in your browser")
      return
    }
  }

  disconnect() {
    this.cleanup()
  }

  async toggleRecording() {
    if (this.isRecording) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    try {
      // Request microphone access
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      })

      // Create MediaRecorder instance
      this.mediaRecorder = new MediaRecorder(this.stream, {
        mimeType: this.getSupportedMimeType()
      })

      // Reset audio chunks
      this.audioChunks = []

      // Set up event handlers
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }

      this.mediaRecorder.onstop = () => {
        this.processRecording()
      }

      this.mediaRecorder.onerror = (event) => {
        console.error("MediaRecorder error:", event.error)
        this.showError("Recording error occurred")
        this.cleanup()
      }

      // Start recording
      this.mediaRecorder.start(1000) // Collect data every second
      this.isRecording = true
      this.updateUI()

    } catch (error) {
      console.error("Error starting audio recording:", error)
      if (error.name === 'NotAllowedError') {
        this.showError("Microphone access denied. Please allow microphone permissions and try again.")
      } else if (error.name === 'NotFoundError') {
        this.showError("No microphone found. Please check your device settings.")
      } else {
        this.showError("Could not start recording. Please try again.")
      }
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.updateUI()

      // Stop all tracks to release microphone
      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop())
      }
    }
  }

  processRecording() {
    if (this.audioChunks.length === 0) {
      this.showError("No audio recorded. Please try again.")
      this.cleanup()
      return
    }

    // Create audio blob and store it
    this.audioBlob = new Blob(this.audioChunks, {
      type: this.getSupportedMimeType()
    })

    // Check if recording is too short (less than 1 second)
    if (this.audioBlob.size < 1000) {
      this.showError("Recording too short. Please record for at least 1 second.")
      this.cleanup()
      return
    }

    // Show processing state
    this.showProcessing()

    // Upload and process the audio
    this.uploadAudio()
  }

  async uploadAudio() {
    if (!this.audioBlob) {
      console.error('No audio to upload')
      return
    }

    try {
      this.updateRecordingStatus('Processing...')

      const formData = new FormData()
      formData.append('journal_entry[media_file]', this.audioBlob, 'recording.webm')
      formData.append('journal_entry[input_type]', 'audio') // Fixed: should be 'audio' not 'speech'
      formData.append('journal_entry[entry_date]', this.entryDateValue)

      const response = await fetch(this.createUrlValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'  // Request JSON response
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        // Trigger custom event for calendar to listen
        window.dispatchEvent(new CustomEvent('entryCreated', {
          detail: data.entry
        }))

        // Trigger existing dashboard event (for main page)
        this.dispatch('entryCreated', { detail: data.entry })

        this.updateRecordingStatus('Entry created successfully!')

        // Reset audio recording state
        this.resetRecording()

      } else {
        console.error('Upload failed:', data.errors)
        this.updateRecordingStatus('Upload failed. Please try again.')
      }

    } catch (error) {
      console.error('Error uploading audio:', error)
      this.updateRecordingStatus('Upload failed. Please try again.')
    }
  }

  updateRecordingStatus(message) {
    if (this.hasRecordingStatusTarget) {
      this.recordingStatusTarget.textContent = message
    }
  }

  resetRecording() {
    this.audioBlob = null
    this.audioChunks = []
    this.updateUI()

    // Clear status message after a delay
    setTimeout(() => {
      this.updateRecordingStatus('')
    }, 2000)
  }

  getSupportedMimeType() {
    const types = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/mp4',
      'audio/mpeg'
    ]

    for (const type of types) {
      if (MediaRecorder.isTypeSupported(type)) {
        return type
      }
    }

    return 'audio/webm' // Fallback
  }

  updateUI() {
    const button = this.recordButtonTarget
    const status = this.hasRecordingStatusTarget ? this.recordingStatusTarget : null

    if (this.isRecording) {
      button.classList.add('recording')
      button.disabled = false
      if (status) {
        status.textContent = 'Recording... Tap to stop'
        status.classList.add('recording')
      }
    } else {
      button.classList.remove('recording', 'processing')
      button.disabled = false
      if (status) {
        status.textContent = ''
        status.classList.remove('recording', 'processing')
      }
    }
  }

  showProcessing() {
    const button = this.recordButtonTarget
    const status = this.hasRecordingStatusTarget ? this.recordingStatusTarget : null

    button.classList.add('processing')
    button.disabled = true

    if (status) {
      status.textContent = 'Processing your recording...'
      status.classList.add('processing')
    }
  }

  showError(message) {
    // You can customize this to match your app's error handling
    console.error(message)

    // Show error in status if available
    if (this.hasRecordingStatusTarget) {
      this.recordingStatusTarget.textContent = message
      this.recordingStatusTarget.classList.add('error')

      // Clear error after 3 seconds
      setTimeout(() => {
        if (this.hasRecordingStatusTarget) {
          this.recordingStatusTarget.textContent = ''
          this.recordingStatusTarget.classList.remove('error')
        }
      }, 3000)
    } else {
      // Fallback to alert if no status target
      alert(message)
    }
  }

  cleanup() {
    this.isRecording = false
    this.audioChunks = []
    this.audioBlob = null

    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }

    if (this.mediaRecorder) {
      this.mediaRecorder = null
    }

    this.updateUI()
  }
}
