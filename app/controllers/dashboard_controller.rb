class DashboardController < ApplicationController
  def index
    start_date = Date.new(2025, 7, 1)
    end_date = Date.current + 1.week
    @current_date = Date.current
    @date_range = (start_date..end_date).to_a
  end

  def calendar
    # For the second page (full calendar view)
    @current_month = params[:month]&.to_i || Date.current.month
    @current_year = params[:year]&.to_i || Date.current.year
    @calendar_date = Date.new(@current_year, @current_month, 1)
    @journal_entries = current_user.journal_entries.for_month(@current_month, @current_year)
  end
end
