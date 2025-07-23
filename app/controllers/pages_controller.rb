class PagesController < ApplicationController
  before_action :authenticate_user!, only: [ :home ]

  def dashboard
    @recent_entries = current_user.journal_entries.recent.limit(5)
    @total_entries = current_user.journal_entries.count
    # Add emotion analytics here later
  end
end
