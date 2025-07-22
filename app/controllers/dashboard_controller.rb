class DashboardController < ApplicationController
  # before_action :set_date, only: %i[show edit update destroy]
  def index
    start_date = Date.new(2025, 7, 1)
    end_date = Date.current + 1.week
    @current_date = Date.current
    @date_range = (start_date..end_date).to_a
  end

  def show
  end

  # private

  # def set_date
    # @date = .find(params[:id])
  # end
end
