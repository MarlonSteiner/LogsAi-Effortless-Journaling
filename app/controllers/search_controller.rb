# app/controllers/search_controller.rb
class SearchController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    query = params[:q]

    if query.present? && query.length >= 2
      # Assuming you have a JournalEntry model with a title field
      @results = current_user.journal_entries
                            .where("title ILIKE ?", "%#{query}%")
                            .limit(10)
                            .select(:id, :title, :created_at)
    else
      @results = []
    end

    render json: @results.map { |entry|
      {
        id: entry.id,
        title: entry.title,
        date: entry.created_at.strftime("%b %d, %Y"),
        url: journal_entry_path(entry) # or wherever you want to link
      }
    }
  end
end
