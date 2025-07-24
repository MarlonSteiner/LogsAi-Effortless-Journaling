class AddAudioSupportToJournalEntries < ActiveRecord::Migration[7.1]
  def change
    # Add non-unique index for faster date-based lookups
    # Remove unique constraint since users might want multiple entries per day
    add_index :journal_entries, [:user_id, :entry_date], name: 'index_journal_entries_on_user_and_date'

    # Add index for input_type for better performance
    add_index :journal_entries, :input_type

    # Add index for entry_date for sorting
    add_index :journal_entries, :entry_date
  end
end
