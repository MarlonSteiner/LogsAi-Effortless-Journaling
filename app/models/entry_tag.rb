class EntryTag < ApplicationRecord
  # Associations
  belongs_to :journal_entry
  belongs_to :mood

  # # Validations
  # validates :journal_entry_id, uniqueness: {
  #   scope: :mood_id,
  #   message: "Mood already tagged for this entry"
  # }
end
