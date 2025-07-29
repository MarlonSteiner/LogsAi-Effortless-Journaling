class AddBannerImageToJournalEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :journal_entries, :ai_banner_image_url, :string
  end
end
