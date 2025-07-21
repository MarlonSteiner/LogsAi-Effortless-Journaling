class User < ApplicationRecord
  # Included default devise modules
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  # Associations
  has_many :journal_entries, dependent: :destroy
  has_many :mood_summaries, dependent: :destroy
  has_many :entry_tags, through: :journal_entries
  has_many :moods, through: :entry_tags

  # Validations
  validates :name, presence: true, allow_blank: true
  validates :surname, presence: true, allow_blank: true
end
