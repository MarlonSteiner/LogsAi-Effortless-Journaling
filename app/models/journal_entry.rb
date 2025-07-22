class JournalEntry < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :entry_tags, dependent: :destroy
  has_many :moods, through: :entry_tags

  # Validations
  # validates :entry_date, presence: true
  # validates :input_type, inclusion: {
   # in: %w[text speech image],
   # message: "%{value} is not a valid input type"
  # }, allow_nil: true
  #validates :title, length: { maximum: 255 }

  # Scopes
  scope :by_date, ->(date) { where(entry_date: date) }
  scope :recent, -> { order(entry_date: :desc, created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :with_moods, -> { joins(:moods).distinct }
  scope :by_input_type, ->(type) { where(input_type: type) }

  # Instance methods
  def formatted_date
    entry_date.strftime("%B, %d, %Y")
  end

  def mood_count
    moods.count
  end
end
