class EntryAiProcessor
  def self.process(entry)
    new(entry).process
  end

  def initialize(entry)
    @entry = entry
  end

  def process
    case @entry.input_type
    when 'audio'
      process_audio_entry
    when 'image', 'video'
      process_media_entry
    when 'text'
      process_text_entry
    end
  end

  private

  def process_audio_entry
    Rails.logger.info "=== AUDIO PROCESSING STARTED ==="
    return unless @entry.media_file.attached?

    begin
      transcription = get_audio_transcription(@entry.media_file)

      if transcription.present?
        @entry.update_column(:content, transcription)

        analysis = MoodAnalysisService.analyze(transcription, 'audio')

        @entry.update_columns(
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
      @entry.update_column(:title, "Voice Recording - #{@entry.entry_date.strftime('%B %d, %Y')}")
    end
  end

  def process_media_entry
    return unless @entry.media_file.attached?

    begin
      analysis = MoodAnalysisService.analyze(@entry.media_file, @entry.input_type)

      @entry.update_columns(
        title: analysis[:title],
        ai_mood_label: analysis[:mood],
        ai_color_theme: analysis[:color_theme],
        ai_background_style: analysis[:background_style],
        ai_summary: analysis[:summary],
        ai_nutshell: analysis[:nutshell]
      )
    rescue => e
      Rails.logger.error "Media processing failed: #{e.message}"
      @entry.update_column(:title, "#{@entry.input_type.capitalize} Entry - #{@entry.entry_date.strftime('%B %d, %Y')}")
    end
  end

  def process_text_entry
    return unless @entry.content.present?

    begin
      analysis = MoodAnalysisService.analyze(@entry.content, 'text')

      @entry.update_columns(
        title: analysis[:title],
        ai_mood_label: analysis[:mood],
        ai_color_theme: analysis[:color_theme],
        ai_background_style: analysis[:background_style],
        ai_summary: analysis[:summary],
        ai_nutshell: analysis[:nutshell]
      )
    rescue => e
      Rails.logger.error "Text processing failed: #{e.message}"
      @entry.update_column(:title, "Journal Entry - #{@entry.entry_date.strftime('%B %d, %Y')}")
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
