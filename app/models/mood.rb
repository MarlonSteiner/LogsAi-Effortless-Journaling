class Mood < ApplicationRecord
  # Associations
  has_many :entry_tags, dependent: :destroy
  has_many :journal_entries, through: :entry_tags
  has_many :users, through: :journal_entries

  # Validations
  # validates :category, presence: true, uniqueness: { case_sensitive: false }
  # validates :category, length: { minimum: 2, maximum: 100 }

  # Scopes
  scope :alphabetical, -> { order(:category) }
end
