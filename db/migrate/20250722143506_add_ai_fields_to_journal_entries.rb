class AddAiFieldsToJournalEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :journal_entries, :ai_mood_label, :string
    add_column :journal_entries, :ai_color_theme, :text
    add_column :journal_entries, :ai_background_style, :text
    add_column :journal_entries, :ai_summary, :text
  end
end
