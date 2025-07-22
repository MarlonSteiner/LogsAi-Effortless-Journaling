class JournalEntriesController < ApplicationController
  respond_to :html, :turbo_stream
  before_action :set_journal_entry, only: [:show, :edit, :update, :destroy]

  # Show all entries for user
  def index
    @journal_entries = current_user.journal_entries.recent
  end

  # Show single entry
  def show
  end

  # Form to create new entry
  def new
    @journal_entry = current_user.journal_entries.build
    @journal_entry.entry_date = Date.current
  end

  # Save new entry
  def create
    @journal_entry = current_user.journal_entries.build(journal_entry_params)

    if @journal_entry.save
      # Run AI mood analysis automatically
      begin
        ai_result = MoodAnalysisService.new(@journal_entry).analyze
        if ai_result
          # Replace content with AI summary and add AI fields
          @journal_entry.content = ai_result[:summary]
          @journal_entry.update!(
            ai_mood_label: ai_result[:mood_label],
            ai_color_theme: ai_result[:color_theme],
            ai_background_style: ai_result[:background_style],
            ai_summary: ai_result[:summary]
          )
        end
        redirect_to @journal_entry, notice: 'Entry created with AI mood analysis!'
      rescue => e
        Rails.logger.error "AI Analysis failed: #{e.message}"
        redirect_to @journal_entry, notice: 'Entry created (AI analysis unavailable)!'
      end
    else
      @moods = Mood.alphabetical if defined?(Mood)
      render :new, status: :unprocessable_entity
    end
  end

  # Form to edit entry
  def edit
  end

  # Save edited entry
  def update
    if @journal_entry.update(journal_entry_params)
      redirect_to @journal_entry, notice: 'Entry updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Delete entry
  def destroy
    if params[:redo] == "true"
      @journal_entry.destroy
      redirect_to new_journal_entry_path, notice: 'Entry deleted. Creating a new entry...'
    else
      @journal_entry.destroy
      redirect_to journal_entries_path, notice: 'Entry deleted successfully!'
    end
  end

  # Redo entry - delete current and redirect to blank new form
  def redo
    @journal_entry = current_user.journal_entries.find(params[:id])
    @journal_entry.destroy

    redirect_to new_journal_entry_path, notice: 'Entry deleted. You can now create a fresh entry.'
  end

  private

  def set_journal_entry
    @journal_entry = current_user.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:title, :content, :input_type, :entry_date)
  end
end
