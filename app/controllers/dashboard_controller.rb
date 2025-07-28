class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    today = Date.current

    # 30 days back + 3 day buffer on each side = 36 total days
    start_date = today - 30.days - 3.days  # 33 days ago
    end_date = today + 3.days               # 3 days in future

    @current_date = today
    @selected_date = today  # Add this line for compatibility with your HTML
    @date_range = (start_date..end_date).to_a
  end

  def calendar
    # Use your existing parameter logic
    @selected_month = params[:month]&.to_i || Date.current.month
    @selected_year = params[:year]&.to_i || Date.current.year
    @calendar_date = Date.new(@selected_year, @selected_month, 1)

    # Get entries for the current month/year
    start_date = @calendar_date.beginning_of_month
    end_date = @calendar_date.end_of_month

    @entries = current_user.journal_entries
                          .where(entry_date: start_date..end_date)
                          .includes(:media_file_attachment)

    # Group entries by date for easy lookup in views
    @entries_by_date = @entries.group_by(&:entry_date)

    # Get available years (years where user has entries)
    @available_years = current_user.journal_entries
                                  .pluck(:entry_date)
                                  .compact
                                  .map(&:year)
                                  .uniq
                                  .sort

    # Default to current year if no entries exist
    @available_years << Date.current.year if @available_years.empty?
    @available_years.uniq!

    # Handle selected date for entry display
    @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : nil
    @selected_entry = @selected_date ? @entries_by_date[@selected_date]&.first : nil
  end

  # Handle Ajax requests to display elements if there is a journal entry or not
  def load_date_content
    date = Date.parse(params[:date])
    entry = current_user.journal_entries.find_by(entry_date: date)

    respond_to do |format|
      format.json do
        if entry
          render json: {
            has_entry: true,
            entry: {
              id: entry.id,
              title: entry.title,
              content: entry.content,
              ai_nutshell: entry.ai_nutshell,
              ai_summary: entry.ai_summary,
              entry_date: date.strftime("%B %d, %Y")
            }
          }
        else
          render json: {
            has_entry: false,
            selected_date: date.strftime("%B %d, %Y")
          }
        end
      end
    end
  rescue Date::Error
    render json: { error: "Invalid date" }, status: 400
  end

  private

  # Helper method to determine emotion color category
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

  # Make this method available in views
  helper_method :emotion_color_category
end
