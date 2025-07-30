class ProcessEntryAiJob < ApplicationJob
  queue_as :default

  def perform(entry_id)
    entry = JournalEntry.find(entry_id)

    # Process AI analysis
    process_with_ai(entry)

    # Generate banner image
    banner_url = BannerImageService.generate_for_entry(entry)
    entry.update(ai_banner_image_url: banner_url) if banner_url
  end

    # Broadcast Turbo Stream update
  #   ActionCable.server.broadcast(
  #     "entry_#{entry.id}",
  #       turbo_stream: ApplicationController.render(
  #         partial: "journal_entries/entry_update",
  #         locals: { entry: entry },
  #         formats: [:turbo_stream]
  #       )
  #   )
  # end

  private

  def process_with_ai(entry)
    case entry.input_type
    when 'audio'
      process_audio_entry(entry)
    when 'image', 'video'
      process_media_entry(entry)
    when 'text'
      process_text_entry(entry)
    end
  end

  def process_audio_entry(entry)
    Rails.logger.info "=== AUDIO PROCESSING STARTED ==="
    return unless entry.media_file.attached?

    # For audio entries, we'll use OpenAI's Whisper API to transcribe
    # and then analyze the transcription
    begin
      # Get audio transcription
      transcription = get_audio_transcription(entry.media_file)

      if transcription.present?
        # Set the transcription as content
        entry.update_column(:content, transcription)

        # Analyze the transcribed content
        analysis = MoodAnalysisService.analyze(transcription, 'audio')

        # Update entry with AI analysis
        entry.update_columns(
          title: analysis[:title],
          ai_mood_label: analysis[:mood],
          ai_color_theme: analysis[:color_theme],
          ai_background_style: analysis[:background_style],
          ai_summary: analysis[:summary],
          ai_nutshell: analysis[:nutshell]
        )
      end
    rescue => e
      Rails.logger.error "Audio processing failed: #{e.message}"
      # Set a default title if AI processing fails
      entry.update_column(:title, "Voice Recording - #{entry.entry_date.strftime('%B %d, %Y')}")
    end
  end

  def process_media_entry(entry)
    return unless entry.media_file.attached?

    begin
      # For image/video, analyze the media file directly
      analysis = MoodAnalysisService.analyze(entry.media_file, entry.input_type)

      entry.update_columns(
        title: analysis[:title],
        ai_mood_label: analysis[:mood],
        ai_color_theme: analysis[:color_theme],
        ai_background_style: analysis[:background_style],
        ai_summary: analysis[:summary],
        ai_nutshell: analysis[:nutshell]
      )
    rescue => e
      Rails.logger.error "Media processing failed: #{e.message}"
      # Set a default title if AI processing fails
      entry.update_column(:title, "#{entry.input_type.capitalize} Entry - #{entry.entry_date.strftime('%B %d, %Y')}")
    end
  end

  def process_text_entry(entry)
    return unless entry.content.present?

    begin
      analysis = MoodAnalysisService.analyze(entry.content, 'text')

      entry.update_columns(
        title: analysis[:title],
        ai_mood_label: analysis[:mood],
        ai_color_theme: analysis[:color_theme],
        ai_background_style: analysis[:background_style],
        ai_summary: analysis[:summary],
        ai_nutshell: analysis[:nutshell]
      )
    rescue => e
      Rails.logger.error "Text processing failed: #{e.message}"
      # Set a default title if AI processing fails
      entry.update_column(:title, "Journal Entry - #{entry.entry_date.strftime('%B %d, %Y')}")
    end
  end

  def get_audio_transcription(audio_file)
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

    file_extension = audio_file.content_type.include?('webm') ? '.webm' : '.mp4'

    temp_file = Tempfile.new(['audio', file_extension])
    temp_file.binmode
    temp_file.write(audio_file.download)
    temp_file.rewind

    begin
      response = client.audio.transcribe(
        parameters: {
          model: "whisper-1",
          file: File.open(temp_file.path, "rb")
        }
      )

      response["text"]
    ensure
      temp_file.close
      temp_file.unlink
    end
  end
end
