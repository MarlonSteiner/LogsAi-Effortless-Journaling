class PagesController < ApplicationController
  before_action :authenticate_user!, only: [ :home ]

  def dashboard
    @recent_entries = current_user.journal_entries.recent.limit(5)
    @total_entries = current_user.journal_entries.count
    # Add emotion analytics here later
  end

  def home
    @selected_date = params[:date] || Date.current.to_s

    # Calendar range: July 1st, 2025 to 7 days from today
    start_date = Date.new(2025, 7, 1)
    end_date = Date.current + 1.week
    @current_date = Date.current
    @date_range = (start_date..end_date).to_a
  end
end
