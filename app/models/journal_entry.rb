class JournalEntry < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :entry_tags, dependent: :destroy
  has_many :moods, through: :entry_tags

  # Cloudinary file attachments
  has_one_attached :media_file

  # Validations
  # validates :entry_date, presence: true
  # validates :input_type, inclusion: {
  #   in: %w[text speech image video],
  #   message: "%{value} is not a valid input type"
  # }, allow_nil: true
  # validates :title, length: { maximum: 255 }

  # Custom validation for content based on input type
  validate :content_presence_based_on_input_type

  # Scopes
  scope :by_date, ->(date) { where(entry_date: date) }
  scope :recent, -> { order(entry_date: :desc, created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :with_moods, -> { joins(:moods).distinct }
  scope :by_input_type, ->(type) { where(input_type: type) }
  scope :by_emotion, ->(emotion) { where(ai_mood_label: emotion) }
  scope :with_emotions, -> { where.not(ai_mood_label: [nil, '']) }

  # Instance methods
  def formatted_date
    entry_date.strftime("%B %d, %Y")
  end

  def mood_count
    moods.count
  end

  # AI color theming based on emotion category (now using service colors)
  def mood_color
    return '#6c757d' unless ai_mood_label

    # Use the same color logic as the service
    case ai_mood_label.downcase
    when 'joyful', 'excited', 'energetic'
      '#28a745'
    when 'grateful', 'loved', 'content'
      '#20c997'
    when 'peaceful', 'calm'
      '#17a2b8'
    when 'optimistic', 'hopeful', 'confident'
      '#ffc107'
    when 'inspired', 'proud'
      '#6f42c1'
    when 'contemplative', 'focused', 'curious'
      '#6c757d'
    when 'nostalgic', 'determined'
      '#495057'
    when 'anxious', 'worried', 'stressed'
      '#fd7e14'
    when 'frustrated', 'angry'
      '#dc3545'
    when 'overwhelmed', 'confused', 'restless'
      '#e83e8c'
    when 'sad', 'lonely', 'disappointed'
      '#6610f2'
    when 'tired'
      '#868e96'
    else
      ai_color_theme || '#6c757d'
    end
  end

  # Get emotion category (positive, reflective, challenging)
  def emotion_category
    return nil unless ai_mood_label

    emotions_by_category = MoodAnalysisService.emotions_by_category
    emotions_by_category.each do |category, emotions|
      return category.downcase if emotions.include?(ai_mood_label.downcase)
    end
    'neutral'
  end

  # Check if entry has media file
  def has_media?
    media_file.attached?
  end

  # Get media file type
  def media_type
    return nil unless has_media?

    if media_file.content_type.start_with?('image/')
      'image'
    elsif media_file.content_type.start_with?('video/')
      'video'
    elsif media_file.content_type.start_with?('audio/')
      'audio'
    else
      'unknown'
    end
  end

  # Generate content for media-based entries for AI analysis
  def content_for_ai_analysis
    return content if content.present?

    case input_type
    when 'image'
      "Image entry uploaded on #{formatted_date}. Visual content captured."
    when 'video'
      "Video entry uploaded on #{formatted_date}. Video content captured."
    when 'speech'
      "Audio entry uploaded on #{formatted_date}. Speech content captured."
    else
      content || "Journal entry from #{formatted_date}."
    end
  end

  private

  def content_presence_based_on_input_type
    if input_type == 'text' && content.blank?
      errors.add(:content, "can't be blank for text entries")
    elsif %w[image video speech].include?(input_type) && !has_media? && content.blank?
      errors.add(:base, "Please provide either content or upload a file")
    end
  end
end
