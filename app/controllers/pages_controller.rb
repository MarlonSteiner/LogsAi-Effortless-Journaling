class PagesController < ApplicationController
  before_action :authenticate_user!, only: [ :home ]

  def dashboard
    @recent_entries = current_user.journal_entries.recent.limit(5)
    @total_entries = current_user.journal_entries.count
    # Add emotion analytics here later
  end

  def home
    today = Date.current

    # 30 days back + 3 day buffer on each side = 36 total days
    start_date = today - 30.days - 3.days  # 33 days ago
    end_date = today + 3.days               # 3 days in future

    @current_date = today
    @date_range = (start_date..end_date).to_a
  end
end
