class JournalEntriesController < ApplicationController
  respond_to :html, :json
  before_action :set_journal_entry, only: [:show, :edit, :update, :destroy]

  def index
    @journal_entries = current_user.journal_entries.recent
  end

  def show
  end

  def new
    @journal_entry = current_user.journal_entries.build
    @journal_entry.entry_date = Date.current
  end

  def create
    @journal_entry = current_user.journal_entries.build(journal_entry_params)

    if @journal_entry.save
      begin
        ai_result = MoodAnalysisService.new(@journal_entry).analyze
        if ai_result
          if @journal_entry.input_type == 'text' || @journal_entry.content.blank?
            @journal_entry.content = ai_result[:summary]
          end

          @journal_entry.update!(
            ai_mood_label: ai_result[:mood_label],
            ai_nutshell: ai_result[:nutshell],
            ai_color_theme: ai_result[:color_theme],
            ai_background_style: ai_result[:background_style],
            ai_summary: ai_result[:summary]
          )
        end

        respond_to do |format|
          format.html { redirect_to @journal_entry, notice: 'Entry created!' }
          format.json {
            render json: {
              success: true,
              entry: entry_json(@journal_entry),
              message: 'Entry created with AI analysis!'
            }
          }
        end
      rescue => e
        Rails.logger.error "AI Analysis failed: #{e.message}"
        respond_to do |format|
          format.html { redirect_to @journal_entry, notice: 'Entry created!' }
          format.json {
            render json: {
              success: true,
              entry: entry_json(@journal_entry),
              message: 'Entry created!'
            }
          }
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            success: false,
            errors: @journal_entry.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  def edit
  end

  def update
    if @journal_entry.update(journal_entry_params)
      redirect_to @journal_entry, notice: 'Entry updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:redo] == "true"
      @journal_entry.destroy
      redirect_to new_journal_entry_path, notice: 'Entry deleted. Creating a new entry...'
    else
      @journal_entry.destroy
      redirect_to journal_entries_path, notice: 'Entry deleted successfully!'
    end
  end

  def redo
    @journal_entry = current_user.journal_entries.find(params[:id])
    @journal_entry.destroy
    redirect_to new_journal_entry_path, notice: 'Entry deleted. You can now create a fresh entry.'
  end

  def show_for_date
    date = Date.parse(params[:date])
    @entry = current_user.journal_entries.find_by(entry_date: date)

    if @entry
      render json: {
        success: true,
        entry: entry_json(@entry)
      }
    else
      render json: {
        success: false,
        message: 'No entry found for this date'
      }
    end
  end

  private

  def set_journal_entry
    @journal_entry = current_user.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:title, :content, :input_type, :entry_date, :media_file)
  end

  def entry_json(entry)
    {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      ai_nutshell: entry.ai_nutshell,
      ai_summary: entry.ai_summary,
      mood_label: entry.ai_mood_label,
      color_theme: entry.ai_color_theme,
      background_style: entry.ai_background_style,
      entry_date: entry.entry_date,
      input_type: entry.input_type,
      has_media: entry.has_media?,
      media_type: entry.media_type,
      media_url: entry.has_media? ? url_for(entry.media_file) : nil
    }
  end
end
