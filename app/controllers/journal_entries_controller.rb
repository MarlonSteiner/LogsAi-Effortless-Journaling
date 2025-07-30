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
              ai_banner_image_url: @entry.ai_banner_image_url,
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
    @journal_entry.entry_date = params[:journal_entry][:entry_date] || Date.current

    respond_to do |format|
      if @journal_entry.save
        # Process AI synchronously - WAIT for completion before responding
        if should_process_with_ai?
          ProcessEntryAiJob.perform_now(@journal_entry.id)
          @journal_entry.reload  # Get the updated AI fields from database
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
              ai_banner_image_url: @journal_entry.ai_banner_image_url
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
    @entry = current_user.journal_entries.find(params[:id])

    respond_to do |format|
      format.json {
        render json: {
          success: true,
          entry: {
            id: @entry.id,
            title: @entry.title,                    # AI-generated title
            content: @entry.ai_summary,             # CHANGED: Send AI summary instead of original content
            entry_date: @entry.entry_date.strftime('%Y-%m-%d')
          }
        }
      }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: 'Entry not found' } }
    end
  end

  def update
    @entry = current_user.journal_entries.find(params[:id])

    # Update the display fields with user's edits
    update_params = {}
    update_params[:title] = params[:journal_entry][:title] if params[:journal_entry][:title].present?
    update_params[:ai_summary] = params[:journal_entry][:content] if params[:journal_entry][:content].present?

    if @entry.update(update_params)
      respond_to do |format|
        format.json {
          render json: {
            success: true,
            entry: {
              id: @entry.id,
              title: @entry.title,                    # Updated title
              content: @entry.ai_summary,             # Updated summary (what user edited)
              ai_mood_label: @entry.ai_mood_label,
              ai_summary: @entry.ai_summary,          # This now contains user's edited text
              ai_nutshell: @entry.ai_nutshell,
              ai_banner_image_url: @entry.ai_banner_image_url,
              input_type: @entry.input_type,
              entry_date: @entry.entry_date.strftime('%Y-%m-%d'),
              formatted_date: @entry.entry_date.strftime("%B %d, %Y"),
              media_url: @entry.media_file.attached? ? url_for(@entry.media_file) : nil
            }
          }
        }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @entry.errors } }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: 'Entry not found' } }
    end
  end

  def status
    @journal_entry = JournalEntry.find(params[:id])

    # Skip if AI data not yet ready
    unless @journal_entry.ai_summary.present? && @journal_entry.ai_nutshell.present?
      head :no_content and return
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @entry = current_user.journal_entries.find(params[:id])
    @entry.destroy

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: 'Entry not found' } }
    end
end

  private

  def entry_params
    params.require(:journal_entry).permit(:title, :content, :entry_date, :input_type)
  end

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
end
