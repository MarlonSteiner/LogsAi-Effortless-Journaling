class MoodSummary < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :user_id, presence: true
  validates :entry_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :average_mood_summary, length: { maximum: 1000 }, allow_blank: true
  validates :dominant_moods, length: { maximum: 500 }, allow_blank: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
end
