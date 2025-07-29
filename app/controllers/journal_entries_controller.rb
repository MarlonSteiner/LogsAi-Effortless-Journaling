class JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal_entry, only: [:show, :edit, :update, :destroy, :regenerate_banner]

  def index
    @journal_entries = current_user.journal_entries.order(entry_date: :desc)
  end

  def show
    respond_to do |format|
      format.html # For direct URL access like /journal_entries/123
      format.json do
        render json: {
          entry: {
            id: @journal_entry.id,
            title: @journal_entry.title,
            content: @journal_entry.content,
            ai_mood_label: @journal_entry.ai_mood_label,
            ai_summary: @journal_entry.ai_summary,
            ai_nutshell: @journal_entry.ai_nutshell,
            ai_banner_image_url: @journal_entry.ai_banner_image_url,
            input_type: @journal_entry.input_type,
            entry_date: @journal_entry.entry_date,
            formatted_date: @journal_entry.entry_date.strftime("%B %d, %Y"),
            media_url: @journal_entry.media_file.attached? ? url_for(@journal_entry.media_file) : nil
          }
        }
      end
    end
  end

  def show_for_date
    @entry = current_user.journal_entries.find_by(entry_date: params[:date])

    respond_to do |format|
      format.json do
        if @entry
          render json: {
            entry: {
              id: @entry.id,
              title: @entry.title,
              content: @entry.content,
              ai_mood_label: @entry.ai_mood_label,
              ai_summary: @entry.ai_summary,
              ai_nutshell: @entry.ai_nutshell,
              ai_banner_image_url: @entry.ai_banner_image_url,  # This line should be here
              input_type: @entry.input_type,
              entry_date: @entry.entry_date,
              media_url: @entry.media_file.attached? ? url_for(@entry.media_file) : nil
            }
          }
        else
          render json: { entry: nil }
        end
      end
    end
  end

  def new
    @journal_entry = current_user.journal_entries.build
    @selected_date = params[:date] || Date.current.to_s
  end

  def create
    @journal_entry = current_user.journal_entries.build(journal_entry_params)

    # Set entry date
    @journal_entry.entry_date = params[:journal_entry][:entry_date] || Date.current

    respond_to do |format|
      if @journal_entry.save
        # Process with AI if media file is attached or content is present
        if should_process_with_ai?
          begin
            process_with_ai(@journal_entry)

            # Generate banner image with logging
            Rails.logger.info "=== Starting banner generation for entry #{@journal_entry.id}"
            banner_url = BannerImageService.generate_for_entry(@journal_entry)
            Rails.logger.info "=== Banner result: #{banner_url}"
            @journal_entry.update(ai_banner_image_url: banner_url) if banner_url

          rescue => e
            Rails.logger.error "AI processing failed: #{e.message}"
            # Continue without AI analysis if it fails
          end
        end

        format.html { redirect_to root_path, notice: 'Journal entry was successfully created.' }
        format.json do
          render json: {
            success: true,
            entry: {
              id: @journal_entry.id,
              date: @journal_entry.entry_date.to_s,
              emotion_category: emotion_color_category(@journal_entry.ai_mood_label),
              title: @journal_entry.title,
              content: @journal_entry.content,
              ai_mood_label: @journal_entry.ai_mood_label,
              ai_summary: @journal_entry.ai_summary,
              ai_nutshell: @journal_entry.ai_nutshell,
              input_type: @journal_entry.input_type,
              entry_date: @journal_entry.entry_date,
              formatted_date: @journal_entry.entry_date.strftime("%B %d, %Y"),
              media_url: @journal_entry.media_file.attached? ? url_for(@journal_entry.media_file) : nil,
              ai_banner_image_url: @journal_entry.ai_banner_image_url  # Add this line too
            }
          }
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @journal_entry.errors.full_messages } }
      end
    end
  end

  def regenerate_banner
    banner_url = BannerImageService.generate_for_entry(@journal_entry)
    @journal_entry.update(ai_banner_image_url: banner_url) if banner_url

    respond_to do |format|
      format.json { render json: { banner_url: @journal_entry.ai_banner_image_url } }
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @journal_entry.update(journal_entry_params)
        format.html { redirect_to @journal_entry, notice: 'Journal entry was successfully updated.' }
        format.json { render json: @journal_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: @journal_entry.errors.full_messages.join(', ') } }
      end
    end
  end

  def destroy
    @journal_entry.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Journal entry was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def set_journal_entry
    @journal_entry = current_user.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:title, :content, :input_type, :entry_date, :media_file)
  end

  def should_process_with_ai?
    @journal_entry.media_file.attached? || @journal_entry.content.present?
  end

  # Helper method to determine emotion color category for calendar
  def emotion_color_category(ai_mood_label)
    return 'neutral' unless ai_mood_label

    good_emotions = %w[joyful excited energetic grateful loved content peaceful calm optimistic hopeful confident inspired proud]
    okay_emotions = %w[contemplative focused curious nostalgic determined tired]
    bad_emotions = %w[anxious worried stressed frustrated angry overwhelmed confused restless sad lonely disappointed]

    mood = ai_mood_label.downcase

    if good_emotions.include?(mood)
      'good'
    elsif okay_emotions.include?(mood)
      'okay'
    elsif bad_emotions.include?(mood)
      'bad'
    else
      'neutral'
    end
  end

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
