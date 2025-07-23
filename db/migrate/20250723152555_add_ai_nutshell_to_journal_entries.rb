class AddAiNutshellToJournalEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :journal_entries, :ai_nutshell, :text
  end
end
